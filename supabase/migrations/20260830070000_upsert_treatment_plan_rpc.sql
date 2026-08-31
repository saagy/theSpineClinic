-- Migration: 20260830070000_upsert_treatment_plan_rpc.sql
-- Description: Atomic RPCs for creating, updating, and deleting treatment plans with child modalities and target regions.

CREATE OR REPLACE FUNCTION public.upsert_treatment_plan(
  p_program_id uuid,
  p_plan_id uuid DEFAULT NULL,
  p_plan_name text DEFAULT 'Plan 1',
  p_is_active boolean DEFAULT true,
  p_notes text DEFAULT NULL,
  p_modalities jsonb DEFAULT '[]'::jsonb
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
  v_plan_id uuid;
  v_modality_elem jsonb;
  v_modality_id uuid;
  v_region_elem jsonb;
  v_result jsonb;
BEGIN
  -- Check caller permissions
  SELECT id, role, is_senior, is_active
  INTO v_caller_staff_id, v_caller_role, v_caller_is_senior, v_caller_active
  FROM public.staff
  WHERE user_id = auth.uid();

  IF v_caller_staff_id IS NULL OR v_caller_active IS NOT TRUE THEN
    RAISE EXCEPTION 'Unauthorized: Active staff profile not found.';
  END IF;

  IF v_caller_role != 'super_admin' AND (v_caller_role != 'doctor' OR v_caller_is_senior IS NOT TRUE) THEN
    RAISE EXCEPTION 'Permission denied: Only senior doctors and super admins can manage treatment plans.';
  END IF;

  -- Ensure program exists
  IF NOT EXISTS (SELECT 1 FROM public.patient_programs WHERE id = p_program_id) THEN
    RAISE EXCEPTION 'Program not found.';
  END IF;

  -- If marked active, deactivate any other active plans for this program
  IF p_is_active IS TRUE THEN
    UPDATE public.treatment_plans
    SET is_active = false, updated_at = now()
    WHERE program_id = p_program_id AND is_active = true;
  END IF;

  -- Insert or Update treatment_plans
  IF p_plan_id IS NOT NULL THEN
    UPDATE public.treatment_plans
    SET
      plan_name = COALESCE(p_plan_name, plan_name),
      is_active = COALESCE(p_is_active, is_active),
      notes = p_notes,
      updated_at = now()
    WHERE id = p_plan_id AND program_id = p_program_id
    RETURNING id INTO v_plan_id;

    IF v_plan_id IS NULL THEN
      RAISE EXCEPTION 'Treatment plan not found in this program.';
    END IF;

    -- Clean up existing modalities (cascade removes modality_regions)
    DELETE FROM public.plan_modalities WHERE treatment_plan_id = v_plan_id;
  ELSE
    INSERT INTO public.treatment_plans (
      program_id,
      created_by,
      plan_name,
      is_active,
      notes
    ) VALUES (
      p_program_id,
      v_caller_staff_id,
      COALESCE(p_plan_name, 'Plan 1'),
      COALESCE(p_is_active, true),
      p_notes
    )
    RETURNING id INTO v_plan_id;
  END IF;

  -- Insert modalities and regions from p_modalities
  IF p_modalities IS NOT NULL AND jsonb_array_length(p_modalities) > 0 THEN
    FOR v_modality_elem IN SELECT * FROM jsonb_array_elements(p_modalities) LOOP
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

  SELECT jsonb_build_object(
    'id', tp.id,
    'program_id', tp.program_id,
    'created_by', tp.created_by,
    'plan_name', tp.plan_name,
    'is_active', tp.is_active,
    'notes', tp.notes,
    'created_at', tp.created_at,
    'updated_at', tp.updated_at
  ) INTO v_result
  FROM public.treatment_plans tp
  WHERE tp.id = v_plan_id;

  RETURN v_result;
END;
$function$;

CREATE OR REPLACE FUNCTION public.delete_treatment_plan(
  p_plan_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_caller_staff_id uuid;
  v_caller_role public.user_role;
  v_caller_is_senior boolean;
  v_caller_active boolean;
BEGIN
  SELECT id, role, is_senior, is_active
  INTO v_caller_staff_id, v_caller_role, v_caller_is_senior, v_caller_active
  FROM public.staff
  WHERE user_id = auth.uid();

  IF v_caller_staff_id IS NULL OR v_caller_active IS NOT TRUE THEN
    RAISE EXCEPTION 'Unauthorized: Active staff profile not found.';
  END IF;

  IF v_caller_role != 'super_admin' AND (v_caller_role != 'doctor' OR v_caller_is_senior IS NOT TRUE) THEN
    RAISE EXCEPTION 'Permission denied: Only senior doctors and super admins can delete treatment plans.';
  END IF;

  DELETE FROM public.treatment_plans WHERE id = p_plan_id;
  RETURN true;
END;
$function$;

-- Table permissions and grants for functions
GRANT EXECUTE ON FUNCTION public.upsert_treatment_plan(uuid, uuid, text, boolean, text, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_treatment_plan(uuid) TO authenticated;
