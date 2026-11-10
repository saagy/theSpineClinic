ALTER TABLE public.patients ADD COLUMN personal_details jsonb NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE public.patients ALTER COLUMN personal_details SET DEFAULT '{"nationality":"Egyptian"}'::jsonb;

CREATE FUNCTION public.normalize_patient_personal_details(p_details jsonb)
RETURNS jsonb LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE
  details record;
BEGIN
  SELECT * INTO details FROM jsonb_to_record(coalesce(p_details, '{}'::jsonb)) AS profile(
    address text, date_of_birth date, nationality text, gender text, secondary_phone text,
    insurance_company text, insurance_member_number text, insurance_expiry date, referral_source text
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
    'insurance_company', nullif(btrim(details.insurance_company), ''),
    'insurance_member_number', nullif(btrim(details.insurance_member_number), ''),
    'insurance_expiry', details.insurance_expiry,
    'referral_source', nullif(btrim(details.referral_source), '')
  ));
END;
$$;

CREATE FUNCTION public.create_patient_profile(p_name text, p_phone text, p_clinic public.clinic_location,
  p_created_by uuid, p_doctor_ids uuid[], p_personal_details jsonb)
RETURNS public.patients LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE patient public.patients;
BEGIN
  patient := public.create_patient_with_doctors(p_name, p_phone, p_clinic, p_created_by, p_doctor_ids);
  UPDATE public.patients SET personal_details = public.normalize_patient_personal_details(p_personal_details)
    WHERE id = patient.id RETURNING * INTO patient;
  RETURN patient;
END;
$$;

CREATE FUNCTION public.update_patient_profile(p_patient_id uuid, p_name text, p_phone text,
  p_clinic public.clinic_location, p_doctor_ids uuid[], p_personal_details jsonb)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  PERFORM public.update_patient_details(p_patient_id, p_name, p_phone, p_clinic, p_doctor_ids);
  UPDATE public.patients SET personal_details = public.normalize_patient_personal_details(p_personal_details)
    WHERE id = p_patient_id;
END;
$$;

CREATE FUNCTION public.billing_lookup_page(p_kind text, p_query text, p_offset integer, p_limit integer)
RETURNS TABLE(id uuid, name text, file_number bigint, branch public.clinic_location, is_senior boolean)
LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $$
  WITH query AS (
    SELECT lower(btrim(coalesce(p_query, ''))) AS term,
      regexp_replace(coalesce(p_query, ''), '[^0-9]', '', 'g') AS digits
  )
  SELECT p.id, p.full_name AS name, p.file_number, p.clinic, false
    FROM public.patients p CROSS JOIN query q
    WHERE public.billing_can('transact') AND p_kind = 'patient'
      AND (q.term = '' OR strpos(lower(p.full_name), q.term) > 0
        OR (q.term ~ '^[+0-9() .-]+$' AND q.digits <> '' AND (
          strpos(regexp_replace(p.phone_number, '[^0-9]', '', 'g'), q.digits) > 0
          OR strpos(regexp_replace(coalesce(p.personal_details->>'secondary_phone',''), '[^0-9]', '', 'g'), q.digits) > 0))
        OR p.file_number = CASE WHEN q.term ~ '^(id[[:space:]]+|#)?[0-9]{1,18}$' THEN q.digits::bigint END)
  UNION ALL
  SELECT s.id, s.full_name, NULL::bigint, NULL::public.clinic_location, s.is_senior
    FROM public.staff s CROSS JOIN query q
    WHERE public.billing_can('transact') AND s.role = 'doctor' AND s.is_active
      AND (p_kind = 'doctor' OR (p_kind = 'senior' AND s.is_senior))
      AND (q.term = '' OR strpos(lower(s.full_name), q.term) > 0)
  ORDER BY name, id OFFSET greatest(p_offset, 0) LIMIT least(greatest(p_limit, 1), 51);
$$;

-- Existing issued documents retain their snapshots. Draft and issue writes
-- must use an active senior doctor when the optional assignment is present.
CREATE FUNCTION public.validate_billing_senior() RETURNS trigger
LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
  IF NEW.consultant_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.staff WHERE id = NEW.consultant_id
      AND role = 'doctor' AND is_active AND is_senior
  ) THEN
    RAISE EXCEPTION 'inactive_senior' USING ERRCODE = 'P0001';
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER validate_billing_senior BEFORE INSERT OR UPDATE OF consultant_id, issued_at
  ON public.billing_invoices FOR EACH ROW EXECUTE FUNCTION public.validate_billing_senior();

REVOKE ALL ON FUNCTION public.normalize_patient_personal_details(jsonb),
  public.validate_billing_senior() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.create_patient_profile(text,text,public.clinic_location,uuid,uuid[],jsonb),
  public.update_patient_profile(uuid,text,text,public.clinic_location,uuid[],jsonb),
  public.billing_lookup_page(text,text,integer,integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_patient_profile(text,text,public.clinic_location,uuid,uuid[],jsonb),
  public.update_patient_profile(uuid,text,text,public.clinic_location,uuid[],jsonb),
  public.billing_lookup_page(text,text,integer,integer) TO authenticated;

