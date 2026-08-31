-- Migration: 20260831030000_atomic_program_treatment_plan.sql
-- Description: Enable atomic treatment plan creation and updates within create_patient_program and update_patient_program RPCs.

DROP FUNCTION IF EXISTS public.create_patient_program(uuid, uuid[], text, text, text, text, text, jsonb);
DROP FUNCTION IF EXISTS public.create_patient_program(uuid, uuid[], text, text, text, text, text, jsonb, jsonb);
DROP FUNCTION IF EXISTS public.update_patient_program(uuid, uuid[], text, text, text, text, text, public.program_status, jsonb);
DROP FUNCTION IF EXISTS public.update_patient_program(uuid, uuid[], text, text, text, text, text, public.program_status, jsonb, jsonb);

CREATE OR REPLACE FUNCTION public.create_patient_program(
  p_patient_id uuid,
  p_condition_ids uuid[],
  p_examination text DEFAULT NULL,
  p_imaging_notes text DEFAULT NULL,
  p_exaggerating_positions text DEFAULT NULL,
  p_relieving_positions text DEFAULT NULL,
  p_notes text DEFAULT NULL,
  p_documents jsonb DEFAULT NULL,
  p_treatment_plan jsonb DEFAULT NULL
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
  v_plan_id uuid;
  v_modality_elem jsonb;
  v_modality_id uuid;
  v_region_elem jsonb;
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

  IF p_treatment_plan IS NOT NULL AND p_treatment_plan != 'null'::jsonb THEN
    IF (p_treatment_plan->'modalities' IS NOT NULL AND jsonb_array_length(p_treatment_plan->'modalities') > 0)
       OR (p_treatment_plan->>'notes' IS NOT NULL AND p_treatment_plan->>'notes' != '') THEN
      INSERT INTO public.treatment_plans (
        program_id,
        created_by,
        plan_name,
        is_active,
        notes
      ) VALUES (
        v_program_id,
        v_caller_staff_id,
        COALESCE(NULLIF(p_treatment_plan->>'plan_name', ''), 'Plan 1'),
        COALESCE((p_treatment_plan->>'is_active')::boolean, true),
        p_treatment_plan->>'notes'
      )
      RETURNING id INTO v_plan_id;

      IF p_treatment_plan->'modalities' IS NOT NULL AND jsonb_array_length(p_treatment_plan->'modalities') > 0 THEN
        FOR v_modality_elem IN SELECT * FROM jsonb_array_elements(p_treatment_plan->'modalities') LOOP
          INSERT INTO public.plan_modalities (
            treatment_plan_id,
            modality_type,
            notes
          ) VALUES (
            v_plan_id,
            (v_modality_elem->>'modality_type')::public.modality_type,
            v_modality_elem->>'notes'
          )
          RETURNING id INTO v_modality_id;

          IF v_modality_elem->'regions' IS NOT NULL AND jsonb_array_length(v_modality_elem->'regions') > 0 THEN
            FOR v_region_elem IN SELECT * FROM jsonb_array_elements(v_modality_elem->'regions') LOOP
              INSERT INTO public.modality_regions (
                plan_modality_id,
                target_region,
                laterality,
                time_minutes
              ) VALUES (
                v_modality_id,
                v_region_elem->>'target_region',
                CASE
                  WHEN v_region_elem->>'laterality' IS NOT NULL AND v_region_elem->>'laterality' != ''
                  THEN (v_region_elem->>'laterality')::public.laterality
                  ELSE NULL
                END,
                COALESCE((v_region_elem->>'time_minutes')::integer, 15)
              );
            END LOOP;
          END IF;
        END LOOP;
      END IF;
    END IF;
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
  p_documents jsonb DEFAULT NULL,
  p_treatment_plan jsonb DEFAULT NULL
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
  v_plan_id uuid;
  v_modality_elem jsonb;
  v_modality_id uuid;
  v_region_elem jsonb;
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

  IF p_treatment_plan IS NOT NULL AND p_treatment_plan != 'null'::jsonb THEN
    IF p_treatment_plan->>'id' IS NOT NULL AND (p_treatment_plan->>'id')::text != '' THEN
      v_plan_id := (p_treatment_plan->>'id')::uuid;

      UPDATE public.treatment_plans
      SET
        plan_name = COALESCE(NULLIF(p_treatment_plan->>'plan_name', ''), plan_name),
        is_active = COALESCE((p_treatment_plan->>'is_active')::boolean, is_active),
        notes = p_treatment_plan->>'notes',
        updated_at = now()
      WHERE id = v_plan_id AND program_id = p_program_id;

      IF COALESCE((p_treatment_plan->>'is_active')::boolean, false) IS TRUE THEN
        UPDATE public.treatment_plans
        SET is_active = false, updated_at = now()
        WHERE program_id = p_program_id AND is_active = true AND id != v_plan_id;
      END IF;

      IF p_treatment_plan->'modalities' IS NOT NULL THEN
        DELETE FROM public.plan_modalities WHERE treatment_plan_id = v_plan_id;

        IF jsonb_array_length(p_treatment_plan->'modalities') > 0 THEN
          FOR v_modality_elem IN SELECT * FROM jsonb_array_elements(p_treatment_plan->'modalities') LOOP
            INSERT INTO public.plan_modalities (
              treatment_plan_id,
              modality_type,
              notes
            ) VALUES (
              v_plan_id,
              (v_modality_elem->>'modality_type')::public.modality_type,
              v_modality_elem->>'notes'
            )
            RETURNING id INTO v_modality_id;

            IF v_modality_elem->'regions' IS NOT NULL AND jsonb_array_length(v_modality_elem->'regions') > 0 THEN
              FOR v_region_elem IN SELECT * FROM jsonb_array_elements(v_modality_elem->'regions') LOOP
                INSERT INTO public.modality_regions (
                  plan_modality_id,
                  target_region,
                  laterality,
                  time_minutes
                ) VALUES (
                  v_modality_id,
                  v_region_elem->>'target_region',
                  CASE
                    WHEN v_region_elem->>'laterality' IS NOT NULL AND v_region_elem->>'laterality' != ''
                    THEN (v_region_elem->>'laterality')::public.laterality
                    ELSE NULL
                  END,
                  COALESCE((v_region_elem->>'time_minutes')::integer, 15)
                );
              END LOOP;
            END IF;
          END LOOP;
        END IF;
      END IF;
    ELSE
      IF (p_treatment_plan->'modalities' IS NOT NULL AND jsonb_array_length(p_treatment_plan->'modalities') > 0)
         OR (p_treatment_plan->>'notes' IS NOT NULL AND p_treatment_plan->>'notes' != '') THEN

        IF COALESCE((p_treatment_plan->>'is_active')::boolean, true) IS TRUE THEN
          UPDATE public.treatment_plans
          SET is_active = false, updated_at = now()
          WHERE program_id = p_program_id AND is_active = true;
        END IF;

        INSERT INTO public.treatment_plans (
          program_id,
          created_by,
          plan_name,
          is_active,
          notes
        ) VALUES (
          p_program_id,
          v_caller_staff_id,
          COALESCE(NULLIF(p_treatment_plan->>'plan_name', ''), 'Plan 1'),
          COALESCE((p_treatment_plan->>'is_active')::boolean, true),
          p_treatment_plan->>'notes'
        )
        RETURNING id INTO v_plan_id;

        IF p_treatment_plan->'modalities' IS NOT NULL AND jsonb_array_length(p_treatment_plan->'modalities') > 0 THEN
          FOR v_modality_elem IN SELECT * FROM jsonb_array_elements(p_treatment_plan->'modalities') LOOP
            INSERT INTO public.plan_modalities (
              treatment_plan_id,
              modality_type,
              notes
            ) VALUES (
              v_plan_id,
              (v_modality_elem->>'modality_type')::public.modality_type,
              v_modality_elem->>'notes'
            )
            RETURNING id INTO v_modality_id;

            IF v_modality_elem->'regions' IS NOT NULL AND jsonb_array_length(v_modality_elem->'regions') > 0 THEN
              FOR v_region_elem IN SELECT * FROM jsonb_array_elements(v_modality_elem->'regions') LOOP
                INSERT INTO public.modality_regions (
                  plan_modality_id,
                  target_region,
                  laterality,
                  time_minutes
                ) VALUES (
                  v_modality_id,
                  v_region_elem->>'target_region',
                  CASE
                    WHEN v_region_elem->>'laterality' IS NOT NULL AND v_region_elem->>'laterality' != ''
                    THEN (v_region_elem->>'laterality')::public.laterality
                    ELSE NULL
                  END,
                  COALESCE((v_region_elem->>'time_minutes')::integer, 15)
                );
              END LOOP;
            END IF;
          END LOOP;
        END IF;
      END IF;
    END IF;
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
