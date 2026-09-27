CREATE TABLE public.document_uploads (
  request_id uuid PRIMARY KEY,
  actor_id uuid NOT NULL,
  patient_id uuid NOT NULL,
  file_name text NOT NULL,
  program_id uuid,
  content_hash text NOT NULL,
  byte_size integer NOT NULL CHECK(byte_size BETWEEN 1 AND 10485760),
  object_key text NOT NULL UNIQUE,
  status text NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','completed','failed')),
  outcome jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.document_uploads ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.document_uploads TO authenticated;
-- No client write policies. Receipts survive deleted documents to fence late retries.

CREATE FUNCTION public.begin_document_upload(p_request_id uuid, p_patient_id uuid,
  p_file_name text, p_program_id uuid, p_content_hash text, p_byte_size integer)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE upload public.document_uploads;
  actor uuid := (SELECT staff_id FROM public.get_auth_staff_profile());
BEGIN
  IF actor IS NULL OR NOT public.can_current_staff_access_patient(p_patient_id)
      OR NOT EXISTS(SELECT 1 FROM public.staff WHERE id=actor AND is_active) THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE='42501';
  END IF;
  IF p_request_id IS NULL OR p_file_name IS NULL OR length(trim(p_file_name)) NOT BETWEEN 1 AND 255
      OR p_content_hash IS NULL OR p_content_hash !~ '^[a-f0-9]{64}$'
      OR p_byte_size IS NULL OR p_byte_size NOT BETWEEN 1 AND 10485760 THEN
    RAISE EXCEPTION 'Invalid document' USING ERRCODE='22000';
  END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended(p_request_id::text,1));
  SELECT * INTO upload FROM public.document_uploads WHERE request_id=p_request_id;
  IF FOUND THEN
    IF upload.actor_id<>actor OR upload.patient_id<>p_patient_id OR upload.file_name<>p_file_name
      OR upload.program_id IS DISTINCT FROM p_program_id OR upload.content_hash<>p_content_hash
      OR upload.byte_size<>p_byte_size THEN
      RAISE EXCEPTION 'Upload identity mismatch' USING ERRCODE='22000';
    END IF;
    RETURN to_jsonb(upload);
  END IF;
  IF NOT EXISTS(SELECT 1 FROM public.patients WHERE id=p_patient_id) OR
      (p_program_id IS NOT NULL AND NOT EXISTS(
        SELECT 1 FROM public.patient_programs WHERE id=p_program_id AND patient_id=p_patient_id)) THEN
    RAISE EXCEPTION 'Patient or program not found' USING ERRCODE='23503';
  END IF;
  INSERT INTO public.document_uploads(request_id,actor_id,patient_id,file_name,program_id,
    content_hash,byte_size,object_key)
  VALUES(p_request_id,actor,p_patient_id,p_file_name,p_program_id,p_content_hash,p_byte_size,
    p_patient_id::text||'/'||p_request_id::text) RETURNING * INTO upload;
  RETURN to_jsonb(upload);
END;
$$;

CREATE FUNCTION public.complete_document_upload(p_request_id uuid) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE upload public.document_uploads; document public.patient_documents; result_json jsonb;
  actor uuid := (SELECT staff_id FROM public.get_auth_staff_profile());
BEGIN
  SELECT * INTO upload FROM public.document_uploads WHERE request_id=p_request_id FOR UPDATE;
  IF NOT FOUND OR actor IS NULL OR upload.actor_id<>actor
      OR NOT public.can_current_staff_access_patient(upload.patient_id)
      OR NOT EXISTS(SELECT 1 FROM public.staff WHERE id=actor AND is_active) THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE='42501';
  END IF;
  IF upload.status<>'pending' THEN RETURN upload.outcome; END IF;
  BEGIN
    IF upload.program_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.patient_programs
        WHERE id=upload.program_id AND patient_id=upload.patient_id) THEN
      RAISE EXCEPTION 'Program no longer exists' USING ERRCODE='23503';
    END IF;
    INSERT INTO public.patient_documents(id,patient_id,file_url,file_name,uploaded_by,program_id)
    VALUES(upload.request_id,upload.patient_id,upload.object_key,upload.file_name,actor,upload.program_id)
    RETURNING * INTO document;
    result_json := jsonb_build_object('ok',true,'document',to_jsonb(document));
    UPDATE public.document_uploads SET status='completed',outcome=result_json WHERE request_id=p_request_id;
  EXCEPTION WHEN OTHERS THEN
    result_json := jsonb_build_object('ok',false);
    UPDATE public.document_uploads SET status='failed',outcome=result_json WHERE request_id=p_request_id;
  END;
  RETURN result_json;
END;
$$;
REVOKE ALL ON FUNCTION public.begin_document_upload(uuid,uuid,text,uuid,text,integer),
  public.complete_document_upload(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.begin_document_upload(uuid,uuid,text,uuid,text,integer),
  public.complete_document_upload(uuid) TO authenticated;
