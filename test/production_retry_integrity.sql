BEGIN;
DO $$
DECLARE u uuid:=gen_random_uuid(); admin uuid:=gen_random_uuid(); d uuid:=gen_random_uuid();
  p uuid:=gen_random_uuid(); req uuid:=gen_random_uuid(); payload jsonb; first_result jsonb;
  result_json jsonb; n integer; upload_id uuid:=gen_random_uuid(); missing uuid:=gen_random_uuid();
BEGIN
  INSERT INTO auth.users(id,email) VALUES(u,u::text||'@example.test');
  INSERT INTO public.staff(id,user_id,full_name,email,role)
    VALUES(admin,u,'Test admin',u::text||'@example.test','super_admin');
  INSERT INTO public.staff(id,full_name,email,role) VALUES(d,'Test doctor',d::text||'@example.test','doctor');
  INSERT INTO public.patients(id,full_name,phone_number,clinic,session_balance)
    VALUES(p,'Test patient','000','tagamoa',5);
  PERFORM set_config('request.jwt.claim.sub',u::text,true);
  -- Legacy payment kinds were removed with payment_records; only bookings remain.
  BEGIN
    PERFORM public.execute_clinic_mutation(req,'payment','{}');
    RAISE EXCEPTION 'Removed payment command accepted';
  EXCEPTION WHEN data_exception THEN NULL; END;
  payload := jsonb_build_object('p_patient_id',p,'p_type','normal_pt_session','p_use_package',true,
    'p_slots',jsonb_build_array(now()+interval '1 day',now()+interval '2 days'),'p_doctor_ids',jsonb_build_array(d));
  first_result := public.execute_clinic_mutation(req,'booking',payload);
  IF first_result->>'ok'<>'true' THEN RAISE EXCEPTION 'Booking failed: %',first_result; END IF;
  PERFORM public.execute_clinic_mutation(req,'booking',payload);
  SELECT count(*) INTO n FROM public.appointments WHERE patient_id=p;
  IF n<>2 THEN RAISE EXCEPTION 'Duplicate appointments'; END IF;
  SELECT count(*) INTO n FROM public.appointment_doctors WHERE appointment_id IN
    (SELECT id FROM public.appointments WHERE patient_id=p);
  IF n<>2 THEN RAISE EXCEPTION 'Duplicate assignments'; END IF;
  IF NOT public.resolve_clinic_mutation(req) THEN RAISE EXCEPTION 'Completed receipt missing'; END IF;
  req := gen_random_uuid();
  IF public.resolve_clinic_mutation(req) THEN RAISE EXCEPTION 'Absent request reported completed'; END IF;
  BEGIN
    PERFORM public.execute_clinic_mutation(req,'booking',payload);
    RAISE EXCEPTION 'Late cancelled request wrote data';
  EXCEPTION WHEN data_exception THEN NULL; END;

  first_result := public.begin_document_upload(upload_id,p,'scan.png',NULL,repeat('a',64),100);
  IF public.begin_document_upload(upload_id,p,'scan.png',NULL,repeat('a',64),100)<>first_result THEN
    RAISE EXCEPTION 'Upload retry changed key'; END IF;
  BEGIN
    PERFORM public.begin_document_upload(upload_id,p,'scan.png',NULL,repeat('b',64),100);
    RAISE EXCEPTION 'Different bytes accepted for upload retry';
  EXCEPTION WHEN data_exception THEN NULL; END;
  first_result := public.complete_document_upload(upload_id);
  IF first_result->>'ok'<>'true' THEN RAISE EXCEPTION 'Upload failed: %',first_result; END IF;
  IF public.complete_document_upload(upload_id)<>first_result THEN RAISE EXCEPTION 'Duplicate finalize'; END IF;
  SELECT count(*) INTO n FROM public.patient_documents WHERE patient_id=p;
  IF n<>1 THEN RAISE EXCEPTION 'Duplicate document'; END IF;
  DELETE FROM public.patient_documents WHERE id=upload_id;
  PERFORM public.complete_document_upload(upload_id);
  IF EXISTS(SELECT 1 FROM public.patient_documents WHERE id=upload_id) THEN RAISE EXCEPTION 'Retry resurrected deleted document'; END IF;
  -- A definite insert failure is retained and cannot later finalize after cleanup.
  upload_id:=gen_random_uuid();
  PERFORM public.begin_document_upload(upload_id,p,'scan.png',NULL,repeat('a',64),100);
  UPDATE public.document_uploads SET program_id=missing WHERE request_id=upload_id;
  result_json := public.complete_document_upload(upload_id);
  IF result_json->>'ok'<>'false' THEN RAISE EXCEPTION 'Missing program accepted'; END IF;
  UPDATE public.document_uploads SET program_id=NULL WHERE request_id=upload_id;
  IF public.complete_document_upload(upload_id)<>result_json THEN RAISE EXCEPTION 'Failed upload finalized after cleanup'; END IF;
  -- A bundled assessment and treatment commit together and replay together.
  req := gen_random_uuid();
  payload := jsonb_build_object('p_patient_id',p,'p_type','normal_pt_session','p_use_package',false,
    'p_slots',jsonb_build_array(now()+interval '4 days'),'p_doctor_ids',jsonb_build_array(d),
    'companion',jsonb_build_object('type','initial_assessment','slots',jsonb_build_array(now()+interval '4 days'),
      'doctor_ids',jsonb_build_array(d)));
  first_result := public.execute_clinic_mutation(req,'booking',payload);
  IF first_result->>'ok'<>'true' THEN RAISE EXCEPTION 'Bundle failed: %',first_result; END IF;
  PERFORM public.execute_clinic_mutation(req,'booking',payload);
  SELECT count(*) INTO n FROM public.appointments WHERE patient_id=p;
  IF n<>4 THEN RAISE EXCEPTION 'Bundle replay duplicated appointments'; END IF;
  payload := jsonb_set(payload,'{companion,doctor_ids}','[]');
  first_result := public.execute_clinic_mutation(gen_random_uuid(),'booking',payload);
  IF first_result->>'ok'<>'false' THEN RAISE EXCEPTION 'Invalid companion accepted'; END IF;
  SELECT count(*) INTO n FROM public.appointments WHERE patient_id=p;
  IF n<>4 THEN RAISE EXCEPTION 'Failed companion left primary booking'; END IF;
  -- Revoked staff cannot read or replay even their own receipts.
  UPDATE public.staff SET is_active=false WHERE id=admin;
  BEGIN
    PERFORM public.complete_document_upload(upload_id);
    RAISE EXCEPTION 'Inactive staff accepted';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END;
$$;
SET LOCAL ROLE authenticated;
DO $$ BEGIN
  IF EXISTS(SELECT 1 FROM public.mutation_receipts) OR EXISTS(SELECT 1 FROM public.document_uploads) THEN
    RAISE EXCEPTION 'Receipt data exposed to clients'; END IF;
  BEGIN
    INSERT INTO public.mutation_receipts VALUES(gen_random_uuid(),gen_random_uuid(),'payment','{}','{}',now());
    RAISE EXCEPTION 'Client forged a receipt';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
ROLLBACK;
