-- Billing plan slice 5: the invoice workflow (invoices v2) is now the only
-- billing system. This removes the self-pay pilot, the legacy payment_records
-- ledger with its package triggers, and patient insurance details.
-- DESTRUCTIVE: pilot invoices and legacy payment rows are deleted with their
-- tables. Patient session balances are not changed.

-- ---- Self-pay pilot ----
DROP FUNCTION public.billing_export(text, public.clinic_location, text, date, date, boolean);
DROP FUNCTION public.billing_list(text, public.clinic_location, text, date, date, integer, integer, boolean);
DROP FUNCTION public.billing_invoice_detail(uuid);
DROP FUNCTION public.billing_lookup(text, text);
DROP FUNCTION public.billing_lookup_page(text, text, integer, integer);
DROP FUNCTION public.execute_billing_mutation(uuid, text, jsonb);
DROP FUNCTION public.resolve_billing_mutation(uuid, text);
DROP FUNCTION public.billing_record_movement(public.billing_invoices, text, jsonb, uuid);
DROP FUNCTION public.billing_issue(public.billing_invoices, uuid);
DROP FUNCTION public.billing_save_draft(jsonb, uuid);
DROP FUNCTION public.billing_save_item(jsonb);
DROP FUNCTION public.billing_next_number(public.clinic_location, text);
DROP VIEW public.billing_register;
DROP TABLE public.billing_allocations, public.billing_movements, public.billing_invoice_lines,
  public.billing_invoices, public.billing_items, public.billing_number_series;
DROP FUNCTION public.validate_billing_senior();
DROP FUNCTION public.billing_can(text);

-- ---- Legacy payments ----
-- The durable clinic command keeps only bookings. Payments are recorded as
-- invoice receipts through execute_invoice_command.
CREATE OR REPLACE FUNCTION public.execute_clinic_mutation(p_request_id uuid, p_kind text, p_payload jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE previous public.mutation_receipts; outcome jsonb;
  actor uuid := (SELECT staff_id FROM public.get_auth_staff_profile());
  error_code text; error_message text;
  request_hash text := encode(sha256(convert_to(p_payload::text,'UTF8')),'hex');
BEGIN
  IF actor IS NULL OR NOT EXISTS(SELECT 1 FROM public.staff WHERE id=actor AND is_active) THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE='42501';
  END IF;
  IF p_request_id IS NULL OR p_payload IS NULL OR p_kind IS DISTINCT FROM 'booking' THEN
    RAISE EXCEPTION 'Invalid request' USING ERRCODE='22000';
  END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended(p_request_id::text,0));
  SELECT * INTO previous FROM public.mutation_receipts WHERE request_id=p_request_id;
  IF FOUND THEN
    IF previous.actor_id<>actor OR previous.kind<>p_kind OR previous.payload_hash<>request_hash THEN
      RAISE EXCEPTION 'Request identity mismatch' USING ERRCODE='22000';
    END IF;
    RETURN previous.outcome;
  END IF;
  -- Roll back every business write on failure, then retain its definitive result.
  BEGIN
    PERFORM public.book_recurring_appointments(
      (p_payload->>'p_patient_id')::uuid,(p_payload->>'p_type')::public.appointment_type,
      ARRAY(SELECT value::timestamptz FROM jsonb_array_elements_text(p_payload->'p_slots')),
      (p_payload->>'p_use_package')::boolean,actor,
      ARRAY(SELECT value::uuid FROM jsonb_array_elements_text(p_payload->'p_doctor_ids')),
      (p_payload->>'p_expected_next_visit_date')::date);
    IF p_payload->'companion' IS NOT NULL THEN
      PERFORM public.book_recurring_appointments(
        (p_payload->>'p_patient_id')::uuid,(p_payload->'companion'->>'type')::public.appointment_type,
        ARRAY(SELECT value::timestamptz FROM jsonb_array_elements_text(p_payload->'companion'->'slots')),
        false,actor,
        ARRAY(SELECT value::uuid FROM jsonb_array_elements_text(p_payload->'companion'->'doctor_ids')),NULL);
    END IF;
    outcome := jsonb_build_object('ok',true);
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS error_code=RETURNED_SQLSTATE, error_message=MESSAGE_TEXT;
    outcome := jsonb_build_object('ok',false,'code',error_code,'message',error_message);
  END;
  INSERT INTO public.mutation_receipts(request_id,actor_id,kind,payload_hash,outcome)
    VALUES(p_request_id,actor,p_kind,request_hash,outcome);
  RETURN outcome;
END;
$$;

DROP FUNCTION public.collect_payment_due(uuid, numeric);
DROP TABLE public.payment_records;
DROP FUNCTION public.handle_payment_package_sync();

-- ---- Patient deletion guard ----
CREATE OR REPLACE FUNCTION public.patient_has_records(p_patient_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.patients WHERE id = p_patient_id
    AND (session_balance <> 0 OR traction_balance <> 0))
    OR EXISTS (SELECT 1 FROM public.appointments WHERE patient_id = p_patient_id)
    OR EXISTS (SELECT 1 FROM public.patient_programs WHERE patient_id = p_patient_id)
    OR EXISTS (SELECT 1 FROM public.patient_medical_history WHERE patient_id = p_patient_id)
    OR EXISTS (SELECT 1 FROM public.patient_notes WHERE patient_id = p_patient_id)
    OR EXISTS (SELECT 1 FROM public.patient_documents WHERE patient_id = p_patient_id)
    OR EXISTS (SELECT 1 FROM public.invoices WHERE patient_id = p_patient_id);
$$;

-- The app's empty-patient preflight keeps calling this name.
CREATE OR REPLACE FUNCTION public.billing_patient_has_invoices(p_patient_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT public.can_current_staff_access_patient(p_patient_id)
    AND EXISTS (SELECT 1 FROM public.invoices WHERE patient_id = p_patient_id);
$$;

-- ---- Patient insurance details ----
CREATE OR REPLACE FUNCTION public.normalize_patient_personal_details(p_details jsonb)
RETURNS jsonb LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE
  details record;
BEGIN
  SELECT * INTO details FROM jsonb_to_record(coalesce(p_details, '{}'::jsonb)) AS profile(
    address text, date_of_birth date, nationality text, gender text, secondary_phone text,
    referral_source text
  );
  IF details.date_of_birth > current_date
    OR (details.gender IS NOT NULL AND details.gender NOT IN ('female', 'male')) THEN
    RAISE EXCEPTION 'Invalid patient details' USING ERRCODE = '22023';
  END IF;
  RETURN jsonb_strip_nulls(jsonb_build_object(
    'address', nullif(btrim(details.address), ''),
    'date_of_birth', details.date_of_birth,
    'nationality', nullif(btrim(details.nationality), ''),
    'gender', details.gender,
    'secondary_phone', nullif(btrim(details.secondary_phone), ''),
    'referral_source', nullif(btrim(details.referral_source), '')
  ));
END;
$$;

UPDATE public.patients
SET personal_details = personal_details - 'insurance_company' - 'insurance_member_number' - 'insurance_expiry'
WHERE personal_details ?| ARRAY['insurance_company', 'insurance_member_number', 'insurance_expiry'];
