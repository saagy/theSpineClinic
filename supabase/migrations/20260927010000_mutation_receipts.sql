-- Durable receipts are deliberately retained: deleting them re-enables old retries.
CREATE TABLE public.mutation_receipts (
  request_id uuid PRIMARY KEY,
  actor_id uuid NOT NULL,
  kind text NOT NULL,
  payload_hash text NOT NULL,
  outcome jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.mutation_receipts ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.mutation_receipts TO authenticated;
-- No client policies: only the checked SECURITY DEFINER functions below write.

CREATE FUNCTION public.execute_clinic_mutation(p_request_id uuid, p_kind text, p_payload jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE previous public.mutation_receipts; outcome jsonb; payment_id uuid;
  actor uuid := (SELECT staff_id FROM public.get_auth_staff_profile());
  error_code text; error_message text; current_amount numeric;
  request_hash text := encode(sha256(convert_to(p_payload::text,'UTF8')),'hex');
BEGIN
  IF actor IS NULL OR NOT EXISTS(SELECT 1 FROM public.staff WHERE id=actor AND is_active) THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE='42501';
  END IF;
  IF p_request_id IS NULL OR p_payload IS NULL OR (p_kind IS NULL OR p_kind NOT IN ('payment','collect_due','booking')) THEN
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
    IF p_kind IN ('payment','collect_due') AND NOT public.current_staff_can_manage_payments() THEN
      RAISE EXCEPTION 'Permission denied' USING ERRCODE='42501';
    END IF;
    IF p_kind='payment' THEN
      INSERT INTO public.payment_records(patient_id,amount,reason,recorded_by,
        session_balance_added,traction_balance_added,total_price)
      VALUES ((p_payload->>'patient_id')::uuid,(p_payload->>'amount')::numeric,
        p_payload->>'reason',actor,(p_payload->>'session_balance_added')::integer,
        (p_payload->>'traction_balance_added')::integer,(p_payload->>'total_price')::numeric)
      RETURNING id INTO payment_id;
      outcome := jsonb_build_object('ok',true,'id',payment_id);
    ELSIF p_kind='collect_due' THEN
      SELECT amount INTO current_amount FROM public.payment_records
        WHERE id=(p_payload->>'p_payment_id')::uuid FOR UPDATE;
      IF current_amount IS DISTINCT FROM (p_payload->>'p_expected_amount')::numeric THEN
        RAISE EXCEPTION 'Payment changed. Refresh before collecting.' USING ERRCODE='P0001';
      END IF;
      PERFORM public.collect_payment_due((p_payload->>'p_payment_id')::uuid,
        (p_payload->>'p_additional_amount')::numeric);
      outcome := jsonb_build_object('ok',true);
    ELSE
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
    END IF;
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS error_code=RETURNED_SQLSTATE, error_message=MESSAGE_TEXT;
    outcome := jsonb_build_object('ok',false,'code',error_code,'message',error_message);
  END;
  INSERT INTO public.mutation_receipts(request_id,actor_id,kind,payload_hash,outcome)
    VALUES(p_request_id,actor,p_kind,request_hash,outcome);
  RETURN outcome;
END;
$$;

-- Fence an unresolved request before allowing edited details to be submitted.
-- The same lock waits for an in-flight write; a missing write is tombstoned.
CREATE FUNCTION public.resolve_clinic_mutation(p_request_id uuid) RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE previous public.mutation_receipts;
  actor uuid := (SELECT staff_id FROM public.get_auth_staff_profile());
BEGIN
  IF actor IS NULL OR NOT EXISTS(SELECT 1 FROM public.staff WHERE id=actor AND is_active) THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE='42501';
  END IF;
  IF p_request_id IS NULL THEN RAISE EXCEPTION 'Invalid request' USING ERRCODE='22000'; END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended(p_request_id::text,0));
  SELECT * INTO previous FROM public.mutation_receipts WHERE request_id=p_request_id;
  IF FOUND THEN
    IF previous.actor_id<>actor THEN RAISE EXCEPTION 'Permission denied' USING ERRCODE='42501'; END IF;
    RETURN coalesce((previous.outcome->>'ok')::boolean,false);
  END IF;
  INSERT INTO public.mutation_receipts(request_id,actor_id,kind,payload_hash,outcome)
    VALUES(p_request_id,actor,'cancelled','{}','{"ok":false}');
  RETURN false;
END;
$$;
REVOKE ALL ON FUNCTION public.execute_clinic_mutation(uuid,text,jsonb),
  public.resolve_clinic_mutation(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.execute_clinic_mutation(uuid,text,jsonb),
  public.resolve_clinic_mutation(uuid) TO authenticated;
