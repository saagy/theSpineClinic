-- Staff reference details (docs/billing-plan.md, slice 7): national ID, birth
-- date, hire date, working days and working hours. They are for reference
-- only and never restrict bookings. They live apart from public.staff because
-- every active staff member can read the staff directory; only active super
-- admins can read these. Writes go through create_staff_account and
-- update_staff_account so a staff save stays one transaction.

CREATE TABLE public.staff_details (
  staff_id uuid PRIMARY KEY REFERENCES public.staff(id) ON DELETE CASCADE,
  -- Egyptian national ID: 14 digits.
  national_id text CHECK (national_id ~ '^[0-9]{14}$'),
  birth_date date CHECK (birth_date >= DATE '1900-01-01'),
  hire_date date CHECK (hire_date >= DATE '1950-01-01'),
  -- ISO weekdays, 1 = Monday ... 7 = Sunday; sorted without duplicates.
  working_days smallint[] NOT NULL DEFAULT '{}'
    CHECK (working_days <@ ARRAY[1, 2, 3, 4, 5, 6, 7]::smallint[]),
  work_starts_at time,
  work_ends_at time,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid REFERENCES public.staff(id) ON DELETE SET NULL,
  CHECK ((work_starts_at IS NULL) = (work_ends_at IS NULL)),
  CHECK (work_ends_at > work_starts_at),
  CHECK (hire_date IS NULL OR birth_date IS NULL OR hire_date > birth_date)
);
CREATE UNIQUE INDEX staff_details_national_id_key ON public.staff_details (national_id)
  WHERE national_id IS NOT NULL;

ALTER TABLE public.staff_details ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.staff_details TO authenticated;
CREATE POLICY staff_details_admin_read ON public.staff_details FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile()
    WHERE staff_role = 'super_admin' AND staff_active));
-- No client write policies: the staff account RPCs are the only write path.

-- Saves a staff member's details from JSON. Missing or empty values clear a
-- field. Not callable by clients.
CREATE FUNCTION public.staff_save_details(p_staff_id uuid, p_details jsonb, p_actor uuid)
RETURNS void LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE
  today date := (now() AT TIME ZONE public.clinic_timezone())::date;
  national text; born date; hired date; starts time; ends time; days smallint[];
BEGIN
  IF jsonb_typeof(p_details) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'staff_details_invalid' USING ERRCODE = '22023';
  END IF;
  -- Casts run here so malformed values reach the handler below.
  national := nullif(btrim(p_details->>'national_id'), '');
  born := nullif(p_details->>'birth_date', '')::date;
  hired := nullif(p_details->>'hire_date', '')::date;
  starts := nullif(p_details->>'work_starts_at', '')::time;
  ends := nullif(p_details->>'work_ends_at', '')::time;
  SELECT coalesce(array_agg(DISTINCT d::smallint ORDER BY d::smallint), '{}')
    INTO days FROM jsonb_array_elements_text(coalesce(p_details->'working_days', '[]')) d;
  IF born > today OR hired > today + 366 THEN
    RAISE EXCEPTION 'staff_details_invalid' USING ERRCODE = '22023';
  END IF;
  IF national IS NOT NULL AND EXISTS (SELECT 1 FROM public.staff_details
      WHERE national_id = national AND staff_id <> p_staff_id) THEN
    RAISE EXCEPTION 'staff_national_id_taken' USING ERRCODE = '23505';
  END IF;
  INSERT INTO public.staff_details AS d (staff_id, national_id, birth_date, hire_date,
    working_days, work_starts_at, work_ends_at, updated_at, updated_by)
  VALUES (p_staff_id, national, born, hired, days, starts, ends, now(), p_actor)
  ON CONFLICT (staff_id) DO UPDATE SET national_id = excluded.national_id,
    birth_date = excluded.birth_date, hire_date = excluded.hire_date,
    working_days = excluded.working_days, work_starts_at = excluded.work_starts_at,
    work_ends_at = excluded.work_ends_at, updated_at = excluded.updated_at,
    updated_by = excluded.updated_by;
EXCEPTION
  WHEN check_violation OR invalid_datetime_format OR datetime_field_overflow
    OR invalid_text_representation OR numeric_value_out_of_range THEN
    RAISE EXCEPTION 'staff_details_invalid' USING ERRCODE = '22023';
END;
$$;
REVOKE ALL ON FUNCTION public.staff_save_details(uuid, jsonb, uuid) FROM PUBLIC, anon, authenticated;

-- Creation gains optional details. The old eight-argument signature is
-- replaced; callers that omit new_details behave exactly as before.
DROP FUNCTION public.create_staff_account(text, text, text, public.user_role, text, boolean,
  public.clinic_location, boolean);
CREATE FUNCTION public.create_staff_account(
  new_email text, new_password text, new_full_name text,
  new_role public.user_role, new_phone text DEFAULT NULL,
  new_can_manage_payments boolean DEFAULT false,
  new_branch public.clinic_location DEFAULT NULL,
  new_is_senior boolean DEFAULT false,
  new_details jsonb DEFAULT NULL
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  created_user_id uuid;
  actor uuid := (SELECT id FROM public.staff WHERE user_id = auth.uid()
    AND role = 'super_admin' AND is_active);
BEGIN
  IF actor IS NULL THEN
    RAISE EXCEPTION 'Only active super admins can create staff users.';
  END IF;
  IF new_is_senior AND new_role <> 'doctor' THEN
    RAISE EXCEPTION 'Senior status requires the doctor role.';
  END IF;
  created_user_id := public.create_staff_user(new_email, new_password,
    new_full_name, new_role, new_phone, new_can_manage_payments, new_branch);
  UPDATE public.staff SET is_senior = COALESCE(new_is_senior, false)
    WHERE user_id = created_user_id;
  IF new_details IS NOT NULL THEN
    PERFORM public.staff_save_details(
      (SELECT id FROM public.staff WHERE user_id = created_user_id), new_details, actor);
  END IF;
  RETURN created_user_id;
END;
$$;

-- Profile, senior status, details and optional password commit together or
-- roll back together. A profile without a "details" key leaves them as is.
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
  actor uuid := (SELECT id FROM public.staff WHERE user_id = auth.uid()
    AND role = 'super_admin' AND is_active);
BEGIN
  IF actor IS NULL THEN
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
  IF profile ? 'details' THEN
    PERFORM public.staff_save_details(target_staff_id, profile->'details', actor);
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.create_staff_account(text,text,text,public.user_role,text,boolean,public.clinic_location,boolean,jsonb) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.update_staff_account(uuid,jsonb,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_staff_account(text,text,text,public.user_role,text,boolean,public.clinic_location,boolean,jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_staff_account(uuid,jsonb,text) TO authenticated;
