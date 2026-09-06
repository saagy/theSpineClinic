CREATE OR REPLACE FUNCTION public.book_recurring_appointments(
  p_patient_id uuid, p_type public.appointment_type, p_slots timestamptz[],
  p_use_package boolean, p_creator_id uuid, p_doctor_ids uuid[],
  p_expected_next_visit_date date DEFAULT NULL
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE patient public.patients; slot timestamptz; appt uuid; doctor uuid;
  available integer; commitments integer; use_credit boolean;
BEGIN
  IF NOT public.current_staff_has_management_access()
      OR p_creator_id IS DISTINCT FROM (SELECT staff_id FROM public.get_auth_staff_profile()) THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE='42501';
  END IF;
  IF coalesce(cardinality(p_slots),0)=0 OR coalesce(cardinality(p_doctor_ids),0)=0
      OR array_position(p_slots,NULL) IS NOT NULL THEN
    RAISE EXCEPTION 'At least one valid slot and doctor are required' USING ERRCODE='22000';
  END IF;
  IF (SELECT count(DISTINCT value) FROM unnest(p_slots) value)<>cardinality(p_slots) THEN
    RAISE EXCEPTION 'Duplicate booking slots' USING ERRCODE='22000';
  END IF;
  IF (SELECT count(*) FROM public.staff WHERE id=ANY(p_doctor_ids) AND role='doctor' AND is_active)
      <>cardinality(p_doctor_ids) THEN
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
    FOREACH doctor IN ARRAY p_doctor_ids LOOP
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
