-- Run against a disposable migrated database; all fixtures roll back.
-- psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f test/program_document_removal.sql
BEGIN;
CREATE FUNCTION pg_temp.check_removal(ok boolean, message text)
RETURNS void LANGUAGE plpgsql AS $$ BEGIN
  IF ok IS NOT TRUE THEN RAISE EXCEPTION '%', message; END IF;
END $$;

INSERT INTO auth.users(id,email) VALUES
  ('10000000-0000-0000-0000-000000000001','program-removal@example.test');
INSERT INTO public.staff(id,user_id,full_name,email,role,is_active,is_senior) VALUES
  ('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',
   'Program editor','program-removal@example.test','doctor',true,true);
INSERT INTO public.patients(id,full_name,phone_number,clinic) VALUES
  ('30000000-0000-0000-0000-000000000001','Patient A','01000000001','tagamoa'),
  ('30000000-0000-0000-0000-000000000002','Patient B','01000000002','tagamoa');
INSERT INTO public.condition_catalog(id,region,condition_name) VALUES
  ('60000000-0000-0000-0000-000000000001','lumbar_spine','Test condition');
INSERT INTO public.patient_programs(id,patient_id,created_by,notes) VALUES
  ('40000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001',
   '20000000-0000-0000-0000-000000000001','Original'),
  ('40000000-0000-0000-0000-000000000002','30000000-0000-0000-0000-000000000002',
   '20000000-0000-0000-0000-000000000001','Unrelated');
INSERT INTO public.patient_documents(id,patient_id,program_id,file_url,thumbnail_url,file_name) VALUES
  ('50000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001',
   '40000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001/a.jpg',
   '30000000-0000-0000-0000-000000000001/a-thumb.jpg','a.jpg'),
  ('50000000-0000-0000-0000-000000000002','30000000-0000-0000-0000-000000000001',
   '40000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001/b.pdf',NULL,'b.pdf'),
  ('50000000-0000-0000-0000-000000000003','30000000-0000-0000-0000-000000000002',
   '40000000-0000-0000-0000-000000000002','30000000-0000-0000-0000-000000000002/c.pdf',NULL,'c.pdf');

DO $$
DECLARE
  payload jsonb := '{"p_patient_id":"30000000-0000-0000-0000-000000000001",
    "p_program_id":"40000000-0000-0000-0000-000000000001",
    "p_condition_ids":["60000000-0000-0000-0000-000000000001"],"p_notes":"Edited",
    "p_removed_document_ids":["50000000-0000-0000-0000-000000000001"]}';
  outcome jsonb; replay jsonb; changed jsonb;
BEGIN
  PERFORM set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',true);
  outcome := public.save_program_mutation('70000000-0000-0000-0000-000000000001',payload);
  PERFORM pg_temp.check_removal(outcome->>'ok'='true','Save must succeed');
  PERFORM pg_temp.check_removal(NOT EXISTS(SELECT 1 FROM public.patient_documents
    WHERE id='50000000-0000-0000-0000-000000000001'),'Requested document must be deleted');
  PERFORM pg_temp.check_removal((SELECT count(*)=2 FROM public.patient_documents),'Keep other documents');
  PERFORM pg_temp.check_removal((SELECT notes='Edited' FROM public.patient_programs
    WHERE id='40000000-0000-0000-0000-000000000001'),'Commit program fields with removal');
  PERFORM pg_temp.check_removal(jsonb_array_length(outcome->'removed_document_paths')=2,
    'Cleanup receipt must retain original and thumbnail paths');
  replay := public.save_program_mutation('70000000-0000-0000-0000-000000000001',payload);
  PERFORM pg_temp.check_removal(outcome=replay,'Lost response retry must return identical receipt');
  BEGIN
    PERFORM public.save_program_mutation('70000000-0000-0000-0000-000000000001',
      payload || '{"p_removed_document_ids":[]}');
    RAISE EXCEPTION 'Changed removal selection must not reuse receipt';
  EXCEPTION WHEN data_exception THEN NULL; END;

  changed := payload || '{"p_notes":"Must roll back","p_removed_document_ids":[
    "50000000-0000-0000-0000-000000000002","50000000-0000-0000-0000-000000000003"]}';
  outcome := public.save_program_mutation('70000000-0000-0000-0000-000000000002',changed);
  PERFORM pg_temp.check_removal(outcome->>'ok'='false','Reject a document from another program/patient');
  PERFORM pg_temp.check_removal((SELECT notes='Edited' FROM public.patient_programs
    WHERE id='40000000-0000-0000-0000-000000000001'),'Scope rejection must roll back program fields');
  PERFORM pg_temp.check_removal((SELECT count(*)=2 FROM public.patient_documents),'No partial document removal');
  PERFORM pg_temp.check_removal(NOT outcome ? 'removed_document_paths','Failures cannot authorize cleanup');

  changed := payload || '{"p_notes":"Must also roll back",
    "p_condition_ids":["60000000-0000-0000-0000-000000000099"],
    "p_removed_document_ids":["50000000-0000-0000-0000-000000000002"]}';
  outcome := public.save_program_mutation('70000000-0000-0000-0000-000000000003',changed);
  PERFORM pg_temp.check_removal(outcome->>'ok'='false','Invalid condition must reject the save');
  PERFORM pg_temp.check_removal((SELECT count(*)=2 FROM public.patient_documents),'Failed program save keeps documents');
  PERFORM pg_temp.check_removal((SELECT notes='Edited' FROM public.patient_programs
    WHERE id='40000000-0000-0000-0000-000000000001'),'Failed condition update rolls back fields');

  outcome := public.save_program_mutation('70000000-0000-0000-0000-000000000004',payload);
  PERFORM pg_temp.check_removal(outcome->>'ok'='true','Already absent document is harmless');
  PERFORM pg_temp.check_removal(outcome->'removed_document_paths'='[]'::jsonb,'Never invent cleanup paths');
  outcome := public.save_program_mutation('70000000-0000-0000-0000-000000000005',payload-'p_program_id');
  PERFORM pg_temp.check_removal(outcome->>'ok'='false','Creation cannot remove existing documents');

  UPDATE public.staff SET is_senior=false WHERE id='20000000-0000-0000-0000-000000000001';
  BEGIN
    PERFORM public.save_program_mutation('70000000-0000-0000-0000-000000000006',payload);
    RAISE EXCEPTION 'Junior doctor must be denied';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  UPDATE public.staff SET is_senior=true,is_active=false WHERE id='20000000-0000-0000-0000-000000000001';
  BEGIN
    PERFORM public.save_program_mutation('70000000-0000-0000-0000-000000000007',payload);
    RAISE EXCEPTION 'Inactive staff must be denied';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  PERFORM pg_temp.check_removal(NOT has_function_privilege('anon',
    'public.save_program_mutation(uuid,jsonb)','EXECUTE'),'Anonymous callers must be denied');
END $$;
ROLLBACK;
