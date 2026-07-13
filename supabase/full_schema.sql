-- Spine Clinic full database schema DDL. Verified 100% against live Supabase project (ujketpugttdqpcixrnga).
-- Run this script to recreate the database schema from scratch.

-- Custom Enum Types
CREATE TYPE public.user_role AS ENUM (
  'super_admin',
  'receptionist',
  'doctor'
);

CREATE TYPE public.clinic_location AS ENUM (
  'tagamoa',
  'masr_elgedida'
);

CREATE TYPE public.appointment_type AS ENUM (
  'normal_pt_session',
  'spinal_traction_session',
  'check_up',
  'initial_assessment',
  'reassessment'
);

CREATE TYPE public.appointment_status AS ENUM (
  'scheduled',
  'checked_in',
  'cancelled'
);

-- Core Tables
CREATE TABLE public.staff (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name       text NOT NULL,
  email           text NOT NULL UNIQUE,
  role            public.user_role NOT NULL,
  is_active       boolean NOT NULL DEFAULT true,
  can_manage_payments boolean NOT NULL DEFAULT false,
  created_at      timestamptz NOT NULL DEFAULT now(),
  phone           text,
  branch          public.clinic_location,
  deactivated_at  timestamptz
);
ALTER TABLE public.staff ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.patients (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name         text NOT NULL,
  phone_number      text NOT NULL,
  program           text,
  clinic            public.clinic_location NOT NULL,
  session_balance   integer NOT NULL DEFAULT 0,
  created_by        uuid REFERENCES public.staff(id) ON DELETE SET NULL,
  created_at        timestamptz NOT NULL DEFAULT now(),
  traction_balance  integer NOT NULL DEFAULT 0,
  next_visit_date   date
);
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.patient_doctors (
  patient_id  uuid NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  doctor_id   uuid NOT NULL REFERENCES public.staff(id) ON DELETE CASCADE,
  assigned_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (patient_id, doctor_id)
);
ALTER TABLE public.patient_doctors ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.appointments (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id    uuid NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  type          public.appointment_type NOT NULL,
  status        public.appointment_status NOT NULL DEFAULT 'scheduled'::public.appointment_status,
  use_package   boolean NOT NULL DEFAULT true,
  created_by    uuid REFERENCES public.staff(id) ON DELETE SET NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  scheduled_at  timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.appointment_doctors (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id     uuid NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
  doctor_id          uuid NOT NULL REFERENCES public.staff(id) ON DELETE RESTRICT,
  is_active          boolean NOT NULL DEFAULT true,
  added_by           uuid REFERENCES public.staff(id) ON DELETE SET NULL,
  added_at           timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.appointment_doctors ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.patient_documents (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id     uuid NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  file_url       text NOT NULL,
  file_name      text NOT NULL,
  uploaded_by    uuid REFERENCES public.staff(id) ON DELETE SET NULL,
  uploaded_at    timestamptz NOT NULL DEFAULT now(),
  thumbnail_url  text
);
ALTER TABLE public.patient_documents ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.patient_notes (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id      uuid NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  appointment_id  uuid REFERENCES public.appointments(id) ON DELETE SET NULL,
  created_by      uuid NOT NULL REFERENCES public.staff(id) ON DELETE RESTRICT,
  note_text       text NOT NULL,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.patient_notes ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.payment_records (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id             uuid NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  amount                 numeric NOT NULL,
  reason                 text NOT NULL,
  recorded_by            uuid REFERENCES public.staff(id) ON DELETE SET NULL,
  recorded_at            timestamptz NOT NULL DEFAULT now(),
  session_balance_added  integer NOT NULL DEFAULT 0,
  traction_balance_added integer NOT NULL DEFAULT 0,
  total_price            numeric DEFAULT NULL
);
ALTER TABLE public.payment_records ENABLE ROW LEVEL SECURITY;

-- Indexes
CREATE UNIQUE INDEX unique_active_appointment_doctor ON public.appointment_doctors USING btree (appointment_id, doctor_id) WHERE (is_active = true);
CREATE INDEX idx_appointments_patient_status_scheduled ON public.appointments USING btree (patient_id, status, scheduled_at DESC);
CREATE INDEX idx_appointments_scheduled_at ON public.appointments USING btree (scheduled_at);
CREATE INDEX idx_patients_clinic_next_visit ON public.patients USING btree (clinic, next_visit_date) WHERE (next_visit_date IS NOT NULL);
CREATE INDEX idx_patient_notes_patient ON public.patient_notes USING btree (patient_id);

-- Functions & RPCs
CREATE OR REPLACE FUNCTION public.clinic_timezone()
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 PARALLEL SAFE
AS $function$
  SELECT 'Africa/Cairo'::text;
$function$;

CREATE OR REPLACE FUNCTION public.get_auth_staff_profile()
 RETURNS TABLE(staff_id uuid, staff_role public.user_role, staff_active boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT id, role, is_active 
    FROM public.staff 
    WHERE user_id = auth.uid() 
    LIMIT 1;
END;
$function$;

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

CREATE OR REPLACE FUNCTION public.check_patient_has_doctors()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  doctor_count integer;
BEGIN
  IF EXISTS (SELECT 1 FROM public.patients WHERE id = OLD.patient_id) THEN
    SELECT count(*) INTO doctor_count
    FROM public.patient_doctors
    WHERE patient_id = OLD.patient_id;

    IF doctor_count = 0 THEN
      RAISE EXCEPTION 'Patient % would have no assigned doctors. Reassign them to another doctor first.',
        OLD.patient_id
        USING ERRCODE = '22000';
    END IF;
  END IF;

  RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION public.enforce_doctor_reference_roles()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path = public
AS $function$
DECLARE
  column_name text;
  referenced_staff_id uuid;
BEGIN
  FOREACH column_name IN ARRAY TG_ARGV LOOP
    referenced_staff_id := (to_jsonb(NEW) ->> column_name)::uuid;
    IF referenced_staff_id IS NOT NULL AND NOT EXISTS (
      SELECT 1
      FROM public.staff
      WHERE id = referenced_staff_id
        AND role = 'doctor'::public.user_role
    ) THEN
      RAISE EXCEPTION '% must reference a doctor account.', column_name
        USING ERRCODE = '23514';
    END IF;
  END LOOP;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.prevent_referenced_doctor_role_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path = public
AS $function$
BEGIN
  IF OLD.role = 'doctor'::public.user_role
     AND NEW.role <> 'doctor'::public.user_role
     AND (
       EXISTS (SELECT 1 FROM public.patient_doctors WHERE doctor_id = OLD.id)
       OR EXISTS (
         SELECT 1 FROM public.appointment_doctors
         WHERE doctor_id = OLD.id
       )
     ) THEN
    RAISE EXCEPTION 'Reassign this doctor before changing their role.'
      USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.create_patient_with_doctors(p_name text, p_phone text, p_program text, p_clinic public.clinic_location, p_created_by uuid, p_doctor_ids uuid[])
 RETURNS public.patients
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
    DECLARE
      new_patient public.patients;
      doc_id uuid;
      invalid_count integer;
    BEGIN
      IF NOT EXISTS (
        SELECT 1 FROM public.get_auth_staff_profile()
        WHERE staff_role IN ('super_admin'::user_role, 'receptionist'::user_role)
          AND staff_active = true
      ) THEN
        RAISE EXCEPTION 'Only active receptionists or super admins can register patients.'
          USING ERRCODE = '42501';
      END IF;

      IF p_doctor_ids IS NULL OR array_length(p_doctor_ids, 1) = 0 THEN
        RAISE EXCEPTION 'At least one assigned doctor is required.'
          USING ERRCODE = '22000';
      END IF;

      SELECT count(*) INTO invalid_count
      FROM unnest(p_doctor_ids) AS did
      LEFT JOIN public.staff s ON s.id = did
        AND s.is_active = true
        AND s.role = 'doctor'::public.user_role
      WHERE s.id IS NULL;
      IF invalid_count > 0 THEN
        RAISE EXCEPTION 'All assigned doctors must be active doctor accounts. Found % invalid doctor(s).',
          invalid_count
          USING ERRCODE = '22000';
      END IF;

      INSERT INTO public.patients (
        full_name, phone_number, program, clinic,
        session_balance, traction_balance, created_by, created_at
      )
      VALUES (p_name, p_phone, p_program, p_clinic, 0, 0, p_created_by, NOW())
      RETURNING * INTO new_patient;

      FOREACH doc_id IN ARRAY p_doctor_ids LOOP
        INSERT INTO public.patient_doctors (patient_id, doctor_id)
        VALUES (new_patient.id, doc_id);
      END LOOP;

      RETURN new_patient;
    END;
    $function$;

CREATE OR REPLACE FUNCTION public.update_patient_doctors(p_patient_id uuid, p_doctor_ids uuid[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  doc_id uuid;
  invalid_count integer;
  active_count integer;
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.get_auth_staff_profile()
    WHERE staff_role IN ('super_admin'::user_role, 'receptionist'::user_role)
      AND staff_active = true
  ) THEN
    RAISE EXCEPTION 'Only active receptionists or super admins can update patient doctor assignments.'
      USING ERRCODE = '42501';
  END IF;

  IF p_doctor_ids IS NULL OR array_length(p_doctor_ids, 1) = 0 THEN
    RAISE EXCEPTION 'At least one assigned doctor is required.'
      USING ERRCODE = '22000';
  END IF;

  SELECT count(*) INTO invalid_count
  FROM unnest(p_doctor_ids) AS did
  LEFT JOIN public.staff s ON s.id = did
    AND s.role = 'doctor'::public.user_role
  WHERE s.id IS NULL;

  IF invalid_count > 0 THEN
    RAISE EXCEPTION 'Found % ID(s) that do not belong to doctor accounts.', invalid_count
      USING ERRCODE = '22000';
  END IF;

  SELECT count(*) INTO active_count
  FROM unnest(p_doctor_ids) AS did
  JOIN public.staff s ON s.id = did
    AND s.is_active = true
    AND s.role = 'doctor'::public.user_role;

  IF active_count = 0 THEN
    RAISE EXCEPTION 'At least one active doctor is required.'
      USING ERRCODE = '22000';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.patient_doctors
    WHERE patient_id = p_patient_id
  ) AND (
    SELECT count(*) = array_length(p_doctor_ids, 1)
      AND array_agg(doctor_id ORDER BY doctor_id)
          = (SELECT array_agg(x ORDER BY x) FROM unnest(p_doctor_ids) AS x)
    FROM public.patient_doctors
    WHERE patient_id = p_patient_id
  ) THEN
    RETURN;
  END IF;

  DELETE FROM public.patient_doctors WHERE patient_id = p_patient_id;

  FOREACH doc_id IN ARRAY p_doctor_ids LOOP
    INSERT INTO public.patient_doctors (patient_id, doctor_id)
    VALUES (p_patient_id, doc_id);
  END LOOP;
END;
$function$;

CREATE OR REPLACE FUNCTION public.create_staff_user(new_email text, new_password text, new_full_name text, new_role public.user_role, new_phone text DEFAULT NULL::text, new_can_manage_payments boolean DEFAULT false, new_branch public.clinic_location DEFAULT NULL::public.clinic_location)
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

CREATE OR REPLACE FUNCTION public.update_user_password(target_user_id uuid, new_password text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.staff
        WHERE user_id = auth.uid()
        AND role = 'super_admin'::user_role
        AND is_active = true
    ) THEN
        RAISE EXCEPTION 'Only active super admins can change user passwords.';
    END IF;

    UPDATE auth.users
    SET encrypted_password = crypt(new_password, gen_salt('bf')),
        updated_at = now()
    WHERE id = target_user_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.delete_doctor_user(target_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.staff
        WHERE user_id = auth.uid()
        AND role = 'super_admin'::user_role
        AND is_active = true
    ) THEN
        RAISE EXCEPTION 'Only active super admins can reject/delete doctor applications.';
    END IF;

    DELETE FROM auth.users WHERE id = target_user_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.handle_package_deduction()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  bucket text;
BEGIN
  IF NEW.type = 'normal_pt_session'::public.appointment_type THEN
    bucket := 'session_balance';
  ELSIF NEW.type = 'spinal_traction_session'::public.appointment_type THEN
    bucket := 'traction_balance';
  ELSE
    RETURN NEW;
  END IF;

  IF OLD.status = 'scheduled'
     AND NEW.status = 'checked_in'
     AND NEW.use_package = true THEN
    EXECUTE format(
      'UPDATE public.patients SET %I = %I - 1 WHERE id = $1',
      bucket, bucket
    ) USING NEW.patient_id;

  ELSIF OLD.status = 'checked_in'
     AND NEW.status IN ('scheduled', 'cancelled')
     AND OLD.use_package = true THEN
    EXECUTE format(
      'UPDATE public.patients SET %I = %I + 1 WHERE id = $1',
      bucket, bucket
    ) USING NEW.patient_id;
  END IF;

  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.handle_payment_package_sync()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.session_balance_added IS NOT NULL AND NEW.session_balance_added > 0 THEN
      UPDATE public.patients
        SET session_balance = session_balance + NEW.session_balance_added
        WHERE id = NEW.patient_id;
    END IF;
    IF NEW.traction_balance_added IS NOT NULL AND NEW.traction_balance_added > 0 THEN
      UPDATE public.patients
        SET traction_balance = traction_balance + NEW.traction_balance_added
        WHERE id = NEW.patient_id;
    END IF;
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.session_balance_added IS NOT NULL AND OLD.session_balance_added > 0 THEN
      UPDATE public.patients
        SET session_balance = session_balance - OLD.session_balance_added
        WHERE id = OLD.patient_id;
    END IF;
    IF OLD.traction_balance_added IS NOT NULL AND OLD.traction_balance_added > 0 THEN
      UPDATE public.patients
        SET traction_balance = traction_balance - OLD.traction_balance_added
        WHERE id = OLD.patient_id;
    END IF;
  END IF;
  RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION public.sync_staff_email_to_auth_users()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    IF (NEW.email IS DISTINCT FROM OLD.email) AND (NEW.user_id IS NOT NULL) THEN
        UPDATE auth.users
        SET email = NEW.email,
            email_change = NEW.email
        WHERE id = NEW.user_id;
    END IF;
    RETURN NEW;
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

CREATE OR REPLACE FUNCTION public.get_due_patients(
  p_due_on date,
  p_doctor_id uuid,
  p_clinic public.clinic_location
)
 RETURNS SETOF public.patients
 LANGUAGE sql
 STABLE
 SECURITY INVOKER
AS $function$
  SELECT p.*
  FROM public.patients p
  WHERE p.clinic = p_clinic
    AND p.next_visit_date IS NOT NULL
    AND p.next_visit_date <= p_due_on
    AND (
      p_doctor_id IS NULL
      OR EXISTS (
        SELECT 1
        FROM public.patient_doctors pd
        WHERE pd.patient_id = p.id
          AND pd.doctor_id = p_doctor_id
      )
    )
    AND NOT EXISTS (
      SELECT 1
      FROM public.appointments a
      WHERE a.patient_id = p.id
        AND a.status = 'scheduled'::public.appointment_status
        AND (a.scheduled_at AT TIME ZONE public.clinic_timezone())::date >= p.next_visit_date
    )
  ORDER BY p.next_visit_date, p.full_name;
$function$;

CREATE OR REPLACE FUNCTION public.book_recurring_appointments(
  p_patient_id uuid,
  p_type public.appointment_type,
  p_slots timestamptz[],
  p_use_package boolean,
  p_creator_id uuid,
  p_doctor_ids uuid[],
  p_expected_next_visit_date date DEFAULT NULL
)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path = public
AS $function$
DECLARE
  v_slot timestamptz;
  v_appt_id uuid;
  v_doc_id uuid;
  v_staff_id uuid;
  v_staff_role public.user_role;
  v_staff_active boolean;
  v_next_visit date;
BEGIN
  SELECT staff_id, staff_role, staff_active
  INTO v_staff_id, v_staff_role, v_staff_active
  FROM public.get_auth_staff_profile();

  IF v_staff_active IS DISTINCT FROM true
     OR v_staff_role NOT IN ('receptionist', 'super_admin')
     OR v_staff_id IS DISTINCT FROM p_creator_id THEN
    RAISE EXCEPTION 'Permission denied.' USING ERRCODE = '42501';
  END IF;

  IF coalesce(array_length(p_slots, 1), 0) = 0
     OR coalesce(array_length(p_doctor_ids, 1), 0) = 0 THEN
    RAISE EXCEPTION 'At least one slot and doctor are required.';
  END IF;

  IF p_expected_next_visit_date IS NOT NULL THEN
    SELECT next_visit_date INTO v_next_visit
    FROM public.patients
    WHERE id = p_patient_id
    FOR UPDATE;

    IF v_next_visit IS DISTINCT FROM p_expected_next_visit_date
       OR EXISTS (
         SELECT 1
         FROM unnest(p_slots) AS slots(slot)
         WHERE (slots.slot AT TIME ZONE public.clinic_timezone())::date
               < v_next_visit
       )
       OR EXISTS (
         SELECT 1 FROM public.appointments a
         WHERE a.patient_id = p_patient_id
           AND a.status = 'scheduled'::public.appointment_status
           AND (a.scheduled_at AT TIME ZONE public.clinic_timezone())::date >= v_next_visit
       ) THEN
      RAISE EXCEPTION 'Patient is no longer due for booking.'
        USING ERRCODE = 'P0001';
    END IF;
  END IF;

  FOREACH v_slot IN ARRAY p_slots LOOP
    INSERT INTO public.appointments (
      patient_id,
      type,
      scheduled_at,
      status,
      use_package,
      created_by
    ) VALUES (
      p_patient_id,
      p_type,
      v_slot,
      'scheduled'::public.appointment_status,
      p_use_package,
      p_creator_id
    ) RETURNING id INTO v_appt_id;

    FOREACH v_doc_id IN ARRAY p_doctor_ids LOOP
      INSERT INTO public.appointment_doctors (
        appointment_id,
        doctor_id,
        is_active,
        added_by
      ) VALUES (
        v_appt_id,
        v_doc_id,
        true,
        p_creator_id
      );
    END LOOP;
  END LOOP;
END;
$function$;

CREATE OR REPLACE FUNCTION public.bulk_replace_appointment_doctor(
  p_absent_doctor_id uuid,
  p_replacement_doctor_ids uuid[],
  p_appointment_ids uuid[],
  p_day date
)
 RETURNS TABLE(replaced_count integer, remaining_count integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path = public
AS $function$
DECLARE
  v_editor_id uuid;
  v_role public.user_role;
  v_active boolean;
  v_appointment_id uuid;
  v_doctor_id uuid;
  v_expected integer;
BEGIN
  SELECT staff_id, staff_role, staff_active
  INTO v_editor_id, v_role, v_active
  FROM public.get_auth_staff_profile();

  IF v_active IS DISTINCT FROM true
     OR v_role NOT IN ('receptionist', 'super_admin') THEN
    RAISE EXCEPTION 'Permission denied.' USING ERRCODE = '42501';
  END IF;

  IF coalesce(array_length(p_appointment_ids, 1), 0) = 0
     OR coalesce(array_length(p_replacement_doctor_ids, 1), 0) = 0
     OR p_absent_doctor_id = ANY(p_replacement_doctor_ids) THEN
    RAISE EXCEPTION 'Invalid replacement selection.';
  END IF;

  SELECT count(DISTINCT id)::integer INTO v_expected
  FROM public.staff
  WHERE id = ANY(p_replacement_doctor_ids)
    AND role = 'doctor' AND is_active = true;
  IF v_expected <> cardinality(p_replacement_doctor_ids) THEN
    RAISE EXCEPTION 'Every replacement must be an active doctor.';
  END IF;

  PERFORM 1
  FROM public.appointments a
  JOIN public.appointment_doctors ad ON ad.appointment_id = a.id
  WHERE a.id = ANY(p_appointment_ids)
    AND a.status <> 'cancelled'
    AND (a.scheduled_at AT TIME ZONE public.clinic_timezone())::date = p_day
    AND ad.doctor_id = p_absent_doctor_id
    AND ad.is_active = true
  FOR UPDATE OF ad;

  SELECT count(DISTINCT a.id)::integer INTO v_expected
  FROM public.appointments a
  JOIN public.appointment_doctors ad ON ad.appointment_id = a.id
  WHERE a.id = ANY(p_appointment_ids)
    AND a.status <> 'cancelled'
    AND (a.scheduled_at AT TIME ZONE public.clinic_timezone())::date = p_day
    AND ad.doctor_id = p_absent_doctor_id AND ad.is_active = true;
  IF v_expected <> cardinality(p_appointment_ids) THEN
    RAISE EXCEPTION 'One or more appointments are no longer replaceable.';
  END IF;

  FOREACH v_appointment_id IN ARRAY p_appointment_ids LOOP
    UPDATE public.appointment_doctors SET is_active = false
    WHERE appointment_id = v_appointment_id
      AND doctor_id = p_absent_doctor_id AND is_active = true;

    FOREACH v_doctor_id IN ARRAY p_replacement_doctor_ids LOOP
      UPDATE public.appointment_doctors
      SET is_active = true, added_by = v_editor_id, added_at = now()
      WHERE id = (
        SELECT id FROM public.appointment_doctors
        WHERE appointment_id = v_appointment_id
          AND doctor_id = v_doctor_id AND is_active = false
        ORDER BY added_at DESC LIMIT 1
      );
      IF NOT FOUND THEN
        INSERT INTO public.appointment_doctors (
          appointment_id, doctor_id, is_active, added_by
        ) VALUES (v_appointment_id, v_doctor_id, true, v_editor_id);
      END IF;
    END LOOP;
  END LOOP;

  RETURN QUERY
  SELECT cardinality(p_appointment_ids)::integer, count(DISTINCT a.id)::integer
  FROM public.appointments a
  JOIN public.appointment_doctors ad ON ad.appointment_id = a.id
  WHERE a.status <> 'cancelled'
    AND (a.scheduled_at AT TIME ZONE public.clinic_timezone())::date = p_day
    AND ad.doctor_id = p_absent_doctor_id AND ad.is_active = true;
END;
$function$;

-- Triggers
CREATE CONSTRAINT TRIGGER tr_check_patient_has_doctors AFTER DELETE OR UPDATE ON public.patient_doctors DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION check_patient_has_doctors();
CREATE TRIGGER trigger_appointment_package_deduction AFTER UPDATE ON public.appointments FOR EACH ROW EXECUTE FUNCTION handle_package_deduction();
CREATE TRIGGER trigger_payment_insert_package_sync AFTER INSERT ON public.payment_records FOR EACH ROW EXECUTE FUNCTION handle_payment_package_sync();
CREATE TRIGGER trigger_payment_delete_package_sync AFTER DELETE ON public.payment_records FOR EACH ROW EXECUTE FUNCTION handle_payment_package_sync();
CREATE TRIGGER trigger_sync_staff_email AFTER UPDATE ON public.staff FOR EACH ROW EXECUTE FUNCTION sync_staff_email_to_auth_users();
CREATE TRIGGER tr_verify_staff_update_permissions BEFORE UPDATE ON public.staff FOR EACH ROW EXECUTE FUNCTION verify_staff_update_permissions();
CREATE TRIGGER tr_prevent_referenced_doctor_role_change BEFORE UPDATE OF role ON public.staff FOR EACH ROW EXECUTE FUNCTION prevent_referenced_doctor_role_change();
CREATE TRIGGER tr_enforce_patient_doctor_role BEFORE INSERT OR UPDATE OF doctor_id ON public.patient_doctors FOR EACH ROW EXECUTE FUNCTION enforce_doctor_reference_roles('doctor_id');
CREATE TRIGGER tr_enforce_appointment_doctor_roles BEFORE INSERT OR UPDATE OF doctor_id ON public.appointment_doctors FOR EACH ROW EXECUTE FUNCTION enforce_doctor_reference_roles('doctor_id');

-- Table RLS Policies
CREATE POLICY "Active staff members can see the directory" ON public.staff FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true));
CREATE POLICY "Allow users to view their own profile" ON public.staff FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "Allow users to insert their own profile" ON public.staff FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid() AND is_active = false AND can_manage_payments = false AND role = ANY (ARRAY['doctor'::user_role, 'receptionist'::user_role]));
CREATE POLICY "Allow users to update their own profile" ON public.staff FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "Only super_admins can modify staff data" ON public.staff FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_role = 'super_admin'::user_role AND staff_active = true));

CREATE POLICY "Super Admins and Receptionists have full access to patients" ON public.patients FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_role = ANY (ARRAY['super_admin'::user_role, 'receptionist'::user_role]) AND staff_active = true));
CREATE POLICY "Super Admins and Receptionists can delete patients" ON public.patients FOR DELETE TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_role = ANY (ARRAY['super_admin'::user_role, 'receptionist'::user_role]) AND staff_active = true));
CREATE POLICY "Doctors can view assigned or appointment patients" ON public.patients FOR SELECT TO authenticated USING ((EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_role = 'doctor'::user_role AND staff_active = true)) AND (id IN (SELECT pd.patient_id FROM public.patient_doctors pd WHERE pd.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile())) OR id IN (SELECT a.patient_id FROM public.appointments a JOIN public.appointment_doctors ad ON ad.appointment_id = a.id WHERE ad.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile()) AND ad.is_active = true)));
CREATE POLICY "Doctors can update assigned or appointment patients" ON public.patients FOR UPDATE TO authenticated USING ((EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_role = 'doctor'::user_role AND staff_active = true)) AND (id IN (SELECT pd.patient_id FROM public.patient_doctors pd WHERE pd.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile())) OR id IN (SELECT a.patient_id FROM public.appointments a JOIN public.appointment_doctors ad ON ad.appointment_id = a.id WHERE ad.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile()) AND ad.is_active = true))) WITH CHECK ((EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_role = 'doctor'::user_role AND staff_active = true)) AND (id IN (SELECT pd.patient_id FROM public.patient_doctors pd WHERE pd.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile())) OR id IN (SELECT a.patient_id FROM public.appointments a JOIN public.appointment_doctors ad ON ad.appointment_id = a.id WHERE ad.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile()) AND ad.is_active = true)));

CREATE POLICY "All active staff can look at patient-doctor associations" ON public.patient_doctors FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true));
CREATE POLICY "Only receptionists and admins can alter long-term patient doctor assignments" ON public.patient_doctors FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_role = ANY (ARRAY['super_admin'::user_role, 'receptionist'::user_role]) AND staff_active = true));

CREATE POLICY "Staff can view all appointments" ON public.appointments FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true));
CREATE POLICY "Staff can modify appointments" ON public.appointments FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true));

CREATE POLICY "Staff can view appointment doctor assignments" ON public.appointment_doctors FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true));
CREATE POLICY "Staff can modify appointment doctor assignments" ON public.appointment_doctors FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true));

CREATE POLICY "Select patient_documents policy" ON public.patient_documents FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true AND (staff_role = ANY (ARRAY['super_admin'::user_role, 'receptionist'::user_role]) OR (staff_role = 'doctor'::user_role AND (patient_id IN (SELECT pd.patient_id FROM public.patient_doctors pd WHERE pd.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile())) OR patient_id IN (SELECT a.patient_id FROM public.appointments a JOIN public.appointment_doctors ad ON ad.appointment_id = a.id WHERE ad.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile()) AND ad.is_active = true))))));
CREATE POLICY "Insert patient_documents policy" ON public.patient_documents FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true AND staff_id = patient_documents.uploaded_by AND (staff_role = ANY (ARRAY['super_admin'::user_role, 'receptionist'::user_role]) OR (staff_role = 'doctor'::user_role AND (patient_id IN (SELECT pd.patient_id FROM public.patient_doctors pd WHERE pd.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile())) OR patient_id IN (SELECT a.patient_id FROM public.appointments a JOIN public.appointment_doctors ad ON ad.appointment_id = a.id WHERE ad.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile()) AND ad.is_active = true))))));
CREATE POLICY "Update patient_documents policy" ON public.patient_documents FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true AND (staff_role = ANY (ARRAY['super_admin'::user_role, 'receptionist'::user_role]) OR (staff_role = 'doctor'::user_role AND (patient_id IN (SELECT pd.patient_id FROM public.patient_doctors pd WHERE pd.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile())) OR patient_id IN (SELECT a.patient_id FROM public.appointments a JOIN public.appointment_doctors ad ON ad.appointment_id = a.id WHERE ad.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile()) AND ad.is_active = true)))))) WITH CHECK (file_name = btrim(file_name) AND char_length(file_name) BETWEEN 1 AND 255 AND file_name !~ '[[:cntrl:]]' AND EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true AND (staff_role = ANY (ARRAY['super_admin'::user_role, 'receptionist'::user_role]) OR (staff_role = 'doctor'::user_role AND (patient_id IN (SELECT pd.patient_id FROM public.patient_doctors pd WHERE pd.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile())) OR patient_id IN (SELECT a.patient_id FROM public.appointments a JOIN public.appointment_doctors ad ON ad.appointment_id = a.id WHERE ad.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile()) AND ad.is_active = true))))));
CREATE POLICY "Delete patient_documents policy" ON public.patient_documents FOR DELETE TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true AND (staff_role = ANY (ARRAY['super_admin'::user_role, 'receptionist'::user_role]) OR (staff_role = 'doctor'::user_role AND (patient_id IN (SELECT pd.patient_id FROM public.patient_doctors pd WHERE pd.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile())) OR patient_id IN (SELECT a.patient_id FROM public.appointments a JOIN public.appointment_doctors ad ON ad.appointment_id = a.id WHERE ad.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile()) AND ad.is_active = true))))));

REVOKE UPDATE ON TABLE public.patient_documents FROM authenticated;
GRANT UPDATE (file_name) ON TABLE public.patient_documents TO authenticated;

CREATE POLICY "Select patient_notes policy" ON public.patient_notes FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true AND (staff_role = ANY (ARRAY['super_admin'::user_role, 'receptionist'::user_role]) OR (staff_role = 'doctor'::user_role AND (patient_id IN (SELECT pd.patient_id FROM public.patient_doctors pd WHERE pd.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile())) OR patient_id IN (SELECT a.patient_id FROM public.appointments a JOIN public.appointment_doctors ad ON ad.appointment_id = a.id WHERE ad.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile()) AND ad.is_active = true))))));
CREATE POLICY "Insert patient_notes policy" ON public.patient_notes FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true AND staff_id = patient_notes.created_by AND (staff_role = ANY (ARRAY['super_admin'::user_role, 'receptionist'::user_role]) OR (staff_role = 'doctor'::user_role AND (patient_id IN (SELECT pd.patient_id FROM public.patient_doctors pd WHERE pd.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile())) OR patient_id IN (SELECT a.patient_id FROM public.appointments a JOIN public.appointment_doctors ad ON ad.appointment_id = a.id WHERE ad.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile()) AND ad.is_active = true))))));
CREATE POLICY "Update patient_notes policy" ON public.patient_notes FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() p WHERE p.staff_active = true AND (p.staff_role = ANY (ARRAY['super_admin'::user_role, 'receptionist'::user_role]) OR p.staff_role = 'doctor'::user_role))) WITH CHECK (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() p WHERE p.staff_active = true AND (p.staff_role = ANY (ARRAY['super_admin'::user_role, 'receptionist'::user_role]) OR p.staff_role = 'doctor'::user_role)));
CREATE POLICY "Delete patient_notes policy" ON public.patient_notes FOR DELETE TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() p WHERE p.staff_active = true AND (p.staff_role = ANY (ARRAY['super_admin'::user_role, 'receptionist'::user_role]) OR p.staff_role = 'doctor'::user_role)));

CREATE POLICY "All active staff can view payment history logs" ON public.payment_records FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true));
CREATE POLICY "Only payment-enabled staff can record payments" ON public.payment_records FOR INSERT TO authenticated WITH CHECK (public.current_staff_can_manage_payments());
CREATE POLICY "Only payment-enabled staff can update payments" ON public.payment_records FOR UPDATE TO authenticated USING (public.current_staff_can_manage_payments()) WITH CHECK (public.current_staff_can_manage_payments());
CREATE POLICY "Only payment-enabled staff can delete payments" ON public.payment_records FOR DELETE TO authenticated USING (public.current_staff_can_manage_payments());

-- Storage Configuration & Policies
INSERT INTO storage.buckets (id, name, public) VALUES ('patient-documents', 'patient-documents', false) ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Select storage_objects policy" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'patient-documents' AND EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true AND (staff_role = ANY (ARRAY['super_admin'::user_role, 'receptionist'::user_role]) OR (staff_role = 'doctor'::user_role AND (path_tokens[1] IN (SELECT pd.patient_id::text FROM public.patient_doctors pd WHERE pd.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile())) OR path_tokens[1] IN (SELECT a.patient_id::text FROM public.appointments a JOIN public.appointment_doctors ad ON ad.appointment_id = a.id WHERE ad.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile()) AND ad.is_active = true))))));
CREATE POLICY "Insert storage_objects policy" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'patient-documents' AND EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true AND (staff_role = ANY (ARRAY['super_admin'::user_role, 'receptionist'::user_role]) OR (staff_role = 'doctor'::user_role AND (path_tokens[1] IN (SELECT pd.patient_id::text FROM public.patient_doctors pd WHERE pd.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile())) OR path_tokens[1] IN (SELECT a.patient_id::text FROM public.appointments a JOIN public.appointment_doctors ad ON ad.appointment_id = a.id WHERE ad.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile()) AND ad.is_active = true))))));
CREATE POLICY "Update storage_objects policy" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'patient-documents'::text AND EXISTS ( SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true AND staff_role = ANY (ARRAY['super_admin'::user_role, 'receptionist'::user_role])));
CREATE POLICY "Delete storage_objects policy" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'patient-documents' AND EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true AND (staff_role = ANY (ARRAY['super_admin'::user_role, 'receptionist'::user_role]) OR (staff_role = 'doctor'::user_role AND (path_tokens[1] IN (SELECT pd.patient_id::text FROM public.patient_doctors pd WHERE pd.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile())) OR path_tokens[1] IN (SELECT a.patient_id::text FROM public.appointments a JOIN public.appointment_doctors ad ON ad.appointment_id = a.id WHERE ad.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile()) AND ad.is_active = true))))));
