-- ============================================================================
-- Migration: 20260831000000_senior_doctor_admin_privileges_and_unassigned_patients.sql
-- Description:
--   1. Allow patients to be registered and edited without assigned doctors.
--   2. Grant senior doctors administrative CRUD privileges for patients and appointments.
--   3. Keep appointments strictly requiring an assigned doctor.
-- ============================================================================

-- 1. Drop trigger enforcing at least one doctor on patient_doctors
DROP TRIGGER IF EXISTS tr_check_patient_has_doctors ON public.patient_doctors;

CREATE OR REPLACE FUNCTION public.check_patient_has_doctors()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
  RETURN NULL;
END;
$function$;

-- 2. Update create_patient_with_doctors to allow 0 doctors and allow senior doctors
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
    full_name, phone_number, program, clinic,
    session_balance, traction_balance, created_by, created_at
  )
  VALUES (p_name, p_phone, p_program, p_clinic, 0, 0, p_created_by, NOW())
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

-- 3. Update update_patient_doctors to allow 0 doctors and allow senior doctors
CREATE OR REPLACE FUNCTION public.update_patient_doctors(
  p_patient_id uuid,
  p_doctor_ids uuid[]
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  doc_id uuid;
  invalid_count integer;
  active_count integer;
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
    RAISE EXCEPTION 'Only active receptionists, super admins, or senior doctors can update patient doctor assignments.'
      USING ERRCODE = '42501';
  END IF;

  IF p_doctor_ids IS NULL OR array_length(p_doctor_ids, 1) = 0 THEN
    DELETE FROM public.patient_doctors WHERE patient_id = p_patient_id;
    RETURN;
  END IF;

  SELECT count(*) INTO invalid_count
  FROM unnest(p_doctor_ids) AS did
  LEFT JOIN public.staff s ON s.id = did
    AND s.role = 'doctor'::public.user_role
  WHERE s.id IS NULL;

  IF invalid_count > 0 THEN
    RAISE EXCEPTION 'Found % ID(s) that do not belong to doctor accounts.', invalid_count
      USING ERRCODE = '22000';
  END IF;

  SELECT count(*) INTO active_count
  FROM unnest(p_doctor_ids) AS did
  JOIN public.staff s ON s.id = did
    AND s.is_active = true
    AND s.role = 'doctor'::public.user_role;

  IF active_count = 0 THEN
    RAISE EXCEPTION 'At least one active doctor is required when assigning doctors.'
      USING ERRCODE = '22000';
  END IF;

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
    RETURN;
  END IF;

  DELETE FROM public.patient_doctors WHERE patient_id = p_patient_id;

  FOREACH doc_id IN ARRAY p_doctor_ids LOOP
    INSERT INTO public.patient_doctors (patient_id, doctor_id)
    VALUES (p_patient_id, doc_id);
  END LOOP;
END;
$function$;

-- 4. Update book_recurring_appointments to allow senior doctors
CREATE OR REPLACE FUNCTION public.book_recurring_appointments(
  p_patient_id uuid,
  p_type public.appointment_type,
  p_slots timestamptz[],
  p_use_package boolean,
  p_creator_id uuid,
  p_doctor_ids uuid[],
  p_expected_next_visit_date date DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_slot timestamptz;
  v_appt_id uuid;
  v_doc_id uuid;
  v_staff_id uuid;
  v_staff_role public.user_role;
  v_staff_active boolean;
  v_next_visit date;
  v_current_balance integer;
  v_future_commitments integer;
  v_available_balance integer;
  v_required_sessions integer;
BEGIN
  SELECT staff_id, staff_role, staff_active
  INTO v_staff_id, v_staff_role, v_staff_active
  FROM public.get_auth_staff_profile();

  IF v_staff_active IS DISTINCT FROM true
     OR (v_staff_role NOT IN ('receptionist', 'super_admin')
         AND NOT EXISTS (
           SELECT 1 FROM public.staff s
           WHERE s.id = v_staff_id AND s.role = 'doctor'::public.user_role AND s.is_senior = true
         ))
     OR v_staff_id IS DISTINCT FROM p_creator_id THEN
    RAISE EXCEPTION 'Permission denied.' USING ERRCODE = '42501';
  END IF;

  IF coalesce(array_length(p_slots, 1), 0) = 0
     OR coalesce(array_length(p_doctor_ids, 1), 0) = 0 THEN
    RAISE EXCEPTION 'At least one slot and doctor are required.';
  END IF;

  IF p_use_package AND p_type IN ('normal_pt_session'::public.appointment_type, 'spinal_traction_session'::public.appointment_type) THEN
    v_required_sessions := coalesce(array_length(p_slots, 1), 0);

    IF p_type = 'normal_pt_session'::public.appointment_type THEN
      SELECT coalesce(session_balance, 0) INTO v_current_balance
      FROM public.patients
      WHERE id = p_patient_id
      FOR UPDATE;
    ELSIF p_type = 'spinal_traction_session'::public.appointment_type THEN
      SELECT coalesce(traction_balance, 0) INTO v_current_balance
      FROM public.patients
      WHERE id = p_patient_id
      FOR UPDATE;
    END IF;

    SELECT coalesce(count(*), 0)::integer INTO v_future_commitments
    FROM public.appointments
    WHERE patient_id = p_patient_id
      AND type = p_type
      AND status = 'scheduled'::public.appointment_status
      AND scheduled_at > now();

    v_available_balance := v_current_balance - v_future_commitments;

    IF v_required_sessions > v_available_balance THEN
      RAISE EXCEPTION 'Insufficient package balance for patient %. Required %, available %.',
        p_patient_id, v_required_sessions, v_available_balance
        USING ERRCODE = '22000';
    END IF;
  END IF;

  FOREACH v_slot IN ARRAY p_slots LOOP
    INSERT INTO public.appointments (
      patient_id, type, scheduled_at, status, created_by
    ) VALUES (
      p_patient_id, p_type, v_slot, 'scheduled'::public.appointment_status, p_creator_id
    ) RETURNING id INTO v_appt_id;

    FOREACH v_doc_id IN ARRAY p_doctor_ids LOOP
      INSERT INTO public.appointment_doctors (
        appointment_id, doctor_id, is_active, added_by
      ) VALUES (
        v_appt_id, v_doc_id, true, p_creator_id
      );
    END LOOP;
  END LOOP;

  IF p_expected_next_visit_date IS NOT NULL THEN
    v_next_visit := p_expected_next_visit_date;
  ELSE
    SELECT (scheduled_at AT TIME ZONE public.clinic_timezone())::date INTO v_next_visit
    FROM public.appointments
    WHERE patient_id = p_patient_id
      AND status = 'scheduled'::public.appointment_status
      AND scheduled_at >= now()
    ORDER BY scheduled_at ASC
    LIMIT 1;
  END IF;

  UPDATE public.patients
  SET next_visit_date = v_next_visit
  WHERE id = p_patient_id;
END;
$function$;

-- 5. Update update_appointment_doctors to allow senior doctors
CREATE OR REPLACE FUNCTION public.update_appointment_doctors(
  p_appointment_id uuid,
  p_doctor_ids uuid[],
  p_editor_id uuid DEFAULT NULL::uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_staff_id   uuid;
  v_staff_role public.user_role;
  v_active     boolean;
  invalid_count integer;
  v_now        timestamptz := now();
BEGIN
  SELECT staff_id, staff_role, staff_active
    INTO v_staff_id, v_staff_role, v_active
    FROM public.get_auth_staff_profile();

  IF NOT coalesce(v_active, false)
     OR (v_staff_role NOT IN ('super_admin', 'receptionist')
         AND NOT EXISTS (
           SELECT 1 FROM public.staff s
           WHERE s.id = v_staff_id AND s.role = 'doctor'::public.user_role AND s.is_senior = true
         )) THEN
    RAISE EXCEPTION 'Permission denied: must be active super_admin, receptionist, or senior doctor'
      USING ERRCODE = '42501';
  END IF;

  IF coalesce(array_length(p_doctor_ids, 1), 0) = 0 THEN
    RAISE EXCEPTION 'At least one doctor must be assigned'
      USING ERRCODE = '22000';
  END IF;

  SELECT count(*) INTO invalid_count
  FROM unnest(p_doctor_ids) AS did
  LEFT JOIN public.staff s ON s.id = did
    AND s.role = 'doctor'::public.user_role
    AND s.is_active = true
  WHERE s.id IS NULL;

  IF invalid_count > 0 THEN
    RAISE EXCEPTION 'Found % ID(s) that do not belong to active doctor accounts.', invalid_count
      USING ERRCODE = '22000';
  END IF;

  UPDATE public.appointment_doctors
     SET is_active = false
   WHERE appointment_id = p_appointment_id
     AND is_active = true
     AND doctor_id != ALL(p_doctor_ids);

  UPDATE public.appointment_doctors
     SET is_active = true,
         added_by  = coalesce(p_editor_id, v_staff_id),
         added_at  = v_now
   WHERE appointment_id = p_appointment_id
     AND is_active = false
     AND doctor_id = ANY(p_doctor_ids);

  INSERT INTO public.appointment_doctors (appointment_id, doctor_id, is_active, added_by, added_at)
  SELECT p_appointment_id, unnest, true, coalesce(p_editor_id, v_staff_id), v_now
    FROM unnest(p_doctor_ids)
   WHERE unnest NOT IN (
     SELECT doctor_id FROM public.appointment_doctors
      WHERE appointment_id = p_appointment_id
   );
END;
$function$;

-- 6. Update bulk_replace_appointment_doctor to allow senior doctors
CREATE OR REPLACE FUNCTION public.bulk_replace_appointment_doctor(
  p_absent_doctor_id uuid,
  p_replacement_doctor_ids uuid[],
  p_appointment_ids uuid[],
  p_day date
)
RETURNS TABLE(replaced_count integer, remaining_count integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_editor_id uuid;
  v_role public.user_role;
  v_active boolean;
  v_appointment_id uuid;
  v_doctor_id uuid;
  v_expected integer;
BEGIN
  SELECT staff_id, staff_role, staff_active
  INTO v_editor_id, v_role, v_active
  FROM public.get_auth_staff_profile();

  IF v_active IS DISTINCT FROM true
     OR (v_role NOT IN ('receptionist', 'super_admin')
         AND NOT EXISTS (
           SELECT 1 FROM public.staff s
           WHERE s.id = v_editor_id AND s.role = 'doctor'::public.user_role AND s.is_senior = true
         )) THEN
    RAISE EXCEPTION 'Permission denied.' USING ERRCODE = '42501';
  END IF;

  IF coalesce(array_length(p_appointment_ids, 1), 0) = 0
     OR coalesce(array_length(p_replacement_doctor_ids, 1), 0) = 0
     OR p_absent_doctor_id = ANY(p_replacement_doctor_ids) THEN
    RAISE EXCEPTION 'Invalid replacement selection.';
  END IF;

  SELECT count(DISTINCT id)::integer INTO v_expected
  FROM public.staff
  WHERE id = ANY(p_replacement_doctor_ids)
    AND role = 'doctor' AND is_active = true;
  IF v_expected <> cardinality(p_replacement_doctor_ids) THEN
    RAISE EXCEPTION 'Every replacement must be an active doctor.';
  END IF;

  PERFORM 1
  FROM public.appointments a
  JOIN public.appointment_doctors ad ON ad.appointment_id = a.id
  WHERE a.id = ANY(p_appointment_ids)
    AND a.status <> 'cancelled'
    AND (a.scheduled_at AT TIME ZONE public.clinic_timezone())::date = p_day
    AND ad.doctor_id = p_absent_doctor_id
    AND ad.is_active = true
  FOR UPDATE OF ad;

  SELECT count(DISTINCT a.id)::integer INTO v_expected
  FROM public.appointments a
  JOIN public.appointment_doctors ad ON ad.appointment_id = a.id
  WHERE a.id = ANY(p_appointment_ids)
    AND a.status <> 'cancelled'
    AND (a.scheduled_at AT TIME ZONE public.clinic_timezone())::date = p_day
    AND ad.doctor_id = p_absent_doctor_id AND ad.is_active = true;
  IF v_expected <> cardinality(p_appointment_ids) THEN
    RAISE EXCEPTION 'One or more appointments are no longer replaceable.';
  END IF;

  FOREACH v_appointment_id IN ARRAY p_appointment_ids LOOP
    UPDATE public.appointment_doctors SET is_active = false
    WHERE appointment_id = v_appointment_id
      AND doctor_id = p_absent_doctor_id AND is_active = true;

    FOREACH v_doctor_id IN ARRAY p_replacement_doctor_ids LOOP
      IF EXISTS (
        SELECT 1 FROM public.appointment_doctors
        WHERE appointment_id = v_appointment_id
          AND doctor_id = v_doctor_id AND is_active = true
      ) THEN
        CONTINUE;
      END IF;

      UPDATE public.appointment_doctors
      SET is_active = true, added_by = v_editor_id, added_at = now()
      WHERE id = (
        SELECT id FROM public.appointment_doctors
        WHERE appointment_id = v_appointment_id
          AND doctor_id = v_doctor_id AND is_active = false
        ORDER BY added_at DESC LIMIT 1
      );
      IF NOT FOUND THEN
        INSERT INTO public.appointment_doctors (
          appointment_id, doctor_id, is_active, added_by
        ) VALUES (v_appointment_id, v_doctor_id, true, v_editor_id);
      END IF;
    END LOOP;
  END LOOP;

  RETURN QUERY
  SELECT cardinality(p_appointment_ids)::integer, count(DISTINCT a.id)::integer
  FROM public.appointments a
  JOIN public.appointment_doctors ad ON ad.appointment_id = a.id
  WHERE a.status <> 'cancelled'
    AND (a.scheduled_at AT TIME ZONE public.clinic_timezone())::date = p_day
    AND ad.doctor_id = p_absent_doctor_id AND ad.is_active = true;
END;
$function$;

-- 7. Update RLS policies for patients, patient_doctors, and patient_medical_history
DROP POLICY IF EXISTS "Super Admins and Receptionists have full access to patients" ON public.patients;
DROP POLICY IF EXISTS "Super Admins and Receptionists can delete patients" ON public.patients;
DROP POLICY IF EXISTS "Staff with management access have full access to patients" ON public.patients;
DROP POLICY IF EXISTS "Staff with management access can delete patients" ON public.patients;

CREATE POLICY "Staff with management access have full access to patients" ON public.patients
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.staff s
      WHERE s.user_id = auth.uid()
        AND s.is_active = true
        AND (
          s.role IN ('super_admin'::public.user_role, 'receptionist'::public.user_role)
          OR (s.role = 'doctor'::public.user_role AND s.is_senior = true)
        )
    )
  );

DROP POLICY IF EXISTS "Only receptionists and admins can alter long-term patient doctor assignments" ON public.patient_doctors;
DROP POLICY IF EXISTS "Staff with management access can alter long-term patient doctor assignments" ON public.patient_doctors;

CREATE POLICY "Staff with management access can alter long-term patient doctor assignments" ON public.patient_doctors
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.staff s
      WHERE s.user_id = auth.uid()
        AND s.is_active = true
        AND (
          s.role IN ('super_admin'::public.user_role, 'receptionist'::public.user_role)
          OR (s.role = 'doctor'::public.user_role AND s.is_senior = true)
        )
    )
  );

DROP POLICY IF EXISTS "Super admins can delete medical history" ON public.patient_medical_history;
DROP POLICY IF EXISTS "Senior doctors and admins can delete medical history" ON public.patient_medical_history;

CREATE POLICY "Senior doctors and admins can delete medical history" ON public.patient_medical_history
  FOR DELETE TO authenticated
  USING (public.can_current_staff_modify_patient_programs(patient_id));
