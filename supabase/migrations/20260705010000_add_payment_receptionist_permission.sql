ALTER TABLE public.staff
ADD COLUMN IF NOT EXISTS can_manage_payments boolean NOT NULL DEFAULT false;

CREATE OR REPLACE FUNCTION public.current_staff_can_manage_payments()
 RETURNS boolean
 LANGUAGE sql
 SECURITY DEFINER
 STABLE
AS $function$
  SELECT EXISTS (
    SELECT 1
    FROM public.staff
    WHERE user_id = auth.uid()
      AND is_active = true
      AND (
        role = 'super_admin'::public.user_role
        OR (role = 'receptionist'::public.user_role AND can_manage_payments = true)
      )
  );
$function$;

DROP FUNCTION IF EXISTS public.create_staff_user(
  text,
  text,
  text,
  public.user_role,
  text
);

CREATE OR REPLACE FUNCTION public.create_staff_user(
  new_email text,
  new_password text,
  new_full_name text,
  new_role public.user_role,
  new_phone text DEFAULT NULL::text,
  new_can_manage_payments boolean DEFAULT false
)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    new_user_id uuid;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.staff
        WHERE user_id = auth.uid()
        AND role = 'super_admin'::user_role
        AND is_active = true
    ) THEN
        RAISE EXCEPTION 'Only active super admins can create staff users.';
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
        new_user_id, 'authenticated', 'authenticated', new_email,
        crypt(new_password, gen_salt('bf')), now(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{}'::jsonb, false, now(), now(), new_phone,
        '', '', '', ''
    );

    INSERT INTO public.staff (
        user_id, full_name, email, phone, role, is_active, can_manage_payments
    )
    VALUES (
        new_user_id, new_full_name, new_email, new_phone, new_role, true,
        CASE WHEN new_role = 'receptionist'::user_role THEN new_can_manage_payments ELSE false END
    );

    RETURN new_user_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.verify_staff_update_permissions()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  caller_role public.user_role;
  caller_active boolean;
BEGIN
  SELECT role, is_active INTO caller_role, caller_active
  FROM staff
  WHERE user_id = auth.uid();

  IF caller_role = 'super_admin' AND caller_active = true THEN
    RETURN NEW;
  END IF;

  IF OLD.user_id = auth.uid() AND NEW.user_id = auth.uid() THEN
    IF NEW.role IS DISTINCT FROM OLD.role THEN
      RAISE EXCEPTION 'You cannot change your own role.';
    END IF;
    IF NEW.is_active IS DISTINCT FROM OLD.is_active THEN
      RAISE EXCEPTION 'You cannot change your active status.';
    END IF;
    IF NEW.can_manage_payments IS DISTINCT FROM OLD.can_manage_payments THEN
      RAISE EXCEPTION 'You cannot change your payment access.';
    END IF;
    IF NEW.id IS DISTINCT FROM OLD.id OR NEW.user_id IS DISTINCT FROM OLD.user_id THEN
      RAISE EXCEPTION 'You cannot change your ID or User ID.';
    END IF;
    RETURN NEW;
  END IF;

  RAISE EXCEPTION 'Permission denied.';
END;
$function$;

DROP POLICY IF EXISTS "Allow users to insert their own profile" ON public.staff;
CREATE POLICY "Allow users to insert their own profile"
ON public.staff
FOR INSERT
TO authenticated
WITH CHECK (
  user_id = auth.uid()
  AND is_active = false
  AND can_manage_payments = false
  AND role = ANY (ARRAY['doctor'::user_role, 'receptionist'::user_role])
);

DROP POLICY IF EXISTS "Only receptionists and admins can record payments" ON public.payment_records;
DROP POLICY IF EXISTS "Super admins and receptionists can update payments" ON public.payment_records;
DROP POLICY IF EXISTS "Super admins and receptionists can delete payments" ON public.payment_records;
DROP POLICY IF EXISTS "Only payment-enabled staff can record payments" ON public.payment_records;
DROP POLICY IF EXISTS "Only payment-enabled staff can update payments" ON public.payment_records;
DROP POLICY IF EXISTS "Only payment-enabled staff can delete payments" ON public.payment_records;

CREATE POLICY "Only payment-enabled staff can record payments"
ON public.payment_records
FOR INSERT
TO authenticated
WITH CHECK (public.current_staff_can_manage_payments());

CREATE POLICY "Only payment-enabled staff can update payments"
ON public.payment_records
FOR UPDATE
TO authenticated
USING (public.current_staff_can_manage_payments())
WITH CHECK (public.current_staff_can_manage_payments());

CREATE POLICY "Only payment-enabled staff can delete payments"
ON public.payment_records
FOR DELETE
TO authenticated
USING (public.current_staff_can_manage_payments());
