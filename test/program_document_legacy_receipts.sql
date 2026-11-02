-- Regression: an older server saved program edits but ignored removal IDs.
-- Fixtures and simulated legacy receipts stay in a disposable database.
BEGIN;
CREATE FUNCTION pg_temp.check_legacy_removal(ok boolean, message text)
RETURNS void LANGUAGE plpgsql AS $$ BEGIN
  IF ok IS NOT TRUE THEN RAISE EXCEPTION '%', message; END IF;
END $$;
DO $$
DECLARE
  login uuid := gen_random_uuid(); actor uuid := gen_random_uuid();
  patient uuid := gen_random_uuid(); program uuid := gen_random_uuid();
  other_program uuid := gen_random_uuid(); document uuid := gen_random_uuid();
  foreign_document uuid := gen_random_uuid(); condition uuid := gen_random_uuid();
  old_condition uuid := gen_random_uuid(); request uuid := gen_random_uuid();
  invalid_request uuid := gen_random_uuid(); unchanged_request uuid := gen_random_uuid();
  payload jsonb; invalid_payload jsonb; unchanged_payload jsonb;
  legacy jsonb; result_json jsonb; replay jsonb;
BEGIN
  INSERT INTO auth.users(id,email) VALUES(login,login::text||'@example.test');
  INSERT INTO public.staff(id,user_id,full_name,email,role,is_senior)
    VALUES(actor,login,'Test senior',login::text||'@example.test','doctor',true);
  INSERT INTO public.patients(id,full_name,phone_number,clinic)
    VALUES(patient,'Test patient','000','tagamoa');
  INSERT INTO public.condition_catalog(id,region,condition_name) VALUES
    (condition,'knee_joint',condition::text),(old_condition,'knee_joint',old_condition::text);
  INSERT INTO public.patient_programs(id,patient_id,created_by,notes) VALUES
    (program,patient,actor,'Newer clinical edits'),(other_program,patient,actor,'Other program');
  INSERT INTO public.program_conditions(program_id,condition_id) VALUES(program,condition);
  INSERT INTO public.treatment_plans(program_id,created_by,notes)
    VALUES(program,actor,'Current plan');
  INSERT INTO public.patient_documents(id,patient_id,program_id,file_url,thumbnail_url,file_name) VALUES
    (document,patient,program,patient::text||'/scan.jpg',patient::text||'/thumb.jpg','scan.jpg'),
    (foreign_document,patient,other_program,patient::text||'/other.pdf',NULL,'other.pdf');

  payload := jsonb_build_object('p_patient_id',patient,'p_program_id',program,
    'p_condition_ids',jsonb_build_array(old_condition),'p_notes','Earlier saved edits',
    'p_treatment_plan',jsonb_build_object('notes','Earlier plan'),
    'p_removed_document_ids',jsonb_build_array(document));
  SELECT jsonb_build_object('ok',true,'program',to_jsonb(p)||'{"notes":"Earlier saved edits"}')
    INTO legacy FROM public.patient_programs p WHERE id=program;
  invalid_payload := payload||jsonb_build_object('p_removed_document_ids',
    jsonb_build_array(document,foreign_document));
  unchanged_payload := payload-'p_removed_document_ids';
  INSERT INTO public.mutation_receipts(request_id,actor_id,kind,payload_hash,outcome) VALUES
    (request,actor,'program_update',encode(sha256(convert_to(payload::text,'UTF8')),'hex'),legacy),
    (invalid_request,actor,'program_update',
      encode(sha256(convert_to(invalid_payload::text,'UTF8')),'hex'),legacy),
    (unchanged_request,actor,'program_update',
      encode(sha256(convert_to(unchanged_payload::text,'UTF8')),'hex'),legacy);
  PERFORM set_config('request.jwt.claim.sub',login::text,true);

  replay := public.save_program_mutation(unchanged_request,unchanged_payload);
  PERFORM pg_temp.check_legacy_removal(replay=legacy,'Ordinary legacy receipts stay unchanged');
  BEGIN
    PERFORM public.save_program_mutation(request,payload||'{"p_notes":"Changed retry"}');
    RAISE EXCEPTION 'Changed payload reused a legacy receipt';
  EXCEPTION WHEN data_exception THEN NULL; END;
  PERFORM set_config('request.jwt.claim.sub','',true);
  UPDATE public.staff SET is_senior=false WHERE id=actor;
  PERFORM set_config('request.jwt.claim.sub',login::text,true);
  BEGIN
    PERFORM public.save_program_mutation(request,payload);
    RAISE EXCEPTION 'Junior doctor recovered a legacy removal';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  PERFORM set_config('request.jwt.claim.sub','',true);
  UPDATE public.staff SET is_senior=true,is_active=false WHERE id=actor;
  PERFORM set_config('request.jwt.claim.sub',login::text,true);
  BEGIN
    PERFORM public.save_program_mutation(request,payload);
    RAISE EXCEPTION 'Inactive doctor recovered a legacy removal';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  PERFORM set_config('request.jwt.claim.sub','',true);
  UPDATE public.staff SET is_active=true WHERE id=actor;
  PERFORM set_config('request.jwt.claim.sub',login::text,true);

  result_json := public.save_program_mutation(invalid_request,invalid_payload);
  PERFORM pg_temp.check_legacy_removal(result_json->>'ok'='false' AND result_json->>'code'='42501',
    'Legacy recovery must reject documents from another program');
  PERFORM pg_temp.check_legacy_removal((SELECT count(*)=2 FROM public.patient_documents
    WHERE id IN (document,foreign_document)),'Rejected recovery cannot partially delete');
  PERFORM pg_temp.check_legacy_removal((SELECT r.outcome=legacy FROM public.mutation_receipts r
    WHERE request_id=invalid_request),'Rejected recovery retains the original save receipt');
  UPDATE public.mutation_receipts SET outcome='{"ok":false,"code":"23503"}'
    WHERE request_id=invalid_request;
  replay := public.save_program_mutation(invalid_request,invalid_payload);
  PERFORM pg_temp.check_legacy_removal(replay='{"ok":false,"code":"23503"}'::jsonb,
    'Definitive legacy failures must never execute removal');

  result_json := public.save_program_mutation(request,payload);
  PERFORM pg_temp.check_legacy_removal(result_json->>'ok'='true' AND
    result_json->'removed_document_ids'=jsonb_build_array(document),
    'Retry must finish and acknowledge the legacy removal');
  PERFORM pg_temp.check_legacy_removal(NOT EXISTS(SELECT 1 FROM public.patient_documents
    WHERE id=document),'Retry must actually delete the document');
  PERFORM pg_temp.check_legacy_removal(EXISTS(SELECT 1 FROM public.patient_documents
    WHERE id=foreign_document),'Keep unrelated documents');
  PERFORM pg_temp.check_legacy_removal(jsonb_array_length(result_json->'removed_document_paths')=2,
    'Recovered receipt must authorize original and thumbnail cleanup');
  PERFORM pg_temp.check_legacy_removal((SELECT notes='Newer clinical edits'
    FROM public.patient_programs WHERE id=program),'Never reapply older clinical edits');
  PERFORM pg_temp.check_legacy_removal((SELECT count(*)=1 AND bool_and(condition_id=condition)
    FROM public.program_conditions WHERE program_id=program),'Keep newer conditions');
  PERFORM pg_temp.check_legacy_removal((SELECT count(*)=1 AND bool_and(notes='Current plan')
    FROM public.treatment_plans WHERE program_id=program),'Never duplicate or replace plans');
  PERFORM pg_temp.check_legacy_removal(result_json#>>'{program,notes}'='Newer clinical edits' AND
    result_json#>>'{program,program_conditions,0,condition_catalog,id}'=condition::text AND
    jsonb_array_length(result_json#>'{program,treatment_plans}')=1,'Return the current complete program');
  replay := public.save_program_mutation(request,payload);
  PERFORM pg_temp.check_legacy_removal(replay=result_json,'Recovery itself must be safely replayable');
  PERFORM pg_temp.check_legacy_removal((SELECT r.outcome=result_json FROM public.mutation_receipts r
    WHERE request_id=request),'Persist the recovered receipt under the same request identity');
END $$;
ROLLBACK;
