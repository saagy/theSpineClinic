-- Program writes commit with a durable result before tracked file uploads begin.
CREATE FUNCTION public.save_program_mutation(p_request_id uuid, p_payload jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE previous public.mutation_receipts; outcome jsonb; saved jsonb;
  actor uuid := (SELECT staff_id FROM public.get_auth_staff_profile());
  v_patient_id uuid := (p_payload->>'p_patient_id')::uuid;
  v_program_id uuid := (p_payload->>'p_program_id')::uuid;
  v_kind text := CASE WHEN v_program_id IS NULL THEN 'program_create' ELSE 'program_update' END;
  request_hash text := encode(sha256(convert_to(p_payload::text,'UTF8')),'hex');
  error_code text; error_message text;
BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.staff WHERE id=actor AND is_active AND
    (role='super_admin' OR (role='doctor' AND is_senior))) THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE='42501';
  END IF;
  IF p_request_id IS NULL OR v_patient_id IS NULL OR p_payload IS NULL THEN
    RAISE EXCEPTION 'Invalid request' USING ERRCODE='22000';
  END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended(p_request_id::text,0));
  SELECT * INTO previous FROM public.mutation_receipts WHERE request_id=p_request_id;
  IF FOUND THEN
    IF previous.actor_id<>actor OR previous.kind<>v_kind OR previous.payload_hash<>request_hash THEN
      RAISE EXCEPTION 'Request identity mismatch' USING ERRCODE='22000';
    END IF;
    RETURN previous.outcome;
  END IF;
  BEGIN
    IF v_program_id IS NULL THEN
      saved := public.create_patient_program(v_patient_id,
        ARRAY(SELECT value::uuid FROM jsonb_array_elements_text(p_payload->'p_condition_ids')),
        p_payload->>'p_examination',p_payload->>'p_imaging_notes',
        p_payload->>'p_exaggerating_positions',p_payload->>'p_relieving_positions',
        p_payload->>'p_notes',NULL,p_payload->'p_treatment_plan');
      v_program_id := (saved->>'id')::uuid;
    ELSE
      IF NOT EXISTS(SELECT 1 FROM public.patient_programs p
        WHERE p.id=v_program_id AND p.patient_id=v_patient_id) THEN
        RAISE EXCEPTION 'Program not found for patient' USING ERRCODE='P0001';
      END IF;
      saved := public.update_patient_program(v_program_id,
        ARRAY(SELECT value::uuid FROM jsonb_array_elements_text(p_payload->'p_condition_ids')),
        p_payload->>'p_examination',p_payload->>'p_imaging_notes',
        p_payload->>'p_exaggerating_positions',p_payload->>'p_relieving_positions',
        p_payload->>'p_notes',(p_payload->>'p_status')::public.program_status,
        NULL,p_payload->'p_treatment_plan');
    END IF;
    -- Return the complete display model in the same transaction. A later read
    -- failure must never turn a confirmed save into a failed/duplicated write.
    saved := saved || jsonb_build_object(
      'program_conditions',coalesce((SELECT jsonb_agg(to_jsonb(pc) ||
        jsonb_build_object('condition_catalog',to_jsonb(c)))
        FROM public.program_conditions pc JOIN public.condition_catalog c ON c.id=pc.condition_id
        WHERE pc.program_id=v_program_id),'[]'::jsonb),
      'treatment_plans',coalesce((SELECT jsonb_agg(to_jsonb(tp) || jsonb_build_object(
        'plan_modalities',coalesce((SELECT jsonb_agg(to_jsonb(pm) || jsonb_build_object(
          'modality_regions',coalesce((SELECT jsonb_agg(to_jsonb(mr))
            FROM public.modality_regions mr WHERE mr.plan_modality_id=pm.id),'[]'::jsonb)))
          FROM public.plan_modalities pm WHERE pm.treatment_plan_id=tp.id),'[]'::jsonb)))
        FROM public.treatment_plans tp WHERE tp.program_id=v_program_id),'[]'::jsonb));
    outcome := jsonb_build_object('ok',true,'program',saved);
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS error_code=RETURNED_SQLSTATE, error_message=MESSAGE_TEXT;
    outcome := jsonb_build_object('ok',false,'code',error_code,'message',error_message);
  END;
  INSERT INTO public.mutation_receipts(request_id,actor_id,kind,payload_hash,outcome)
    VALUES(p_request_id,actor,v_kind,request_hash,outcome);
  RETURN outcome;
END;
$$;
REVOKE ALL ON FUNCTION public.save_program_mutation(uuid,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.save_program_mutation(uuid,jsonb) TO authenticated;
