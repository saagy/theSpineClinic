-- Keep the original RPC available for older clients; senior creation is atomic.
CREATE OR REPLACE FUNCTION public.create_staff_account(
  new_email text, new_password text, new_full_name text,
  new_role public.user_role, new_phone text DEFAULT NULL,
  new_can_manage_payments boolean DEFAULT false,
  new_branch public.clinic_location DEFAULT NULL,
  new_is_senior boolean DEFAULT false
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  created_user_id uuid;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.staff WHERE user_id = auth.uid()
      AND role = 'super_admin' AND is_active) THEN
    RAISE EXCEPTION 'Only active super admins can create staff users.';
  END IF;
  IF new_is_senior AND new_role <> 'doctor' THEN
    RAISE EXCEPTION 'Senior status requires the doctor role.';
  END IF;
  created_user_id := public.create_staff_user(new_email, new_password,
    new_full_name, new_role, new_phone, new_can_manage_payments, new_branch);
  UPDATE public.staff SET is_senior = COALESCE(new_is_senior, false)
    WHERE user_id = created_user_id;
  RETURN created_user_id;
END;
$$;

-- Commit profile, senior status and optional password together or roll back all.
CREATE OR REPLACE FUNCTION public.update_staff_account(
  target_staff_id uuid, profile jsonb, new_password text DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  target_user_id uuid;
  selected_role public.user_role := (profile->>'role')::public.user_role;
  selected_senior boolean := COALESCE((profile->>'is_senior')::boolean, false);
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.staff WHERE user_id = auth.uid()
      AND role = 'super_admin' AND is_active) THEN
    RAISE EXCEPTION 'Only active super admins can manage staff users.';
  END IF;
  SELECT user_id INTO target_user_id FROM public.staff
    WHERE id = target_staff_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Staff account not found.'; END IF;
  IF selected_senior AND selected_role <> 'doctor' THEN
    RAISE EXCEPTION 'Senior status requires the doctor role.';
  END IF;
  IF target_user_id = auth.uid() AND
      (selected_role <> 'super_admin' OR (profile->>'is_active')::boolean IS NOT TRUE) THEN
    RAISE EXCEPTION 'You cannot change your own role or active status.';
  END IF;
  IF NULLIF(new_password, '') IS NOT NULL THEN
    IF target_user_id IS NULL THEN RAISE EXCEPTION 'Staff account has no user.'; END IF;
    PERFORM public.update_user_password(target_user_id, new_password);
  END IF;
  UPDATE public.staff SET
    full_name = profile->>'full_name', email = profile->>'email',
    phone = profile->>'phone', role = selected_role,
    is_active = (profile->>'is_active')::boolean,
    is_senior = selected_senior,
    can_manage_payments = selected_role = 'receptionist'
      AND COALESCE((profile->>'can_manage_payments')::boolean, false),
    branch = CASE WHEN selected_role = 'receptionist'
      THEN (profile->>'branch')::public.clinic_location ELSE NULL END,
    deactivated_at = CASE WHEN (profile->>'is_active')::boolean THEN NULL
      ELSE COALESCE((profile->>'deactivated_at')::timestamptz, now()) END
  WHERE id = target_staff_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_staff_account(text,text,text,public.user_role,text,boolean,public.clinic_location,boolean) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.update_staff_account(uuid,jsonb,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_staff_account(text,text,text,public.user_role,text,boolean,public.clinic_location,boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_staff_account(uuid,jsonb,text) TO authenticated;
