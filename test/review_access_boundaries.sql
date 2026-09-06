-- Run only in a disposable database. Direct SQL role tests, not UI mocks.
BEGIN;
INSERT INTO auth.users(id, email) VALUES
 ('10000000-0000-0000-0000-000000000001', 'review-admin@example.test'),
 ('10000000-0000-0000-0000-000000000002', 'review-doctor@example.test'),
 ('10000000-0000-0000-0000-000000000003', 'review-other@example.test');
INSERT INTO public.staff(id, user_id, full_name, email, role) VALUES
 ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Review admin', 'review-admin@example.test', 'super_admin'),
 ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', 'Review doctor', 'review-doctor@example.test', 'doctor'),
 ('20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000003', 'Review other', 'review-other@example.test', 'doctor');
INSERT INTO public.patients(id, full_name, phone_number, clinic) VALUES
 ('30000000-0000-0000-0000-000000000001', 'Review assigned', '000', 'tagamoa'),
 ('30000000-0000-0000-0000-000000000002', 'Review private', '001', 'tagamoa');
INSERT INTO public.patient_doctors(patient_id, doctor_id) VALUES
 ('30000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002'),
 ('30000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000003');
INSERT INTO public.appointments(id, patient_id, type, use_package) VALUES
 ('40000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 'initial_assessment', false),
 ('40000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000002', 'initial_assessment', false);
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000002', true);
DO $$
DECLARE n integer;
BEGIN
  BEGIN
    INSERT INTO public.appointment_doctors(appointment_id, doctor_id) VALUES
      ('40000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002');
    RAISE EXCEPTION 'SECURITY: doctor can self-assign to an unrelated patient';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  SELECT count(*) INTO n FROM public.patients
    WHERE id='30000000-0000-0000-0000-000000000002';
  IF n <> 0 THEN RAISE EXCEPTION 'SECURITY: unrelated patient is visible'; END IF;
  UPDATE public.appointments SET status='checked_in'
    WHERE id='40000000-0000-0000-0000-000000000002';
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 0 THEN RAISE EXCEPTION 'SECURITY: unrelated appointment is writable'; END IF;
  UPDATE public.appointments SET status='checked_in'
    WHERE id='40000000-0000-0000-0000-000000000001';
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n <> 1 THEN RAISE EXCEPTION 'Assigned doctor cannot check in'; END IF;
  BEGIN
    UPDATE public.patients SET session_balance=999
      WHERE id='30000000-0000-0000-0000-000000000001';
    RAISE EXCEPTION 'SECURITY: doctor can modify package credits directly';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    UPDATE public.staff SET is_senior=true
      WHERE id='20000000-0000-0000-0000-000000000002';
    RAISE EXCEPTION 'SECURITY: doctor can promote self';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM LIKE 'SECURITY:%' THEN RAISE; END IF;
  END;
END;
$$;
RESET ROLE;
SELECT set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000001', true);
UPDATE public.staff SET is_active=false WHERE id='20000000-0000-0000-0000-000000000002';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000002', true);
DO $$
BEGIN
  IF EXISTS(SELECT 1 FROM public.patients) THEN RAISE EXCEPTION 'Inactive staff can read patients'; END IF;
  IF EXISTS(SELECT 1 FROM public.appointments) THEN RAISE EXCEPTION 'Inactive staff can read appointments'; END IF;
END;
$$;
RESET ROLE;
SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claim.sub', '', true);
DO $$
BEGIN
  IF has_function_privilege('anon', 'public.create_staff_user(text,text,text,public.user_role,text,boolean,public.clinic_location)', 'EXECUTE') THEN
    RAISE EXCEPTION 'Admin RPC remains executable by anonymous callers';
  END IF;
END;
$$;
ROLLBACK;
