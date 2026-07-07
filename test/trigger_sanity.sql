-- Trigger sanity tests for appointment and payment balance sync.
-- Run manually against a disposable database or development project:
--   psql "$DATABASE_URL" -f test/trigger_sanity.sql
--
-- The script creates synthetic rows inside one transaction and always rolls
-- back. Any failed expectation raises an exception.

\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  v_doctor_id uuid := gen_random_uuid();
  v_patient_id uuid := gen_random_uuid();
  v_appt_id uuid;
  v_payment_id uuid;
  v_session_balance integer;
  v_traction_balance integer;
BEGIN
  INSERT INTO public.staff (id, full_name, email, role, is_active)
  VALUES (
    v_doctor_id,
    'Trigger Test Doctor',
    'trigger-test-doctor@example.test',
    'doctor'::public.user_role,
    true
  );

  INSERT INTO public.patients (
    id,
    full_name,
    phone_number,
    clinic,
    session_balance,
    traction_balance
  )
  VALUES (
    v_patient_id,
    'Trigger Test Patient',
    '0000000000',
    'tagamoa'::public.clinic_location,
    10,
    5
  );

  INSERT INTO public.patient_doctors (patient_id, doctor_id)
  VALUES (v_patient_id, v_doctor_id);

  INSERT INTO public.appointments (patient_id, type, scheduled_at, use_package)
  VALUES (
    v_patient_id,
    'normal_pt_session'::public.appointment_type,
    now(),
    true
  )
  RETURNING id INTO v_appt_id;

  UPDATE public.appointments SET status = 'completed'
  WHERE id = v_appt_id;

  SELECT session_balance, traction_balance
  INTO v_session_balance, v_traction_balance
  FROM public.patients
  WHERE id = v_patient_id;

  IF v_session_balance != 9 OR v_traction_balance != 5 THEN
    RAISE EXCEPTION 'Normal session deduction failed: session %, traction %',
      v_session_balance, v_traction_balance;
  END IF;

  INSERT INTO public.appointments (patient_id, type, scheduled_at, use_package)
  VALUES (
    v_patient_id,
    'spinal_traction_session'::public.appointment_type,
    now() + interval '1 hour',
    true
  )
  RETURNING id INTO v_appt_id;

  UPDATE public.appointments SET status = 'checked_in'
  WHERE id = v_appt_id;

  SELECT traction_balance INTO v_traction_balance
  FROM public.patients
  WHERE id = v_patient_id;

  IF v_traction_balance != 4 THEN
    RAISE EXCEPTION 'Traction deduction failed: traction %',
      v_traction_balance;
  END IF;

  UPDATE public.appointments SET status = 'cancelled'
  WHERE id = v_appt_id;

  SELECT traction_balance INTO v_traction_balance
  FROM public.patients
  WHERE id = v_patient_id;

  IF v_traction_balance != 5 THEN
    RAISE EXCEPTION 'Traction refund failed: traction %',
      v_traction_balance;
  END IF;

  INSERT INTO public.appointments (patient_id, type, scheduled_at, use_package)
  VALUES (
    v_patient_id,
    'initial_assessment'::public.appointment_type,
    now() + interval '2 hours',
    true
  )
  RETURNING id INTO v_appt_id;

  UPDATE public.appointments SET status = 'completed'
  WHERE id = v_appt_id;

  SELECT session_balance, traction_balance
  INTO v_session_balance, v_traction_balance
  FROM public.patients
  WHERE id = v_patient_id;

  IF v_session_balance != 9 OR v_traction_balance != 5 THEN
    RAISE EXCEPTION 'Assessment should not change balances: session %, traction %',
      v_session_balance, v_traction_balance;
  END IF;

  INSERT INTO public.appointments (patient_id, type, scheduled_at, use_package)
  VALUES (
    v_patient_id,
    'normal_pt_session'::public.appointment_type,
    now() + interval '3 hours',
    false
  )
  RETURNING id INTO v_appt_id;

  UPDATE public.appointments SET status = 'completed'
  WHERE id = v_appt_id;

  SELECT session_balance INTO v_session_balance
  FROM public.patients
  WHERE id = v_patient_id;

  IF v_session_balance != 9 THEN
    RAISE EXCEPTION 'Non-package appointment should not deduct: session %',
      v_session_balance;
  END IF;

  INSERT INTO public.payment_records (
    patient_id,
    amount,
    reason,
    session_balance_added,
    traction_balance_added
  )
  VALUES (
    v_patient_id,
    1000,
    'Package test payment',
    8,
    4
  )
  RETURNING id INTO v_payment_id;

  SELECT session_balance, traction_balance
  INTO v_session_balance, v_traction_balance
  FROM public.patients
  WHERE id = v_patient_id;

  IF v_session_balance != 17 OR v_traction_balance != 9 THEN
    RAISE EXCEPTION 'Payment credit failed: session %, traction %',
      v_session_balance, v_traction_balance;
  END IF;

  DELETE FROM public.payment_records WHERE id = v_payment_id;

  SELECT session_balance, traction_balance
  INTO v_session_balance, v_traction_balance
  FROM public.patients
  WHERE id = v_patient_id;

  IF v_session_balance != 9 OR v_traction_balance != 5 THEN
    RAISE EXCEPTION 'Payment delete reversal failed: session %, traction %',
      v_session_balance, v_traction_balance;
  END IF;
END;
$$;

ROLLBACK;

\echo 'Trigger sanity tests passed and rolled back.'
