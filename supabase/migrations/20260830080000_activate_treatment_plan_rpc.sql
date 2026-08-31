-- Migration: 20260830080000_activate_treatment_plan_rpc.sql
-- Description: Atomic RPC to switch the active treatment plan for a rehabilitation program.

CREATE OR REPLACE FUNCTION public.activate_treatment_plan(
  p_plan_id uuid,
  p_program_id uuid
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
    RAISE EXCEPTION 'Permission denied: Only senior doctors and super admins can manage treatment plans.';
  END IF;

  -- Ensure target plan exists in program
  IF NOT EXISTS (
    SELECT 1 FROM public.treatment_plans
    WHERE id = p_plan_id AND program_id = p_program_id
  ) THEN
    RAISE EXCEPTION 'Treatment plan not found in this program.';
  END IF;

  -- Deactivate all other plans in this program
  UPDATE public.treatment_plans
  SET is_active = false, updated_at = now()
  WHERE program_id = p_program_id AND is_active = true;

  -- Activate the selected plan
  UPDATE public.treatment_plans
  SET is_active = true, updated_at = now()
  WHERE id = p_plan_id AND program_id = p_program_id;

  RETURN true;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.activate_treatment_plan(uuid, uuid) TO authenticated;
