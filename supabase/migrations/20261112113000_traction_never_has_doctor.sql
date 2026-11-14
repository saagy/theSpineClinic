-- Spinal traction is always done without a doctor: a traction appointment
-- never has one assigned, and every other type needs at least one. This
-- tightens 20261112110000, which only made the doctor optional.

CREATE OR REPLACE FUNCTION public.book_recurring_appointments(
  p_patient_id uuid, p_type public.appointment_type, p_slots timestamptz[],
  p_use_package boolean, p_creator_id uuid, p_doctor_ids uuid[],
  p_expected_next_visit_date date DEFAULT NULL
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE patient public.patients; slot timestamptz; appt uuid; doctor uuid;
  available integer; commitments integer; use_credit boolean;
  doctors uuid[] := coalesce(p_doctor_ids,'{}'::uuid[]);
BEGIN
  IF NOT public.current_staff_has_management_access()
      OR p_creator_id IS DISTINCT FROM (SELECT staff_id FROM public.get_auth_staff_profile()) THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE='42501';
  END IF;
  IF coalesce(cardinality(p_slots),0)=0 OR array_position(p_slots,NULL) IS NOT NULL THEN
    RAISE EXCEPTION 'At least one valid slot is required' USING ERRCODE='22000';
  END IF;
  IF p_type='spinal_traction_session' AND cardinality(doctors)>0 THEN
    RAISE EXCEPTION 'Spinal traction is booked without a doctor' USING ERRCODE='22000';
  END IF;
  IF p_type<>'spinal_traction_session' AND cardinality(doctors)=0 THEN
    RAISE EXCEPTION 'At least one doctor must be assigned' USING ERRCODE='22000';
  END IF;
  IF (SELECT count(DISTINCT value) FROM unnest(p_slots) value)<>cardinality(p_slots) THEN
    RAISE EXCEPTION 'Duplicate booking slots' USING ERRCODE='22000';
  END IF;
  IF (SELECT count(*) FROM public.staff WHERE id=ANY(doctors) AND role='doctor' AND is_active)
      <>cardinality(doctors) THEN
    RAISE EXCEPTION 'Every assigned doctor must be active' USING ERRCODE='22000';
  END IF;
  -- Serialize package checks and due-queue claims for this patient.
  SELECT * INTO patient FROM public.patients WHERE id=p_patient_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Patient not found' USING ERRCODE='P0002'; END IF;
  IF p_expected_next_visit_date IS NOT NULL AND (
      patient.next_visit_date IS DISTINCT FROM p_expected_next_visit_date
      OR EXISTS(SELECT 1 FROM public.appointments WHERE patient_id=p_patient_id
        AND status='scheduled' AND (scheduled_at AT TIME ZONE public.clinic_timezone())::date>=patient.next_visit_date)
      OR EXISTS(SELECT 1 FROM unnest(p_slots) s
        WHERE (s AT TIME ZONE public.clinic_timezone())::date<patient.next_visit_date)) THEN
    RAISE EXCEPTION 'Patient is no longer due for booking.' USING ERRCODE='P0001';
  END IF;
  use_credit := coalesce(p_use_package,false) AND p_type IN ('normal_pt_session','spinal_traction_session');
  IF use_credit THEN
    SELECT count(*) INTO commitments FROM public.appointments WHERE patient_id=p_patient_id
      AND type=p_type AND use_package AND status='scheduled' AND scheduled_at>now();
    available := CASE WHEN p_type='normal_pt_session' THEN patient.session_balance ELSE patient.traction_balance END - commitments;
    IF cardinality(p_slots)>available THEN
      RAISE EXCEPTION 'Insufficient package balance' USING ERRCODE='22000';
    END IF;
  END IF;
  FOREACH slot IN ARRAY p_slots LOOP
    INSERT INTO public.appointments(patient_id,type,scheduled_at,status,use_package,created_by)
      VALUES(p_patient_id,p_type,slot,'scheduled',use_credit,p_creator_id) RETURNING id INTO appt;
    FOREACH doctor IN ARRAY doctors LOOP
      INSERT INTO public.appointment_doctors(appointment_id,doctor_id,is_active,added_by)
        VALUES(appt,doctor,true,p_creator_id);
    END LOOP;
  END LOOP;
  IF p_expected_next_visit_date IS NULL THEN
    UPDATE public.patients SET next_visit_date=(SELECT (scheduled_at AT TIME ZONE public.clinic_timezone())::date
      FROM public.appointments WHERE patient_id=p_patient_id AND status='scheduled' AND scheduled_at>=now()
      ORDER BY scheduled_at LIMIT 1) WHERE id=p_patient_id;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_appointment_doctors(
  p_appointment_id uuid,
  p_doctor_ids uuid[],
  p_editor_id uuid DEFAULT NULL::uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
DECLARE
  v_staff_id   uuid;
  v_staff_role public.user_role;
  v_active     boolean;
  invalid_count integer;
  v_now        timestamptz := now();
  v_doctors    uuid[] := coalesce(p_doctor_ids, '{}'::uuid[]);
  v_traction   boolean;
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

  SELECT a.type = 'spinal_traction_session' INTO v_traction
    FROM public.appointments a WHERE a.id = p_appointment_id;
  IF coalesce(v_traction, false) AND cardinality(v_doctors) > 0 THEN
    RAISE EXCEPTION 'Spinal traction is booked without a doctor'
      USING ERRCODE = '22000';
  END IF;
  IF NOT coalesce(v_traction, false) AND cardinality(v_doctors) = 0 THEN
    RAISE EXCEPTION 'At least one doctor must be assigned'
      USING ERRCODE = '22000';
  END IF;

  SELECT count(*) INTO invalid_count
  FROM unnest(v_doctors) AS did
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
     AND doctor_id != ALL(v_doctors);

  UPDATE public.appointment_doctors
     SET is_active = true,
         added_by  = coalesce(p_editor_id, v_staff_id),
         added_at  = v_now
   WHERE appointment_id = p_appointment_id
     AND is_active = false
     AND doctor_id = ANY(v_doctors);

  INSERT INTO public.appointment_doctors (appointment_id, doctor_id, is_active, added_by, added_at)
  SELECT p_appointment_id, unnest, true, coalesce(p_editor_id, v_staff_id), v_now
    FROM unnest(v_doctors)
   WHERE unnest NOT IN (
     SELECT doctor_id FROM public.appointment_doctors
      WHERE appointment_id = p_appointment_id
   );
END;
$function$;

-- The type is saved first. Changing a visit to traction releases its
-- doctors; any other type must end up with at least one.
CREATE OR REPLACE FUNCTION public.update_appointment_details(
  p_appointment_id uuid, p_scheduled_at timestamptz, p_type public.appointment_type,
  p_use_package boolean, p_doctor_ids uuid[] DEFAULT NULL
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE existing_ids uuid[]; editor uuid;
BEGIN
  PERFORM 1 FROM public.appointments WHERE id=p_appointment_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Appointment not found' USING ERRCODE='P0002'; END IF;
  IF NOT public.can_current_staff_edit_appointment(p_appointment_id) THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE='42501';
  END IF;
  UPDATE public.appointments SET scheduled_at=p_scheduled_at,type=p_type,
    use_package=p_use_package AND p_type IN ('normal_pt_session','spinal_traction_session')
    WHERE id=p_appointment_id;
  IF p_type='spinal_traction_session' THEN
    UPDATE public.appointment_doctors SET is_active=false
      WHERE appointment_id=p_appointment_id AND is_active;
    RETURN;
  END IF;
  IF p_doctor_ids IS NOT NULL THEN
    SELECT array_agg(doctor_id ORDER BY doctor_id) INTO existing_ids
      FROM public.appointment_doctors WHERE appointment_id=p_appointment_id AND is_active;
    IF coalesce(existing_ids,'{}'::uuid[]) IS DISTINCT FROM
        (SELECT coalesce(array_agg(id ORDER BY id),'{}'::uuid[]) FROM unnest(p_doctor_ids) id) THEN
      SELECT staff_id INTO editor FROM public.get_auth_staff_profile();
      PERFORM public.update_appointment_doctors(p_appointment_id,p_doctor_ids,editor);
    END IF;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.appointment_doctors
      WHERE appointment_id=p_appointment_id AND is_active) THEN
    RAISE EXCEPTION 'At least one doctor must be assigned' USING ERRCODE='22000';
  END IF;
END;
$$;
