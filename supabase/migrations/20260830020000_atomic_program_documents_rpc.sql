-- Migration: Enable atomic patient_documents insertion in program creation/update RPCs
DROP FUNCTION IF EXISTS public.create_patient_program(uuid, uuid[], text, text, text, text, text);
DROP FUNCTION IF EXISTS public.create_patient_program(uuid, uuid[], text, text, text, text, text, jsonb);
DROP FUNCTION IF EXISTS public.update_patient_program(uuid, uuid[], text, text, text, text, text, public.program_status);
DROP FUNCTION IF EXISTS public.update_patient_program(uuid, uuid[], text, text, text, text, text, public.program_status, jsonb);

CREATE OR REPLACE FUNCTION public.create_patient_program(
  p_patient_id uuid,
  p_condition_ids uuid[],
  p_examination text DEFAULT NULL,
  p_imaging_notes text DEFAULT NULL,
  p_exaggerating_positions text DEFAULT NULL,
  p_relieving_positions text DEFAULT NULL,
  p_notes text DEFAULT NULL,
  p_documents jsonb DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_caller_staff_id uuid;
  v_caller_role public.user_role;
  v_caller_is_senior boolean;
  v_caller_active boolean;
  v_program_id uuid;
  v_cond_id uuid;
  v_result jsonb;
BEGIN
  SELECT id, role, is_senior, is_active
  INTO v_caller_staff_id, v_caller_role, v_caller_is_senior, v_caller_active
  FROM public.staff
  WHERE user_id = auth.uid();

  IF v_caller_staff_id IS NULL OR v_caller_active IS NOT TRUE THEN
    RAISE EXCEPTION 'Unauthorized: Active staff profile not found.';
  END IF;

  IF v_caller_role != 'super_admin' AND (v_caller_role != 'doctor' OR v_caller_is_senior IS NOT TRUE) THEN
    RAISE EXCEPTION 'Permission denied: Only senior doctors and super admins can create patient programs.';
  END IF;

  INSERT INTO public.patient_programs (
    patient_id,
    created_by,
    status,
    examination,
    imaging_notes,
    exaggerating_positions,
    relieving_positions,
    notes
  ) VALUES (
    p_patient_id,
    v_caller_staff_id,
    'active',
    p_examination,
    p_imaging_notes,
    p_exaggerating_positions,
    p_relieving_positions,
    p_notes
  )
  RETURNING id INTO v_program_id;

  IF p_condition_ids IS NOT NULL AND array_length(p_condition_ids, 1) > 0 THEN
    FOREACH v_cond_id IN ARRAY p_condition_ids LOOP
      INSERT INTO public.program_conditions (program_id, condition_id)
      VALUES (v_program_id, v_cond_id)
      ON CONFLICT (program_id, condition_id) DO NOTHING;
    END LOOP;
  END IF;

  IF p_documents IS NOT NULL AND jsonb_array_length(p_documents) > 0 THEN
    INSERT INTO public.patient_documents (patient_id, program_id, file_url, file_name, uploaded_by)
    SELECT
      p_patient_id,
      v_program_id,
      doc->>'file_url',
      doc->>'file_name',
      v_caller_staff_id
    FROM jsonb_array_elements(p_documents) AS doc;
  END IF;

  SELECT jsonb_build_object(
    'id', p.id,
    'patient_id', p.patient_id,
    'created_by', p.created_by,
    'status', p.status,
    'examination', p.examination,
    'imaging_notes', p.imaging_notes,
    'exaggerating_positions', p.exaggerating_positions,
    'relieving_positions', p.relieving_positions,
    'notes', p.notes,
    'created_at', p.created_at,
    'updated_at', p.updated_at
  ) INTO v_result
  FROM public.patient_programs p
  WHERE p.id = v_program_id;

  RETURN v_result;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_patient_program(
  p_program_id uuid,
  p_condition_ids uuid[],
  p_examination text DEFAULT NULL,
  p_imaging_notes text DEFAULT NULL,
  p_exaggerating_positions text DEFAULT NULL,
  p_relieving_positions text DEFAULT NULL,
  p_notes text DEFAULT NULL,
  p_status public.program_status DEFAULT NULL,
  p_documents jsonb DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_caller_staff_id uuid;
  v_caller_role public.user_role;
  v_caller_is_senior boolean;
  v_caller_active boolean;
  v_program public.patient_programs%ROWTYPE;
  v_cond_id uuid;
  v_result jsonb;
BEGIN
  SELECT id, role, is_senior, is_active
  INTO v_caller_staff_id, v_caller_role, v_caller_is_senior, v_caller_active
  FROM public.staff
  WHERE user_id = auth.uid();

  IF v_caller_staff_id IS NULL OR v_caller_active IS NOT TRUE THEN
    RAISE EXCEPTION 'Unauthorized: Active staff profile not found.';
  END IF;

  IF v_caller_role != 'super_admin' AND (v_caller_role != 'doctor' OR v_caller_is_senior IS NOT TRUE) THEN
    RAISE EXCEPTION 'Permission denied: Only senior doctors and super admins can update patient programs.';
  END IF;

  SELECT * INTO v_program FROM public.patient_programs WHERE id = p_program_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Program not found.';
  END IF;

  UPDATE public.patient_programs
  SET
    examination = COALESCE(p_examination, examination),
    imaging_notes = COALESCE(p_imaging_notes, imaging_notes),
    exaggerating_positions = COALESCE(p_exaggerating_positions, exaggerating_positions),
    relieving_positions = COALESCE(p_relieving_positions, relieving_positions),
    notes = COALESCE(p_notes, notes),
    status = COALESCE(p_status, status),
    updated_at = now()
  WHERE id = p_program_id;

  IF p_condition_ids IS NOT NULL THEN
    DELETE FROM public.program_conditions WHERE program_id = p_program_id;
    IF array_length(p_condition_ids, 1) > 0 THEN
      FOREACH v_cond_id IN ARRAY p_condition_ids LOOP
        INSERT INTO public.program_conditions (program_id, condition_id)
        VALUES (p_program_id, v_cond_id)
        ON CONFLICT (program_id, condition_id) DO NOTHING;
      END LOOP;
    END IF;
  END IF;

  IF p_documents IS NOT NULL AND jsonb_array_length(p_documents) > 0 THEN
    INSERT INTO public.patient_documents (patient_id, program_id, file_url, file_name, uploaded_by)
    SELECT
      v_program.patient_id,
      p_program_id,
      doc->>'file_url',
      doc->>'file_name',
      v_caller_staff_id
    FROM jsonb_array_elements(p_documents) AS doc;
  END IF;

  SELECT jsonb_build_object(
    'id', p.id,
    'patient_id', p.patient_id,
    'created_by', p.created_by,
    'status', p.status,
    'examination', p.examination,
    'imaging_notes', p.imaging_notes,
    'exaggerating_positions', p.exaggerating_positions,
    'relieving_positions', p.relieving_positions,
    'notes', p.notes,
    'created_at', p.created_at,
    'updated_at', p.updated_at
  ) INTO v_result
  FROM public.patient_programs p
  WHERE p.id = p_program_id;

  RETURN v_result;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.create_patient_program TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_patient_program TO authenticated;
