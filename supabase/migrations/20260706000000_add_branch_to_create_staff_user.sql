DROP FUNCTION IF EXISTS public.create_staff_user(
  text,
  text,
  text,
  public.user_role,
  text,
  boolean
);

CREATE OR REPLACE FUNCTION public.create_staff_user(
  new_email text,
  new_password text,
  new_full_name text,
  new_role public.user_role,
  new_phone text DEFAULT NULL::text,
  new_can_manage_payments boolean DEFAULT false,
  new_branch public.clinic_location DEFAULT NULL::public.clinic_location
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
        user_id, full_name, email, phone, role, is_active, can_manage_payments, branch
    )
    VALUES (
        new_user_id, new_full_name, new_email, new_phone, new_role, true,
        CASE WHEN new_role = 'receptionist'::user_role THEN new_can_manage_payments ELSE false END,
        CASE WHEN new_role = 'receptionist'::user_role THEN new_branch ELSE NULL END
    );

    RETURN new_user_id;
END;
$function$;
