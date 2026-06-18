-- Migration: Enforce Patient-Doctor Assignment Integrity
-- Ensures no patient can exist without at least one assigned active doctor.
-- Guards against: network interruptions during multi-step creates, client-side
-- list-reference bugs, and cascade deletes from doctor rejection flows.

-- ============================================================================
-- 1. Trigger function: blocks any operation that would leave a patient with 0 doctors
--    Improved: includes the patient_id in the error so admins know whom to reassign.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.check_patient_has_doctors()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  doctor_count integer;
BEGIN
  -- Only enforce when the patient record still exists (allows cascade deletes
  -- when the patient itself is being removed).
  IF EXISTS (SELECT 1 FROM public.patients WHERE id = OLD.patient_id) THEN
    SELECT count(*) INTO doctor_count
    FROM public.patient_doctors
    WHERE patient_id = OLD.patient_id;

    IF doctor_count = 0 THEN
      RAISE EXCEPTION 'Patient % would have no assigned doctors. Reassign them to another doctor first.',
        OLD.patient_id
        USING ERRCODE = '22000';
    END IF;
  END IF;

  RETURN NULL;
END;
$$;

-- Re-create the constraint trigger (idempotent — dropped first to update definition).
DROP TRIGGER IF EXISTS tr_check_patient_has_doctors ON public.patient_doctors;
CREATE CONSTRAINT TRIGGER tr_check_patient_has_doctors
  AFTER DELETE OR UPDATE ON public.patient_doctors
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  EXECUTE FUNCTION check_patient_has_doctors();

-- ============================================================================
-- 2. Atomic patient creation RPC
--    Improved: validates that every doctor ID belongs to an active staff member.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.create_patient_with_doctors(
  p_name text,
  p_phone text,
  p_program text,
  p_clinic clinic_location,
  p_created_by uuid,
  p_doctor_ids uuid[]
) RETURNS public.patients
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_patient public.patients;
  doc_id uuid;
  invalid_count integer;
BEGIN
  -- Validate caller permission (must be active receptionist or super admin)
  IF NOT EXISTS (
    SELECT 1
    FROM public.get_auth_staff_profile()
    WHERE staff_role IN ('super_admin'::user_role, 'receptionist'::user_role)
      AND staff_active = true
  ) THEN
    RAISE EXCEPTION 'Only active receptionists or super admins can register patients.'
      USING ERRCODE = '42501';
  END IF;

  -- Validate doctors list is non-empty
  IF p_doctor_ids IS NULL OR array_length(p_doctor_ids, 1) = 0 THEN
    RAISE EXCEPTION 'At least one assigned doctor is required.'
      USING ERRCODE = '22000';
  END IF;

  -- Validate every doctor ID belongs to an active staff member
  SELECT count(*) INTO invalid_count
  FROM unnest(p_doctor_ids) AS did
  LEFT JOIN public.staff s ON s.id = did AND s.is_active = true
  WHERE s.id IS NULL;

  IF invalid_count > 0 THEN
    RAISE EXCEPTION 'All assigned doctors must be active staff members. Found % invalid or inactive doctor(s).',
      invalid_count
      USING ERRCODE = '22000';
  END IF;

  -- Insert patient record
  INSERT INTO public.patients (
    full_name,
    phone_number,
    program,
    clinic,
    package_balance,
    created_by,
    created_at
  )
  VALUES (
    p_name,
    p_phone,
    p_program,
    p_clinic,
    0,
    p_created_by,
    NOW()
  )
  RETURNING * INTO new_patient;

  -- Insert doctor assignments
  FOREACH doc_id IN ARRAY p_doctor_ids LOOP
    INSERT INTO public.patient_doctors (patient_id, doctor_id)
    VALUES (new_patient.id, doc_id);
  END LOOP;

  RETURN new_patient;
END;
$$;

-- ============================================================================
-- 3. Atomic doctor assignment update RPC
--    Improved: validates that every doctor ID belongs to an active staff member.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_patient_doctors(
  p_patient_id uuid,
  p_doctor_ids uuid[]
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  doc_id uuid;
  invalid_count integer;
BEGIN
  -- Validate caller permission (must be active receptionist or super admin)
  IF NOT EXISTS (
    SELECT 1
    FROM public.get_auth_staff_profile()
    WHERE staff_role IN ('super_admin'::user_role, 'receptionist'::user_role)
      AND staff_active = true
  ) THEN
    RAISE EXCEPTION 'Only active receptionists or super admins can update patient doctor assignments.'
      USING ERRCODE = '42501';
  END IF;

  -- Validate doctors list is non-empty
  IF p_doctor_ids IS NULL OR array_length(p_doctor_ids, 1) = 0 THEN
    RAISE EXCEPTION 'At least one assigned doctor is required.'
      USING ERRCODE = '22000';
  END IF;

  -- Validate every doctor ID belongs to an active staff member
  SELECT count(*) INTO invalid_count
  FROM unnest(p_doctor_ids) AS did
  LEFT JOIN public.staff s ON s.id = did AND s.is_active = true
  WHERE s.id IS NULL;

  IF invalid_count > 0 THEN
    RAISE EXCEPTION 'All assigned doctors must be active staff members. Found % invalid or inactive doctor(s).',
      invalid_count
      USING ERRCODE = '22000';
  END IF;

  -- If the new list is identical to the existing assignments, skip work.
  IF EXISTS (
    SELECT 1
    FROM public.patient_doctors
    WHERE patient_id = p_patient_id
  ) AND (
    SELECT count(*) = array_length(p_doctor_ids, 1)
      AND array_agg(doctor_id ORDER BY doctor_id)
          = (SELECT array_agg(x ORDER BY x) FROM unnest(p_doctor_ids) AS x)
    FROM public.patient_doctors
    WHERE patient_id = p_patient_id
  ) THEN
    RETURN; -- No change needed — avoid unnecessary delete+insert cycle
  END IF;

  -- Delete existing doctor assignments for the patient
  DELETE FROM public.patient_doctors WHERE patient_id = p_patient_id;

  -- Insert new doctor assignments
  FOREACH doc_id IN ARRAY p_doctor_ids LOOP
    INSERT INTO public.patient_doctors (patient_id, doctor_id)
    VALUES (p_patient_id, doc_id);
  END LOOP;
END;
$$;
