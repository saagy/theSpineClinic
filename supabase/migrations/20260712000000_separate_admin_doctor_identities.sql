-- Keep Clinic Admin operational permissions while enforcing doctor identity.
CREATE OR REPLACE FUNCTION public.enforce_doctor_reference_roles()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  column_name text;
  referenced_staff_id uuid;
BEGIN
  FOREACH column_name IN ARRAY TG_ARGV LOOP
    referenced_staff_id := (to_jsonb(NEW) ->> column_name)::uuid;
    IF referenced_staff_id IS NOT NULL AND NOT EXISTS (
      SELECT 1
      FROM public.staff
      WHERE id = referenced_staff_id
        AND role = 'doctor'::public.user_role
    ) THEN
      RAISE EXCEPTION '% must reference a doctor account.', column_name
        USING ERRCODE = '23514';
    END IF;
  END LOOP;
  RETURN NEW;
END;
$function$;
CREATE OR REPLACE FUNCTION public.prevent_referenced_doctor_role_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  IF OLD.role = 'doctor'::public.user_role
     AND NEW.role <> 'doctor'::public.user_role
     AND (
       EXISTS (SELECT 1 FROM public.patient_doctors WHERE doctor_id = OLD.id)
       OR EXISTS (
         SELECT 1 FROM public.appointment_doctors
         WHERE doctor_id = OLD.id OR replaced_doctor_id = OLD.id
       )
       OR EXISTS (
         SELECT 1 FROM public.doctor_replacements
         WHERE absent_doctor_id = OLD.id OR covering_doctor_id = OLD.id
       )
     ) THEN
    RAISE EXCEPTION 'Reassign this doctor before changing their role.'
      USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$function$;
DROP TRIGGER IF EXISTS tr_prevent_referenced_doctor_role_change ON public.staff;
CREATE TRIGGER tr_prevent_referenced_doctor_role_change
BEFORE UPDATE OF role ON public.staff
FOR EACH ROW EXECUTE FUNCTION public.prevent_referenced_doctor_role_change();
DROP TRIGGER IF EXISTS tr_enforce_patient_doctor_role ON public.patient_doctors;
CREATE TRIGGER tr_enforce_patient_doctor_role
BEFORE INSERT OR UPDATE OF doctor_id ON public.patient_doctors
FOR EACH ROW EXECUTE FUNCTION public.enforce_doctor_reference_roles('doctor_id');
DROP TRIGGER IF EXISTS tr_enforce_appointment_doctor_roles ON public.appointment_doctors;
CREATE TRIGGER tr_enforce_appointment_doctor_roles
BEFORE INSERT OR UPDATE OF doctor_id, replaced_doctor_id
ON public.appointment_doctors
FOR EACH ROW EXECUTE FUNCTION public.enforce_doctor_reference_roles(
  'doctor_id',
  'replaced_doctor_id'
);
DROP TRIGGER IF EXISTS tr_enforce_replacement_doctor_roles ON public.doctor_replacements;
CREATE TRIGGER tr_enforce_replacement_doctor_roles
BEFORE INSERT OR UPDATE OF absent_doctor_id, covering_doctor_id
ON public.doctor_replacements
FOR EACH ROW EXECUTE FUNCTION public.enforce_doctor_reference_roles(
  'absent_doctor_id',
  'covering_doctor_id'
);
CREATE OR REPLACE FUNCTION public.create_patient_with_doctors(
  p_name text,
  p_phone text,
  p_program text,
  p_clinic public.clinic_location,
  p_created_by uuid,
  p_doctor_ids uuid[]
)
RETURNS public.patients
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  new_patient public.patients;
  doc_id uuid;
  invalid_count integer;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.get_auth_staff_profile()
    WHERE staff_role IN ('super_admin'::user_role, 'receptionist'::user_role)
      AND staff_active = true
  ) THEN
    RAISE EXCEPTION 'Only active receptionists or super admins can register patients.'
      USING ERRCODE = '42501';
  END IF;
  IF p_doctor_ids IS NULL OR array_length(p_doctor_ids, 1) = 0 THEN
    RAISE EXCEPTION 'At least one assigned doctor is required.'
      USING ERRCODE = '22000';
  END IF;
  SELECT count(*) INTO invalid_count
  FROM unnest(p_doctor_ids) AS did
  LEFT JOIN public.staff s ON s.id = did
    AND s.is_active = true
    AND s.role = 'doctor'::public.user_role
  WHERE s.id IS NULL;
  IF invalid_count > 0 THEN
    RAISE EXCEPTION 'All assigned doctors must be active doctor accounts. Found % invalid doctor(s).',
      invalid_count USING ERRCODE = '22000';
  END IF;
  INSERT INTO public.patients (
    full_name, phone_number, program, clinic,
    session_balance, traction_balance, created_by, created_at
  ) VALUES (p_name, p_phone, p_program, p_clinic, 0, 0, p_created_by, NOW())
  RETURNING * INTO new_patient;
  FOREACH doc_id IN ARRAY p_doctor_ids LOOP
    INSERT INTO public.patient_doctors (patient_id, doctor_id)
    VALUES (new_patient.id, doc_id);
  END LOOP;
  RETURN new_patient;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_patient_doctors(
  p_patient_id uuid,
  p_doctor_ids uuid[]
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  doc_id uuid;
  invalid_count integer;
  active_count integer;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.get_auth_staff_profile()
    WHERE staff_role IN ('super_admin'::user_role, 'receptionist'::user_role)
      AND staff_active = true
  ) THEN
    RAISE EXCEPTION 'Only active receptionists or super admins can update patient doctor assignments.'
      USING ERRCODE = '42501';
  END IF;
  IF p_doctor_ids IS NULL OR array_length(p_doctor_ids, 1) = 0 THEN
    RAISE EXCEPTION 'At least one assigned doctor is required.'
      USING ERRCODE = '22000';
  END IF;
  SELECT count(*) INTO invalid_count
  FROM unnest(p_doctor_ids) AS did
  LEFT JOIN public.staff s ON s.id = did
    AND s.role = 'doctor'::public.user_role
  WHERE s.id IS NULL;
  IF invalid_count > 0 THEN
    RAISE EXCEPTION 'Found % ID(s) that do not belong to doctor accounts.',
      invalid_count USING ERRCODE = '22000';
  END IF;
  SELECT count(*) INTO active_count
  FROM unnest(p_doctor_ids) AS did
  JOIN public.staff s ON s.id = did
    AND s.is_active = true
    AND s.role = 'doctor'::public.user_role;
  IF active_count = 0 THEN
    RAISE EXCEPTION 'At least one active doctor is required.'
      USING ERRCODE = '22000';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.patient_doctors WHERE patient_id = p_patient_id
  ) AND (
    SELECT count(*) = array_length(p_doctor_ids, 1)
      AND array_agg(doctor_id ORDER BY doctor_id)
          = (SELECT array_agg(x ORDER BY x) FROM unnest(p_doctor_ids) AS x)
    FROM public.patient_doctors
    WHERE patient_id = p_patient_id
  ) THEN
    RETURN;
  END IF;
  DELETE FROM public.patient_doctors WHERE patient_id = p_patient_id;
  FOREACH doc_id IN ARRAY p_doctor_ids LOOP
    INSERT INTO public.patient_doctors (patient_id, doctor_id)
    VALUES (p_patient_id, doc_id);
  END LOOP;
END;
$function$;
