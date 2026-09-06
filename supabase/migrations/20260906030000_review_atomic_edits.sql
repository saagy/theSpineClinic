CREATE OR REPLACE FUNCTION public.update_patient_details(
  p_patient_id uuid,p_name text,p_phone text,p_program text,p_clinic public.clinic_location,
  p_doctor_ids uuid[] DEFAULT NULL
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
BEGIN
  IF NOT public.can_current_staff_access_patient(p_patient_id) THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE='42501';
  END IF;
  -- Demographic edits never write stale balances, authorship, or recall dates.
  UPDATE public.patients SET full_name=p_name,phone_number=p_phone,program=p_program,clinic=p_clinic
    WHERE id=p_patient_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Patient not found' USING ERRCODE='P0002'; END IF;
  IF p_doctor_ids IS NOT NULL THEN
    PERFORM public.update_patient_doctors(p_patient_id,p_doctor_ids);
  END IF;
END;
$$;
REVOKE ALL ON FUNCTION public.update_patient_details(uuid,text,text,text,public.clinic_location,uuid[]) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.update_patient_details(uuid,text,text,text,public.clinic_location,uuid[]) TO authenticated;

CREATE OR REPLACE FUNCTION public.update_appointment_details(
  p_appointment_id uuid,p_scheduled_at timestamptz,p_type public.appointment_type,
  p_use_package boolean,p_doctor_ids uuid[] DEFAULT NULL
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE existing_ids uuid[]; editor uuid;
BEGIN
  PERFORM 1 FROM public.appointments WHERE id=p_appointment_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Appointment not found' USING ERRCODE='P0002'; END IF;
  IF NOT public.can_current_staff_edit_appointment(p_appointment_id) THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE='42501';
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
  UPDATE public.appointments SET scheduled_at=p_scheduled_at,type=p_type,
    use_package=p_use_package AND p_type IN ('normal_pt_session','spinal_traction_session')
    WHERE id=p_appointment_id;
END;
$$;
REVOKE ALL ON FUNCTION public.update_appointment_details(uuid,timestamptz,public.appointment_type,boolean,uuid[]) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.update_appointment_details(uuid,timestamptz,public.appointment_type,boolean,uuid[]) TO authenticated;
