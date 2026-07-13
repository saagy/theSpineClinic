ALTER TABLE public.patients
ADD COLUMN next_visit_date date;

CREATE INDEX idx_patients_clinic_next_visit
ON public.patients (clinic, next_visit_date)
WHERE next_visit_date IS NOT NULL;

CREATE OR REPLACE FUNCTION public.clinic_timezone()
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $function$
  SELECT 'Africa/Cairo'::text;
$function$;

CREATE OR REPLACE FUNCTION public.get_due_patients(
  p_due_on date,
  p_doctor_id uuid,
  p_clinic public.clinic_location
)
RETURNS SETOF public.patients
LANGUAGE sql
STABLE
SECURITY INVOKER
AS $function$
  SELECT p.*
  FROM public.patients p
  JOIN public.patient_doctors pd ON pd.patient_id = p.id
  WHERE pd.doctor_id = p_doctor_id
    AND p.clinic = p_clinic
    AND p.next_visit_date IS NOT NULL
    AND p.next_visit_date <= p_due_on
    AND NOT EXISTS (
      SELECT 1
      FROM public.appointments a
      WHERE a.patient_id = p.id
        AND a.status = 'scheduled'::public.appointment_status
        AND (a.scheduled_at AT TIME ZONE public.clinic_timezone())::date >= p.next_visit_date
    )
  ORDER BY p.next_visit_date, p.full_name;
$function$;

DROP FUNCTION public.book_recurring_appointments(
  uuid,
  public.appointment_type,
  timestamptz[],
  boolean,
  uuid,
  uuid[]
);

CREATE FUNCTION public.book_recurring_appointments(
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
BEGIN
  SELECT staff_id, staff_role, staff_active
  INTO v_staff_id, v_staff_role, v_staff_active
  FROM public.get_auth_staff_profile();

  IF v_staff_active IS DISTINCT FROM true
     OR v_staff_role NOT IN ('receptionist', 'super_admin')
     OR v_staff_id IS DISTINCT FROM p_creator_id THEN
    RAISE EXCEPTION 'Permission denied.' USING ERRCODE = '42501';
  END IF;

  IF coalesce(array_length(p_slots, 1), 0) = 0
     OR coalesce(array_length(p_doctor_ids, 1), 0) = 0 THEN
    RAISE EXCEPTION 'At least one slot and doctor are required.';
  END IF;

  IF p_expected_next_visit_date IS NOT NULL THEN
    SELECT next_visit_date
    INTO v_next_visit
    FROM public.patients
    WHERE id = p_patient_id
    FOR UPDATE;

    IF v_next_visit IS DISTINCT FROM p_expected_next_visit_date
       OR EXISTS (
         SELECT 1
         FROM unnest(p_slots) AS slots(slot)
         WHERE (slots.slot AT TIME ZONE public.clinic_timezone())::date
               < v_next_visit
       )
       OR EXISTS (
         SELECT 1
         FROM public.appointments a
         WHERE a.patient_id = p_patient_id
           AND a.status = 'scheduled'::public.appointment_status
           AND (a.scheduled_at AT TIME ZONE public.clinic_timezone())::date >= v_next_visit
       ) THEN
      RAISE EXCEPTION 'Patient is no longer due for booking.'
        USING ERRCODE = 'P0001';
    END IF;
  END IF;

  FOREACH v_slot IN ARRAY p_slots LOOP
    INSERT INTO public.appointments (
      patient_id, type, scheduled_at, status, use_package, created_by
    ) VALUES (
      p_patient_id, p_type, v_slot, 'scheduled', p_use_package, p_creator_id
    ) RETURNING id INTO v_appt_id;

    FOREACH v_doc_id IN ARRAY p_doctor_ids LOOP
      INSERT INTO public.appointment_doctors (
        appointment_id, doctor_id, is_active, added_by
      ) VALUES (v_appt_id, v_doc_id, true, p_creator_id);
    END LOOP;
  END LOOP;
END;
$function$;

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
     OR v_role NOT IN ('receptionist', 'super_admin') THEN
    RAISE EXCEPTION 'Permission denied.' USING ERRCODE = '42501';
  END IF;

  IF coalesce(array_length(p_appointment_ids, 1), 0) = 0
     OR coalesce(array_length(p_replacement_doctor_ids, 1), 0) = 0
     OR p_absent_doctor_id = ANY(p_replacement_doctor_ids) THEN
    RAISE EXCEPTION 'Invalid replacement selection.';
  END IF;

  SELECT count(DISTINCT id)::integer
  INTO v_expected
  FROM public.staff
  WHERE id = ANY(p_replacement_doctor_ids)
    AND role = 'doctor'
    AND is_active = true;

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

  SELECT count(DISTINCT a.id)::integer
  INTO v_expected
  FROM public.appointments a
  JOIN public.appointment_doctors ad ON ad.appointment_id = a.id
  WHERE a.id = ANY(p_appointment_ids)
    AND a.status <> 'cancelled'
    AND (a.scheduled_at AT TIME ZONE public.clinic_timezone())::date = p_day
    AND ad.doctor_id = p_absent_doctor_id
    AND ad.is_active = true;

  IF v_expected <> cardinality(p_appointment_ids) THEN
    RAISE EXCEPTION 'One or more appointments are no longer replaceable.';
  END IF;

  FOREACH v_appointment_id IN ARRAY p_appointment_ids LOOP
    UPDATE public.appointment_doctors
    SET is_active = false
    WHERE appointment_id = v_appointment_id
      AND doctor_id = p_absent_doctor_id
      AND is_active = true;

    FOREACH v_doctor_id IN ARRAY p_replacement_doctor_ids LOOP
      UPDATE public.appointment_doctors
      SET is_active = true, added_by = v_editor_id, added_at = now()
      WHERE id = (
        SELECT id
        FROM public.appointment_doctors
        WHERE appointment_id = v_appointment_id
          AND doctor_id = v_doctor_id
          AND is_active = false
        ORDER BY added_at DESC
        LIMIT 1
      );

      IF NOT FOUND THEN
        INSERT INTO public.appointment_doctors (
          appointment_id, doctor_id, is_active, added_by
        ) VALUES (v_appointment_id, v_doctor_id, true, v_editor_id);
      END IF;
    END LOOP;
  END LOOP;

  RETURN QUERY
  SELECT cardinality(p_appointment_ids)::integer,
         count(DISTINCT a.id)::integer
  FROM public.appointments a
  JOIN public.appointment_doctors ad ON ad.appointment_id = a.id
  WHERE a.status <> 'cancelled'
    AND (a.scheduled_at AT TIME ZONE public.clinic_timezone())::date = p_day
    AND ad.doctor_id = p_absent_doctor_id
    AND ad.is_active = true;
END;
$function$;
