-- Staff reference details: admin-only reads, atomic saves, validation and
-- unchanged behavior for callers that send no details. Disposable PostgreSQL only.
BEGIN;
INSERT INTO auth.users(id,email) VALUES
 ('10000000-0000-0000-0000-000000000071','details-admin@example.test'),
 ('10000000-0000-0000-0000-000000000072','details-desk@example.test');
INSERT INTO public.staff(user_id,full_name,email,role) VALUES
 ('10000000-0000-0000-0000-000000000071','Admin','details-admin@example.test','super_admin'),
 ('10000000-0000-0000-0000-000000000072','Desk','details-desk@example.test','receptionist');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000071',true);
DO $$
DECLARE
  created uuid; doctor public.staff; other public.staff; d public.staff_details; before_name text;
BEGIN
  -- Creation saves details with the account; days are sorted and de-duplicated.
  created := public.create_staff_account('details-doctor@example.test', 'test-password',
    'Dr Details', 'doctor', new_details => '{"national_id":"29001011234567","birth_date":"1990-01-01",
    "hire_date":"2024-03-01","working_days":[7,6,1,6],"work_starts_at":"09:00","work_ends_at":"17:30"}');
  SELECT * INTO doctor FROM public.staff WHERE user_id = created;
  SELECT * INTO d FROM public.staff_details WHERE staff_id = doctor.id;
  IF d.national_id IS DISTINCT FROM '29001011234567' OR d.working_days IS DISTINCT FROM '{1,6,7}'::smallint[]
    OR d.work_ends_at IS DISTINCT FROM '17:30'::time OR d.updated_by IS NULL THEN
    RAISE EXCEPTION 'Creation details wrong: %', d;
  END IF;

  -- Old callers: no details on create, and updates without a details key keep them.
  created := public.create_staff_account('details-plain@example.test', 'test-password', 'Plain', 'receptionist');
  SELECT * INTO other FROM public.staff WHERE user_id = created;
  IF EXISTS (SELECT 1 FROM public.staff_details WHERE staff_id = other.id) THEN
    RAISE EXCEPTION 'Details created without being sent'; END IF;
  PERFORM public.update_staff_account(doctor.id, to_jsonb(doctor) || '{"full_name":"Dr Renamed"}');
  IF (SELECT national_id FROM public.staff_details WHERE staff_id = doctor.id) IS NULL THEN
    RAISE EXCEPTION 'Update without details cleared them'; END IF;

  -- Updates replace details; empty values clear fields.
  PERFORM public.update_staff_account(doctor.id, to_jsonb(doctor) || jsonb_build_object('details',
    '{"national_id":"","birth_date":"1990-01-01","working_days":[],"work_starts_at":"","work_ends_at":""}'::jsonb));
  SELECT * INTO d FROM public.staff_details WHERE staff_id = doctor.id;
  IF d.national_id IS NOT NULL OR d.hire_date IS NOT NULL OR d.working_days <> '{}' OR d.work_starts_at IS NOT NULL THEN
    RAISE EXCEPTION 'Details were not cleared: %', d;
  END IF;

  -- Invalid details roll back the whole save, including the profile change.
  before_name := (SELECT full_name FROM public.staff WHERE id = doctor.id);
  BEGIN
    PERFORM public.update_staff_account(doctor.id, to_jsonb(doctor) || jsonb_build_object(
      'full_name', 'Should not stick', 'details', '{"national_id":"123"}'::jsonb));
    RAISE EXCEPTION 'TEST: short national ID accepted';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  IF (SELECT full_name FROM public.staff WHERE id = doctor.id) IS DISTINCT FROM before_name THEN
    RAISE EXCEPTION 'Failed details did not roll back the profile'; END IF;
  BEGIN
    PERFORM public.update_staff_account(doctor.id, to_jsonb(doctor) || jsonb_build_object('details',
      '{"work_starts_at":"17:00","work_ends_at":"09:00"}'::jsonb));
    RAISE EXCEPTION 'TEST: reversed hours accepted';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  BEGIN
    PERFORM public.update_staff_account(doctor.id, to_jsonb(doctor) || jsonb_build_object('details',
      '{"work_starts_at":"09:00"}'::jsonb));
    RAISE EXCEPTION 'TEST: start without end accepted';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  BEGIN
    PERFORM public.update_staff_account(doctor.id, to_jsonb(doctor) || jsonb_build_object('details',
      '{"working_days":[8]}'::jsonb));
    RAISE EXCEPTION 'TEST: weekday 8 accepted';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  BEGIN
    PERFORM public.update_staff_account(doctor.id, to_jsonb(doctor) || jsonb_build_object('details',
      jsonb_build_object('birth_date', (current_date + 3)::text)));
    RAISE EXCEPTION 'TEST: future birth date accepted';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  BEGIN
    PERFORM public.update_staff_account(doctor.id, to_jsonb(doctor) || jsonb_build_object('details',
      '{"birth_date":"2000-05-01","hire_date":"1999-01-01"}'::jsonb));
    RAISE EXCEPTION 'TEST: hire before birth accepted';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;

  -- National IDs are unique across staff.
  PERFORM public.update_staff_account(doctor.id, to_jsonb(doctor) || jsonb_build_object('details',
    '{"national_id":"29001011234567"}'::jsonb));
  BEGIN
    PERFORM public.update_staff_account(other.id, to_jsonb(other) || jsonb_build_object('details',
      '{"national_id":"29001011234567"}'::jsonb));
    RAISE EXCEPTION 'TEST: duplicate national ID accepted';
  EXCEPTION WHEN unique_violation THEN
    IF SQLERRM <> 'staff_national_id_taken' THEN RAISE; END IF;
  END;

  -- Only active super admins read details; clients cannot write them directly.
  IF has_function_privilege('authenticated', 'public.staff_save_details(uuid, jsonb, uuid)', 'execute') THEN
    RAISE EXCEPTION 'Detail writer is callable by clients'; END IF;
  PERFORM set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000072',true);
  IF EXISTS (SELECT 1 FROM public.staff_details) THEN RAISE EXCEPTION 'Receptionist read staff details'; END IF;
  BEGIN
    UPDATE public.staff_details SET national_id = NULL;
    INSERT INTO public.staff_details(staff_id) VALUES (other.id);
    RAISE EXCEPTION 'TEST: receptionist wrote staff details';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM public.update_staff_account(other.id, to_jsonb(other) || '{"details":{}}');
    RAISE EXCEPTION 'TEST: receptionist saved staff details';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM LIKE 'TEST:%' THEN RAISE; END IF;
  END;
  PERFORM set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000071',true);
  IF NOT EXISTS (SELECT 1 FROM public.staff_details WHERE national_id = '29001011234567') THEN
    RAISE EXCEPTION 'Admin cannot read staff details'; END IF;
END;
$$;
ROLLBACK;
