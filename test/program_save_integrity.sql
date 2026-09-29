BEGIN;
DO $$
DECLARE u uuid:=gen_random_uuid(); actor uuid:=gen_random_uuid(); patient uuid:=gen_random_uuid();
  condition uuid; request uuid:=gen_random_uuid(); payload jsonb; first_result jsonb;
  result_json jsonb; program uuid; n integer;
BEGIN
  INSERT INTO auth.users(id,email) VALUES(u,u::text||'@example.test');
  INSERT INTO public.staff(id,user_id,full_name,email,role,is_senior)
    VALUES(actor,u,'Test senior',u::text||'@example.test','doctor',true);
  INSERT INTO public.patients(id,full_name,phone_number,clinic) VALUES(patient,'Test patient','000','tagamoa');
  SELECT id INTO condition FROM public.condition_catalog LIMIT 1;
  PERFORM set_config('request.jwt.claim.sub',u::text,true);
  payload:=jsonb_build_object('p_patient_id',patient,'p_condition_ids',jsonb_build_array(condition),
    'p_examination','Test findings','p_treatment_plan',jsonb_build_object('notes','Test plan'));
  first_result:=public.save_program_mutation(request,payload);
  IF first_result->>'ok'<>'true' THEN RAISE EXCEPTION 'Save failed: %',first_result; END IF;
  program:=(first_result->'program'->>'id')::uuid;
  IF first_result#>>'{program,program_conditions,0,condition_catalog,id}'<>condition::text
    OR jsonb_array_length(first_result#>'{program,treatment_plans}')<>1 THEN
    RAISE EXCEPTION 'Incomplete program response'; END IF;
  IF public.save_program_mutation(request,payload)<>first_result THEN RAISE EXCEPTION 'Replay changed'; END IF;
  SELECT count(*) INTO n FROM public.patient_programs WHERE patient_id=patient;
  IF n<>1 THEN RAISE EXCEPTION 'Duplicate program'; END IF;
  BEGIN
    PERFORM public.save_program_mutation(request,payload||'{"p_notes":"changed"}');
    RAISE EXCEPTION 'Changed retry accepted';
  EXCEPTION WHEN data_exception THEN NULL; END;
  request:=gen_random_uuid();
  PERFORM public.resolve_clinic_mutation(request);
  BEGIN
    PERFORM public.save_program_mutation(request,payload);
    RAISE EXCEPTION 'Cancelled request accepted';
  EXCEPTION WHEN data_exception THEN NULL; END;
  request:=gen_random_uuid();
  payload:=payload||jsonb_build_object('p_program_id',program,'p_notes','Updated');
  first_result:=public.save_program_mutation(request,payload);
  IF first_result->>'ok'<>'true' OR first_result#>>'{program,notes}'<>'Updated' THEN
    RAISE EXCEPTION 'Update failed: %',first_result; END IF;
  IF public.save_program_mutation(request,payload)<>first_result THEN RAISE EXCEPTION 'Update replay changed'; END IF;
  result_json:=public.save_program_mutation(gen_random_uuid(),payload||jsonb_build_object('p_patient_id',gen_random_uuid()));
  IF result_json->>'ok'<>'false' THEN RAISE EXCEPTION 'Wrong patient accepted'; END IF;
  -- A failed transaction must roll back the program and retain its failure receipt.
  request:=gen_random_uuid();
  payload:=jsonb_build_object('p_patient_id',patient,'p_condition_ids',jsonb_build_array(gen_random_uuid()));
  first_result:=public.save_program_mutation(request,payload);
  IF first_result->>'ok'<>'false' THEN RAISE EXCEPTION 'Invalid condition accepted'; END IF;
  IF public.save_program_mutation(request,payload)<>first_result THEN RAISE EXCEPTION 'Failure replay changed'; END IF;
  SELECT count(*) INTO n FROM public.patient_programs WHERE patient_id=patient;
  IF n<>1 THEN RAISE EXCEPTION 'Failed save left program'; END IF;
  PERFORM set_config('request.jwt.claim.sub','',true);
  UPDATE public.staff SET is_senior=false WHERE id=actor;
  PERFORM set_config('request.jwt.claim.sub',u::text,true);
  BEGIN
    PERFORM public.save_program_mutation(request,payload);
    RAISE EXCEPTION 'Junior doctor replay accepted';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  PERFORM set_config('request.jwt.claim.sub','',true);
  UPDATE public.staff SET is_senior=true,is_active=false WHERE id=actor;
  PERFORM set_config('request.jwt.claim.sub',u::text,true);
  BEGIN
    PERFORM public.save_program_mutation(request,payload);
    RAISE EXCEPTION 'Inactive doctor accepted';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
ROLLBACK;
