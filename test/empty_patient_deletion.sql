-- Disposable PostgreSQL test only. No real patient data.
BEGIN;
INSERT INTO auth.users(id, email) VALUES
 ('90000000-0000-0000-0000-000000000001', 'empty-admin@example.test'),
 ('90000000-0000-0000-0000-000000000002', 'empty-doctor@example.test');
INSERT INTO public.staff(id, user_id, full_name, email, role) VALUES
 ('91000000-0000-0000-0000-000000000001', '90000000-0000-0000-0000-000000000001', 'Test admin', 'empty-admin@example.test', 'super_admin'),
 ('91000000-0000-0000-0000-000000000002', '90000000-0000-0000-0000-000000000002', 'Test doctor', 'empty-doctor@example.test', 'doctor');
SELECT set_config('request.jwt.claim.sub', '90000000-0000-0000-0000-000000000001', true);
DO $$
DECLARE p uuid; category text; author uuid := '91000000-0000-0000-0000-000000000001';
BEGIN
  FOREACH category IN ARRAY ARRAY['appointment','payment','program','history','note','document','balance'] LOOP
    p := gen_random_uuid();
    INSERT INTO public.patients(id, full_name, phone_number, clinic) VALUES (p, 'Nonempty fixture', '000', 'tagamoa');
    CASE category
      WHEN 'appointment' THEN INSERT INTO public.appointments(patient_id,type,use_package) VALUES(p,'initial_assessment',false);
      WHEN 'payment' THEN INSERT INTO public.payment_records(patient_id,amount,reason,recorded_by) VALUES(p,10,'Fixture',author);
      WHEN 'program' THEN INSERT INTO public.patient_programs(patient_id,created_by) VALUES(p,author);
      WHEN 'history' THEN INSERT INTO public.patient_medical_history(patient_id) VALUES(p);
      WHEN 'note' THEN INSERT INTO public.patient_notes(patient_id,created_by,note_text) VALUES(p,author,'Fixture');
      WHEN 'document' THEN INSERT INTO public.patient_documents(patient_id,file_url,file_name) VALUES(p,'private/key','Fixture.jpg');
      WHEN 'balance' THEN UPDATE public.patients SET session_balance=1 WHERE id=p;
    END CASE;
    BEGIN
      PERFORM public.delete_empty_patient(p);
      RAISE EXCEPTION 'Deletion unexpectedly succeeded for %', category;
    EXCEPTION WHEN check_violation THEN NULL;
    END;
    IF NOT EXISTS(SELECT 1 FROM public.patients WHERE id=p) THEN RAISE EXCEPTION 'Patient lost'; END IF;
    BEGIN
      DELETE FROM public.patients WHERE id=p;
      RAISE EXCEPTION 'Direct delete bypassed guard for %', category;
    EXCEPTION WHEN check_violation THEN NULL;
    END;
  END LOOP;
  p := gen_random_uuid();
  INSERT INTO public.patients(id,full_name,phone_number,clinic) VALUES(p,'Empty fixture','000','tagamoa');
  PERFORM public.delete_empty_patient(p);
  IF EXISTS(SELECT 1 FROM public.patients WHERE id=p) THEN RAISE EXCEPTION 'Empty patient was not deleted'; END IF;
  p := gen_random_uuid();
  INSERT INTO public.patients(id,full_name,phone_number,clinic) VALUES(p,'Denied fixture','000','tagamoa');
  PERFORM set_config('request.jwt.claim.sub','90000000-0000-0000-0000-000000000002',true);
  BEGIN
    PERFORM public.delete_empty_patient(p);
    RAISE EXCEPTION 'Junior doctor bypassed permission check';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END;
$$;
ROLLBACK;
