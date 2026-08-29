-- =============================================================================
-- Migration: Atomic Operations & RPCs
-- Adds atomic stored procedures for doctor registration, appointment doctor
-- assignments, and payment due collection to eliminate race conditions and
-- multi-step partial failure risks.
-- =============================================================================

-- 1. Atomic Doctor / Staff Self-Registration Application
CREATE OR REPLACE FUNCTION public.register_doctor_application(
  p_email text,
  p_password text,
  p_full_name text,
  p_phone text,
  p_role public.user_role DEFAULT 'doctor'::public.user_role,
  p_branch public.clinic_location DEFAULT NULL::public.clinic_location
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $function$
DECLARE
  new_user_id uuid;
BEGIN
  -- Only doctor or receptionist applications allowed via self-registration
  IF p_role NOT IN ('doctor'::user_role, 'receptionist'::user_role) THEN
    RAISE EXCEPTION 'Only doctor or receptionist applications can be submitted.';
  END IF;

  -- Validate email uniqueness
  IF EXISTS (SELECT 1 FROM auth.users WHERE email = p_email) OR
     EXISTS (SELECT 1 FROM public.staff WHERE email = p_email) THEN
    RAISE EXCEPTION 'A user with this email already exists.'
      USING ERRCODE = '23505';
  END IF;

  new_user_id := gen_random_uuid();

  INSERT INTO auth.users (
    instance_id, id, aud, role, email,
    encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data,
    is_super_admin, created_at, updated_at, phone,
    confirmation_token, recovery_token,
    email_change_token_new, email_change
  )
  VALUES (
    '00000000-0000-0000-0000-000000000000'::uuid,
    new_user_id, 'authenticated', 'authenticated', p_email,
    crypt(p_password, gen_salt('bf')), now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb, false, now(), now(), p_phone,
    '', '', '', ''
  );

  INSERT INTO public.staff (
    user_id, full_name, email, phone, role, is_active, can_manage_payments, branch
  )
  VALUES (
    new_user_id, p_full_name, p_email, p_phone, p_role, false, false,
    CASE WHEN p_role = 'receptionist'::user_role THEN p_branch ELSE NULL END
  );

  RETURN new_user_id;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.register_doctor_application(text, text, text, text, public.user_role, public.clinic_location) TO anon, authenticated;

-- 2. Atomic Appointment Doctors Synchronisation
CREATE OR REPLACE FUNCTION public.update_appointment_doctors(
  p_appointment_id uuid,
  p_doctor_ids uuid[],
  p_editor_id uuid DEFAULT NULL::uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_staff_id   uuid;
  v_staff_role public.user_role;
  v_active     boolean;
  invalid_count integer;
  v_now        timestamptz := now();
BEGIN
  -- Verify caller permissions
  SELECT staff_id, staff_role, staff_active
    INTO v_staff_id, v_staff_role, v_active
    FROM public.get_auth_staff_profile();

  IF NOT coalesce(v_active, false) OR v_staff_role NOT IN ('super_admin', 'receptionist') THEN
    RAISE EXCEPTION 'Permission denied: must be active super_admin or receptionist'
      USING ERRCODE = '42501';
  END IF;

  IF coalesce(array_length(p_doctor_ids, 1), 0) = 0 THEN
    RAISE EXCEPTION 'At least one doctor must be assigned'
      USING ERRCODE = '22000';
  END IF;

  -- Validate all doctor IDs are active doctor accounts
  SELECT count(*) INTO invalid_count
  FROM unnest(p_doctor_ids) AS did
  LEFT JOIN public.staff s ON s.id = did
    AND s.role = 'doctor'::public.user_role
    AND s.is_active = true
  WHERE s.id IS NULL;

  IF invalid_count > 0 THEN
    RAISE EXCEPTION 'Found % ID(s) that do not belong to active doctor accounts.', invalid_count
      USING ERRCODE = '22000';
  END IF;

  -- Deactivate doctors no longer in the assigned list
  UPDATE public.appointment_doctors
     SET is_active = false
   WHERE appointment_id = p_appointment_id
     AND is_active = true
     AND doctor_id != ALL(p_doctor_ids);

  -- Reactivate doctors in the list who have inactive records
  UPDATE public.appointment_doctors
     SET is_active = true,
         added_by  = coalesce(p_editor_id, v_staff_id),
         added_at  = v_now
   WHERE appointment_id = p_appointment_id
     AND is_active = false
     AND doctor_id = ANY(p_doctor_ids);

  -- Insert new doctor assignments that don't have records yet
  INSERT INTO public.appointment_doctors (appointment_id, doctor_id, is_active, added_by, added_at)
  SELECT p_appointment_id, unnest, true, coalesce(p_editor_id, v_staff_id), v_now
    FROM unnest(p_doctor_ids)
   WHERE unnest NOT IN (
     SELECT doctor_id FROM public.appointment_doctors
      WHERE appointment_id = p_appointment_id
   );
END;
$function$;

GRANT EXECUTE ON FUNCTION public.update_appointment_doctors(uuid, uuid[], uuid) TO authenticated;

-- 3. Atomic Payment Due Collection (Race Condition Safe)
CREATE OR REPLACE FUNCTION public.collect_payment_due(
  p_payment_id uuid,
  p_additional_amount numeric
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  -- Verify caller has payment management permission
  IF NOT public.current_staff_can_manage_payments() THEN
    RAISE EXCEPTION 'Permission denied: cannot manage payments'
      USING ERRCODE = '42501';
  END IF;

  IF p_additional_amount IS NULL OR p_additional_amount <= 0 THEN
    RAISE EXCEPTION 'Additional amount must be greater than zero.'
      USING ERRCODE = '22000';
  END IF;

  UPDATE public.payment_records
     SET amount = amount + p_additional_amount
   WHERE id = p_payment_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payment record not found: %', p_payment_id
      USING ERRCODE = 'P0002';
  END IF;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.collect_payment_due(uuid, numeric) TO authenticated;
