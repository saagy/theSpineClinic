-- Run against a disposable database after migrations:
--   psql "$DATABASE_URL" -f test/doctor_role_integrity.sql

\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  v_admin_id uuid := gen_random_uuid();
  v_doctor_id uuid := gen_random_uuid();
  v_patient_id uuid := gen_random_uuid();
  v_appointment_id uuid := gen_random_uuid();
BEGIN
  INSERT INTO public.staff (id, full_name, email, role, is_active)
  VALUES
    (v_admin_id, 'Integrity Admin', v_admin_id::text || '@example.test', 'super_admin', true),
    (v_doctor_id, 'Integrity Doctor', v_doctor_id::text || '@example.test', 'doctor', true);

  INSERT INTO public.patients (
    id,
    full_name,
    phone_number,
    clinic
  ) VALUES (
    v_patient_id,
    'Integrity Patient',
    v_patient_id::text,
    'tagamoa'
  );

  INSERT INTO public.patient_doctors (patient_id, doctor_id)
  VALUES (v_patient_id, v_doctor_id);

  INSERT INTO public.appointments (
    id,
    patient_id,
    type,
    scheduled_at
  ) VALUES (
    v_appointment_id,
    v_patient_id,
    'normal_pt_session',
    now()
  );

  INSERT INTO public.appointment_doctors (
    appointment_id,
    doctor_id
  ) VALUES (
    v_appointment_id,
    v_doctor_id
  );

  BEGIN
    INSERT INTO public.patient_doctors (patient_id, doctor_id)
    VALUES (v_patient_id, v_admin_id);
    RAISE EXCEPTION 'patient_doctors accepted a Clinic Admin';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    INSERT INTO public.appointment_doctors (appointment_id, doctor_id)
    VALUES (v_appointment_id, v_admin_id);
    RAISE EXCEPTION 'appointment_doctors accepted a Clinic Admin';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;

  BEGIN
    UPDATE public.staff SET role = 'receptionist' WHERE id = v_doctor_id;
    RAISE EXCEPTION 'referenced doctor role change was accepted';
  EXCEPTION WHEN check_violation THEN
    NULL;
  END;
END;
$$;

ROLLBACK;

\echo 'Doctor role integrity tests passed and rolled back.'
