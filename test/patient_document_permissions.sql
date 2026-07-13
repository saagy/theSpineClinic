-- Run against a disposable migrated database:
--   psql "$DATABASE_URL" -f test/patient_document_permissions.sql

\set ON_ERROR_STOP on

BEGIN;

CREATE FUNCTION pg_temp.assert_document_crud(
  p_user_id uuid,
  p_staff_id uuid,
  p_patient_id uuid
) RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_document_id uuid;
  v_count integer;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', p_user_id::text, true);
  INSERT INTO public.patient_documents (
    patient_id,
    file_url,
    file_name,
    uploaded_by
  ) VALUES (
    p_patient_id,
    'https://example.test/' || p_staff_id || '.pdf',
    'original.pdf',
    p_staff_id
  ) RETURNING id INTO v_document_id;

  SELECT count(*) INTO v_count
  FROM public.patient_documents
  WHERE id = v_document_id;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'Expected document SELECT access for %', p_staff_id;
  END IF;

  UPDATE public.patient_documents
  SET file_name = 'renamed.pdf'
  WHERE id = v_document_id;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'Expected document rename access for %', p_staff_id;
  END IF;

  DELETE FROM public.patient_documents WHERE id = v_document_id;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'Expected document DELETE access for %', p_staff_id;
  END IF;
END;
$$;

CREATE FUNCTION pg_temp.assert_document_denied(
  p_user_id uuid,
  p_document_id uuid
) RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_count integer;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', p_user_id::text, true);
  SELECT count(*) INTO v_count
  FROM public.patient_documents
  WHERE id = p_document_id;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'Unexpected document SELECT access for %', p_user_id;
  END IF;

  UPDATE public.patient_documents
  SET file_name = 'blocked.pdf'
  WHERE id = p_document_id;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'Unexpected document rename access for %', p_user_id;
  END IF;
END;
$$;

INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_super_admin,
  created_at,
  updated_at,
  confirmation_token,
  recovery_token,
  email_change_token_new,
  email_change
)
SELECT
  '00000000-0000-0000-0000-000000000000'::uuid,
  id,
  'authenticated',
  'authenticated',
  email,
  '',
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{}'::jsonb,
  false,
  now(),
  now(),
  '',
  '',
  '',
  ''
FROM (VALUES
  ('10000000-0000-0000-0000-000000000001'::uuid, 'admin@test.local'),
  ('10000000-0000-0000-0000-000000000002'::uuid, 'reception@test.local'),
  ('10000000-0000-0000-0000-000000000003'::uuid, 'assigned@test.local'),
  ('10000000-0000-0000-0000-000000000004'::uuid, 'appointment@test.local'),
  ('10000000-0000-0000-0000-000000000006'::uuid, 'unrelated@test.local'),
  ('10000000-0000-0000-0000-000000000007'::uuid, 'inactive@test.local')
) AS users(id, email);

INSERT INTO public.staff (id, user_id, full_name, email, role, is_active)
VALUES
  ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Admin', 'admin@test.local', 'super_admin', true),
  ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', 'Reception', 'reception@test.local', 'receptionist', true),
  ('20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000003', 'Assigned', 'assigned@test.local', 'doctor', true),
  ('20000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000004', 'Appointment', 'appointment@test.local', 'doctor', true),
  ('20000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000006', 'Unrelated', 'unrelated@test.local', 'doctor', true),
  ('20000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000007', 'Inactive', 'inactive@test.local', 'doctor', false);

INSERT INTO public.patients (id, full_name, phone_number, clinic)
VALUES ('30000000-0000-0000-0000-000000000001', 'RLS Patient', '01000000000', 'tagamoa');
INSERT INTO public.patient_doctors (patient_id, doctor_id)
VALUES
  ('30000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000003'),
  ('30000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000007');
INSERT INTO public.appointments (id, patient_id, type, scheduled_at)
VALUES ('40000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 'normal_pt_session', now() - interval '3 years');
INSERT INTO public.appointment_doctors (appointment_id, doctor_id, is_active)
VALUES ('40000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000004', true);
INSERT INTO public.patient_documents (id, patient_id, file_url, file_name, uploaded_by)
VALUES ('50000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 'https://example.test/shared.pdf', 'shared.pdf', '20000000-0000-0000-0000-000000000001');

SET LOCAL ROLE authenticated;
SELECT pg_temp.assert_document_crud('10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001');
SELECT pg_temp.assert_document_crud('10000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000001');
SELECT pg_temp.assert_document_crud('10000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000001');
SELECT pg_temp.assert_document_crud('10000000-0000-0000-0000-000000000004', '20000000-0000-0000-0000-000000000004', '30000000-0000-0000-0000-000000000001');
SELECT pg_temp.assert_document_denied('10000000-0000-0000-0000-000000000006', '50000000-0000-0000-0000-000000000001');
SELECT pg_temp.assert_document_denied('10000000-0000-0000-0000-000000000007', '50000000-0000-0000-0000-000000000001');

DO $$
BEGIN
  PERFORM set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000004', true);
  BEGIN
    UPDATE public.patient_documents
    SET file_url = 'https://example.test/blocked.pdf'
    WHERE id = '50000000-0000-0000-0000-000000000001';
    RAISE EXCEPTION 'Authenticated staff updated file_url';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END;
$$;

RESET ROLE;
ROLLBACK;

\echo 'Patient document permission tests passed and rolled back.'
