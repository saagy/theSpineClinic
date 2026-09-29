-- Proves the optimized SELECT policies return the same rows as the original
-- per-patient permission function for every role and both assignment paths.
BEGIN;
INSERT INTO auth.users(id,email)
 SELECT md5('access-user'||g)::uuid,'access'||g||'@example.test' FROM generate_series(1,6) g;
INSERT INTO staff(id,user_id,full_name,email,role,is_senior,is_active)
 SELECT md5('access-staff'||g)::uuid,md5('access-user'||g)::uuid,'Access fixture',
 'access'||g||'@example.test',
 CASE WHEN g=1 THEN 'super_admin' WHEN g=2 THEN 'receptionist' ELSE 'doctor' END::user_role,
 g=3,g<>6 FROM generate_series(1,6) g;
INSERT INTO patients(id,full_name,phone_number,clinic)
 SELECT md5('access-patient'||g)::uuid,'Access fixture '||g,'000','tagamoa' FROM generate_series(1,5) g;
INSERT INTO patient_doctors(patient_id,doctor_id) VALUES
 (md5('access-patient1')::uuid,md5('access-staff4')::uuid),
 (md5('access-patient2')::uuid,md5('access-staff5')::uuid);
INSERT INTO appointments(id,patient_id,type,use_package)
 SELECT md5('access-appt'||g)::uuid,md5('access-patient'||g)::uuid,'normal_pt_session',false
 FROM generate_series(1,5) g;
INSERT INTO appointment_doctors(appointment_id,doctor_id,is_active) VALUES
 (md5('access-appt3')::uuid,md5('access-staff4')::uuid,true),
 (md5('access-appt4')::uuid,md5('access-staff4')::uuid,false);
DO $$
DECLARE actor integer; expected uuid[]; actual uuid[]; actual_appointments uuid[];
BEGIN
  FOR actor IN 1..6 LOOP
    PERFORM set_config('request.jwt.claim.sub',md5('access-user'||actor)::uuid::text,true);
    SELECT coalesce(array_agg(id ORDER BY id),'{}') INTO expected FROM patients
      WHERE can_current_staff_access_patient(id);
    EXECUTE 'SET LOCAL ROLE authenticated';
    SELECT coalesce(array_agg(id ORDER BY id),'{}') INTO actual FROM patients;
    SELECT coalesce(array_agg(patient_id ORDER BY patient_id),'{}') INTO actual_appointments FROM appointments;
    IF expected<>actual OR expected<>actual_appointments THEN
      RAISE EXCEPTION 'Read access changed for actor %: %, %, %',actor,expected,actual,actual_appointments;
    END IF;
    EXECUTE 'RESET ROLE';
  END LOOP;
  PERFORM set_config('request.jwt.claim.sub','',true);
  EXECUTE 'SET LOCAL ROLE authenticated';
  IF EXISTS(SELECT 1 FROM patients) OR EXISTS(SELECT 1 FROM appointments) THEN
    RAISE EXCEPTION 'Missing identity can read rows'; END IF;
  IF has_function_privilege('anon','public.current_staff_accessible_patient_ids()','EXECUTE') THEN
    RAISE EXCEPTION 'Anonymous access to patient IDs'; END IF;
END $$;
ROLLBACK;
