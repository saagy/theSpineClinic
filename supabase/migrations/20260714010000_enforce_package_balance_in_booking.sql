-- =============================================================================
-- Migration: Enforce Package Balance in Recurring and Single Bookings
-- Updates public.book_recurring_appointments to lock the patient record with
-- FOR UPDATE, calculate available package balance (current bucket balance minus
-- future scheduled appointments with use_package = true), and raise exception
-- P0002 if requested package sessions exceed available balance.
-- =============================================================================

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
     OR v_staff_role NOT IN ('receptionist', 'super_admin')
     OR v_staff_id IS DISTINCT FROM p_creator_id THEN
    RAISE EXCEPTION 'Permission denied.' USING ERRCODE = '42501';
  END IF;

  IF coalesce(array_length(p_slots, 1), 0) = 0
     OR coalesce(array_length(p_doctor_ids, 1), 0) = 0 THEN
    RAISE EXCEPTION 'At least one slot and doctor are required.';
  END IF;

  -- Enforce package balance limit when booking with use_package = true
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

    SELECT count(*) INTO v_future_commitments
    FROM public.appointments
    WHERE patient_id = p_patient_id
      AND type = p_type
      AND status = 'scheduled'::public.appointment_status
      AND use_package = true
      AND scheduled_at >= now();

    v_available_balance := coalesce(v_current_balance, 0) - coalesce(v_future_commitments, 0);

    IF v_required_sessions > v_available_balance THEN
      RAISE EXCEPTION 'Insufficient package balance. Available: %, Requested: %', v_available_balance, v_required_sessions
        USING ERRCODE = 'P0002';
    END IF;
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
      p_patient_id, p_type, v_slot, 'scheduled'::public.appointment_status, p_use_package, p_creator_id
    ) RETURNING id INTO v_appt_id;

    FOREACH v_doc_id IN ARRAY p_doctor_ids LOOP
      INSERT INTO public.appointment_doctors (
        appointment_id, doctor_id, is_active, added_by
      ) VALUES (v_appt_id, v_doc_id, true, p_creator_id);
    END LOOP;
  END LOOP;
END;
$function$;
