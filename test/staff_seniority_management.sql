-- Disposable PostgreSQL only. No live accounts.
BEGIN;
INSERT INTO auth.users(id,email) VALUES
 ('10000000-0000-0000-0000-000000000011','senior-admin@example.test');
INSERT INTO public.staff(user_id,full_name,email,role) VALUES
 ('10000000-0000-0000-0000-000000000011','Admin','senior-admin@example.test','super_admin');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000011',true);
DO $$
DECLARE
  created_id uuid;
  doctor public.staff;
  old_password text;
BEGIN
  created_id := public.create_staff_account('senior-created@example.test',
    'test-password','New Senior','doctor',new_is_senior => true);
  SELECT * INTO doctor FROM public.staff WHERE user_id=created_id;
  IF NOT doctor.is_senior THEN RAISE EXCEPTION 'Creation lost senior status'; END IF;
  PERFORM public.update_staff_account(doctor.id,
    to_jsonb(doctor) || '{"is_senior":false}'::jsonb);
  IF (SELECT is_senior FROM public.staff WHERE id=doctor.id) THEN
    RAISE EXCEPTION 'Demotion failed'; END IF;
  PERFORM public.update_staff_account(doctor.id, to_jsonb(doctor));
  IF NOT (SELECT is_senior FROM public.staff WHERE id=doctor.id) THEN
    RAISE EXCEPTION 'Promotion failed'; END IF;
  BEGIN
    PERFORM public.create_staff_account('invalid-senior@example.test',
      'test-password','Invalid Senior','receptionist',new_is_senior => true);
    RAISE EXCEPTION 'TEST: non-doctor senior allowed';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM LIKE 'TEST:%' THEN RAISE; END IF;
  END;
  PERFORM public.update_staff_account(doctor.id,
    to_jsonb(doctor) || '{"role":"receptionist","is_senior":false}'::jsonb);
  IF (SELECT is_senior FROM public.staff WHERE id=doctor.id) THEN
    RAISE EXCEPTION 'Role change retained senior'; END IF;
END;
$$;
RESET ROLE;
DO $$
DECLARE
  doctor public.staff;
  old_password text;
BEGIN
  SELECT * INTO doctor FROM public.staff WHERE email='senior-created@example.test';
  SELECT encrypted_password INTO old_password FROM auth.users WHERE id=doctor.user_id;
  BEGIN
    PERFORM public.update_staff_account(doctor.id,
      to_jsonb(doctor) || '{"full_name":null}'::jsonb, 'changed-password');
    RAISE EXCEPTION 'TEST: invalid profile accepted';
  EXCEPTION WHEN not_null_violation THEN NULL;
  END;
  IF (SELECT encrypted_password FROM auth.users WHERE id=doctor.user_id) <> old_password THEN
    RAISE EXCEPTION 'Profile failure did not roll back password'; END IF;
  PERFORM set_config('request.jwt.claim.sub',doctor.user_id::text,true);
  BEGIN
    PERFORM public.update_staff_account(doctor.id,
      to_jsonb(doctor) || '{"role":"doctor","is_senior":true}'::jsonb);
    RAISE EXCEPTION 'TEST: non-admin promotion allowed';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM LIKE 'TEST:%' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.create_staff_account('blocked@example.test',
      'test-password','Blocked','doctor',new_is_senior => true);
    RAISE EXCEPTION 'TEST: non-admin creation allowed';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM LIKE 'TEST:%' THEN RAISE; END IF;
  END;
END;
$$;
ROLLBACK;
