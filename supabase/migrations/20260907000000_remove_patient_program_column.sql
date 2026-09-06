-- Migration: 20260907000000_remove_patient_program_column.sql
-- Description: Drop legacy single-line text column 'program' from public.patients and update related RPCs.

ALTER TABLE public.patients DROP COLUMN IF EXISTS program;

-- Drop old overload of create_patient_with_doctors that accepted p_program
DROP FUNCTION IF EXISTS public.create_patient_with_doctors(text, text, text, public.clinic_location, uuid, uuid[]);

-- Recreate create_patient_with_doctors without p_program
CREATE OR REPLACE FUNCTION public.create_patient_with_doctors(
  p_name text,
  p_phone text,
  p_clinic public.clinic_location,
  p_created_by uuid,
  p_doctor_ids uuid[]
)
RETURNS public.patients
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  new_patient public.patients;
  doc_id uuid;
  invalid_count integer;
  v_staff_id uuid;
  v_staff_role public.user_role;
  v_staff_active boolean;
BEGIN
  SELECT staff_id, staff_role, staff_active
  INTO v_staff_id, v_staff_role, v_staff_active
  FROM public.get_auth_staff_profile();

  IF v_staff_active IS DISTINCT FROM true
     OR (v_staff_role NOT IN ('super_admin'::user_role, 'receptionist'::user_role)
         AND NOT EXISTS (
           SELECT 1 FROM public.staff s
           WHERE s.id = v_staff_id AND s.role = 'doctor'::public.user_role AND s.is_senior = true
         )) THEN
    RAISE EXCEPTION 'Only active receptionists, super admins, or senior doctors can register patients.'
      USING ERRCODE = '42501';
  END IF;

  IF p_doctor_ids IS NOT NULL AND array_length(p_doctor_ids, 1) > 0 THEN
    SELECT count(*) INTO invalid_count
    FROM unnest(p_doctor_ids) AS did
    LEFT JOIN public.staff s ON s.id = did
      AND s.is_active = true
      AND s.role = 'doctor'::public.user_role
    WHERE s.id IS NULL;
    IF invalid_count > 0 THEN
      RAISE EXCEPTION 'All assigned doctors must be active doctor accounts. Found % invalid doctor(s).',
        invalid_count
        USING ERRCODE = '22000';
    END IF;
  END IF;

  INSERT INTO public.patients (
    full_name, phone_number, clinic,
    session_balance, traction_balance, created_by, created_at
  )
  VALUES (p_name, p_phone, p_clinic, 0, 0, p_created_by, NOW())
  RETURNING * INTO new_patient;

  IF p_doctor_ids IS NOT NULL AND array_length(p_doctor_ids, 1) > 0 THEN
    FOREACH doc_id IN ARRAY p_doctor_ids LOOP
      INSERT INTO public.patient_doctors (patient_id, doctor_id)
      VALUES (new_patient.id, doc_id);
    END LOOP;
  END IF;

  RETURN new_patient;
END;
$function$;

REVOKE ALL ON FUNCTION public.create_patient_with_doctors(text, text, public.clinic_location, uuid, uuid[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_patient_with_doctors(text, text, public.clinic_location, uuid, uuid[]) TO authenticated;

-- Drop old overload of update_patient_details that accepted p_program
DROP FUNCTION IF EXISTS public.update_patient_details(uuid, text, text, text, public.clinic_location, uuid[]);

-- Recreate update_patient_details without p_program
CREATE OR REPLACE FUNCTION public.update_patient_details(
  p_patient_id uuid,
  p_name text,
  p_phone text,
  p_clinic public.clinic_location,
  p_doctor_ids uuid[] DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NOT public.can_current_staff_access_patient(p_patient_id) THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE='42501';
  END IF;
  -- Demographic edits never write stale balances, authorship, or recall dates.
  UPDATE public.patients
  SET full_name = p_name,
      phone_number = p_phone,
      clinic = p_clinic
  WHERE id = p_patient_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Patient not found' USING ERRCODE='P0002';
  END IF;

  IF p_doctor_ids IS NOT NULL THEN
    PERFORM public.update_patient_doctors(p_patient_id, p_doctor_ids);
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.update_patient_details(uuid, text, text, public.clinic_location, uuid[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.update_patient_details(uuid, text, text, public.clinic_location, uuid[]) TO authenticated;
