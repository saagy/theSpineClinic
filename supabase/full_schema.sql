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
  'initial_assessment',
  'reassessment'
);

CREATE TYPE public.body_region AS ENUM (
  'shoulder',
  'elbow',
  'hand',
  'lumbar_spine',
  'thoracic_spine',
  'cervical_spine',
  'hip_joint',
  'knee_joint',
  'ankle_joint',
  'foot'
);

CREATE TYPE public.program_status AS ENUM (
  'active',
  'completed',
  'archived'
);

CREATE TYPE public.modality_type AS ENUM (
  'muscle_pain',
  'mass_built',
  'tecar',
  'tecar_focal',
  'neurodynamic_non_wb',
  'neurodynamic_wb'
);

CREATE TYPE public.laterality AS ENUM (
  'right',
  'left',
  'both'
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
  is_senior       boolean NOT NULL DEFAULT false,
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

CREATE TABLE public.patient_medical_history (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id           uuid NOT NULL UNIQUE REFERENCES public.patients(id) ON DELETE CASCADE,
  has_diabetes         boolean NOT NULL DEFAULT false,
  hba1c_value          text,
  has_hypertension     boolean NOT NULL DEFAULT false,
  has_hyperlipidemia   boolean NOT NULL DEFAULT false,
  has_rheumatology     boolean NOT NULL DEFAULT false,
  rheumatology_details text,
  additional_notes     text,
  updated_by           uuid REFERENCES public.staff(id) ON DELETE SET NULL,
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.patient_medical_history ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.condition_catalog (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  region         public.body_region NOT NULL,
  condition_name text NOT NULL,
  display_order  integer NOT NULL DEFAULT 0,
  created_at     timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT unique_region_condition UNIQUE (region, condition_name)
);
ALTER TABLE public.condition_catalog ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.patient_programs (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id             uuid NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  created_by             uuid NOT NULL REFERENCES public.staff(id) ON DELETE RESTRICT,
  status                 public.program_status NOT NULL DEFAULT 'active'::public.program_status,
  examination            text,
  imaging_notes          text,
  exaggerating_positions text,
  relieving_positions    text,
  notes                  text,
  created_at             timestamptz NOT NULL DEFAULT now(),
  updated_at             timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.patient_programs ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.program_conditions (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id   uuid NOT NULL REFERENCES public.patient_programs(id) ON DELETE CASCADE,
  condition_id uuid NOT NULL REFERENCES public.condition_catalog(id) ON DELETE CASCADE,
  CONSTRAINT unique_program_condition UNIQUE (program_id, condition_id)
);
ALTER TABLE public.program_conditions ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.treatment_plans (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id  uuid NOT NULL REFERENCES public.patient_programs(id) ON DELETE CASCADE,
  created_by  uuid NOT NULL REFERENCES public.staff(id) ON DELETE RESTRICT,
  plan_name   text NOT NULL DEFAULT 'Plan 1',
  is_active   boolean NOT NULL DEFAULT true,
  notes       text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.treatment_plans ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.plan_modalities (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  treatment_plan_id uuid NOT NULL REFERENCES public.treatment_plans(id) ON DELETE CASCADE,
  modality_type     public.modality_type NOT NULL,
  notes             text,
  CONSTRAINT unique_plan_modality UNIQUE (treatment_plan_id, modality_type)
);
ALTER TABLE public.plan_modalities ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.modality_regions (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_modality_id uuid NOT NULL REFERENCES public.plan_modalities(id) ON DELETE CASCADE,
  target_region    text NOT NULL,
  laterality       public.laterality,
  time_minutes     integer NOT NULL DEFAULT 15
);
ALTER TABLE public.modality_regions ENABLE ROW LEVEL SECURITY;

CREATE TABLE public.patient_documents (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id     uuid NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  file_url       text NOT NULL,
  file_name      text NOT NULL,
  uploaded_by    uuid REFERENCES public.staff(id) ON DELETE SET NULL,
  uploaded_at    timestamptz NOT NULL DEFAULT now(),
  thumbnail_url  text,
  program_id     uuid REFERENCES public.patient_programs(id) ON DELETE CASCADE
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
CREATE INDEX idx_medical_history_patient ON public.patient_medical_history USING btree (patient_id);
CREATE INDEX idx_condition_catalog_region ON public.condition_catalog USING btree (region, display_order);
CREATE INDEX idx_patient_programs_patient ON public.patient_programs USING btree (patient_id, status);
CREATE INDEX idx_program_conditions_program ON public.program_conditions USING btree (program_id);
CREATE INDEX idx_treatment_plans_program ON public.treatment_plans USING btree (program_id, is_active);
CREATE INDEX idx_plan_modalities_plan ON public.plan_modalities USING btree (treatment_plan_id);
CREATE INDEX idx_modality_regions_modality ON public.modality_regions USING btree (plan_modality_id);
CREATE INDEX idx_patient_documents_program ON public.patient_documents USING btree (program_id);

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

CREATE OR REPLACE FUNCTION public.can_current_staff_access_patient(p_patient_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.staff s
    WHERE s.user_id = auth.uid()
      AND s.is_active = true
      AND (
        s.role IN ('super_admin'::public.user_role, 'receptionist'::public.user_role)
        OR (
          s.role = 'doctor'::public.user_role
          AND (
            s.is_senior = true
            OR EXISTS (
              SELECT 1 FROM public.patient_doctors pd
              WHERE pd.patient_id = p_patient_id AND pd.doctor_id = s.id
            )
            OR EXISTS (
              SELECT 1 FROM public.appointments a
              JOIN public.appointment_doctors ad ON ad.appointment_id = a.id
              WHERE a.patient_id = p_patient_id
                AND ad.doctor_id = s.id
                AND ad.is_active = true
            )
          )
        )
      )
  );
$function$;

CREATE OR REPLACE FUNCTION public.can_current_staff_modify_patient_programs(p_patient_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.staff s
    WHERE s.user_id = auth.uid()
      AND s.is_active = true
      AND (
        s.role = 'super_admin'::public.user_role
        OR (
          s.role = 'doctor'::public.user_role
          AND s.is_senior = true
        )
      )
  );
$function$;

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
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

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
    IF NEW.is_senior IS DISTINCT FROM OLD.is_senior THEN
      RAISE EXCEPTION 'You cannot change your senior doctor status.';
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
  v_current_balance integer;
  v_future_commitments integer;
  v_available_balance integer;
  v_required_sessions integer;
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

  -- Enforce package balance limit when booking with use_package = true
  IF p_use_package AND p_type IN ('normal_pt_session'::public.appointment_type, 'spinal_traction_session'::public.appointment_type) THEN
    v_required_sessions := coalesce(array_length(p_slots, 1), 0);

    IF p_type = 'normal_pt_session'::public.appointment_type THEN
      SELECT coalesce(session_balance, 0) INTO v_current_balance
      FROM public.patients
      WHERE id = p_patient_id
      FOR UPDATE;
    ELSIF p_type = 'spinal_traction_session'::public.appointment_type THEN
      SELECT coalesce(traction_balance, 0) INTO v_current_balance
      FROM public.patients
      WHERE id = p_patient_id
      FOR UPDATE;
    END IF;

    SELECT count(*) INTO v_future_commitments
    FROM public.appointments
    WHERE patient_id = p_patient_id
      AND type = p_type
      AND status = 'scheduled'::public.appointment_status
      AND use_package = true
      AND scheduled_at >= now();

    v_available_balance := coalesce(v_current_balance, 0) - coalesce(v_future_commitments, 0);

    IF v_required_sessions > v_available_balance THEN
      RAISE EXCEPTION 'Insufficient package balance. Available: %, Requested: %', v_available_balance, v_required_sessions
        USING ERRCODE = 'P0002';
    END IF;
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
      IF EXISTS (
        SELECT 1 FROM public.appointment_doctors
        WHERE appointment_id = v_appointment_id
          AND doctor_id = v_doctor_id AND is_active = true
      ) THEN
        CONTINUE;
      END IF;

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
  IF p_role NOT IN ('doctor'::user_role, 'receptionist'::user_role) THEN
    RAISE EXCEPTION 'Only doctor or receptionist applications can be submitted.';
  END IF;

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

  UPDATE public.appointment_doctors
     SET is_active = false
   WHERE appointment_id = p_appointment_id
     AND is_active = true
     AND doctor_id != ALL(p_doctor_ids);

  UPDATE public.appointment_doctors
     SET is_active = true,
         added_by  = coalesce(p_editor_id, v_staff_id),
         added_at  = v_now
   WHERE appointment_id = p_appointment_id
     AND is_active = false
     AND doctor_id = ANY(p_doctor_ids);

  INSERT INTO public.appointment_doctors (appointment_id, doctor_id, is_active, added_by, added_at)
  SELECT p_appointment_id, unnest, true, coalesce(p_editor_id, v_staff_id), v_now
    FROM unnest(p_doctor_ids)
   WHERE unnest NOT IN (
     SELECT doctor_id FROM public.appointment_doctors
      WHERE appointment_id = p_appointment_id
   );
END;
$function$;

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

  IF NOT EXISTS (SELECT 1 FROM public.patient_programs WHERE id = p_program_id) THEN
    RAISE EXCEPTION 'Program not found.';
  END IF;

  IF p_is_active IS TRUE THEN
    UPDATE public.treatment_plans
    SET is_active = false, updated_at = now()
    WHERE program_id = p_program_id AND is_active = true;
  END IF;

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

  IF NOT EXISTS (
    SELECT 1 FROM public.treatment_plans
    WHERE id = p_plan_id AND program_id = p_program_id
  ) THEN
    RAISE EXCEPTION 'Treatment plan not found in this program.';
  END IF;

  UPDATE public.treatment_plans
  SET is_active = false, updated_at = now()
  WHERE program_id = p_program_id AND is_active = true;

  UPDATE public.treatment_plans
  SET is_active = true, updated_at = now()
  WHERE id = p_plan_id AND program_id = p_program_id;

  RETURN true;
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
CREATE POLICY "Staff can view accessible patients" ON public.patients FOR SELECT TO authenticated USING (public.can_current_staff_access_patient(id));
CREATE POLICY "Staff can update accessible patients" ON public.patients FOR UPDATE TO authenticated USING (public.can_current_staff_access_patient(id)) WITH CHECK (public.can_current_staff_access_patient(id));

CREATE POLICY "All active staff can look at patient-doctor associations" ON public.patient_doctors FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true));
CREATE POLICY "Only receptionists and admins can alter long-term patient doctor assignments" ON public.patient_doctors FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_role = ANY (ARRAY['super_admin'::user_role, 'receptionist'::user_role]) AND staff_active = true));

CREATE POLICY "Staff can view all appointments" ON public.appointments FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true));
CREATE POLICY "Staff can modify appointments" ON public.appointments FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true));

CREATE POLICY "Staff can view appointment doctor assignments" ON public.appointment_doctors FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true));
CREATE POLICY "Staff can modify appointment doctor assignments" ON public.appointment_doctors FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true));

CREATE POLICY "Select patient_documents policy" ON public.patient_documents FOR SELECT TO authenticated USING (public.can_current_staff_access_patient(patient_id));
CREATE POLICY "Insert patient_documents policy" ON public.patient_documents FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true AND staff_id = patient_documents.uploaded_by) AND public.can_current_staff_access_patient(patient_id));
CREATE POLICY "Update patient_documents policy" ON public.patient_documents FOR UPDATE TO authenticated USING (public.can_current_staff_access_patient(patient_id)) WITH CHECK (file_name = btrim(file_name) AND char_length(file_name) BETWEEN 1 AND 255 AND file_name !~ '[[:cntrl:]]' AND public.can_current_staff_access_patient(patient_id));
CREATE POLICY "Delete patient_documents policy" ON public.patient_documents FOR DELETE TO authenticated USING (public.can_current_staff_access_patient(patient_id));

REVOKE UPDATE ON TABLE public.patient_documents FROM authenticated;
GRANT UPDATE (file_name) ON TABLE public.patient_documents TO authenticated;

CREATE POLICY "Select patient_notes policy" ON public.patient_notes FOR SELECT TO authenticated USING (public.can_current_staff_access_patient(patient_id));
CREATE POLICY "Insert patient_notes policy" ON public.patient_notes FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true AND staff_id = patient_notes.created_by) AND public.can_current_staff_access_patient(patient_id));
CREATE POLICY "Update patient_notes policy" ON public.patient_notes FOR UPDATE TO authenticated USING (public.can_current_staff_access_patient(patient_id)) WITH CHECK (public.can_current_staff_access_patient(patient_id));
CREATE POLICY "Delete patient_notes policy" ON public.patient_notes FOR DELETE TO authenticated USING (public.can_current_staff_access_patient(patient_id));

CREATE POLICY "All active staff can view payment history logs" ON public.payment_records FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true));
CREATE POLICY "Only payment-enabled staff can record payments" ON public.payment_records FOR INSERT TO authenticated WITH CHECK (public.current_staff_can_manage_payments());
CREATE POLICY "Only payment-enabled staff can update payments" ON public.payment_records FOR UPDATE TO authenticated USING (public.current_staff_can_manage_payments()) WITH CHECK (public.current_staff_can_manage_payments());
CREATE POLICY "Only payment-enabled staff can delete payments" ON public.payment_records FOR DELETE TO authenticated USING (public.current_staff_can_manage_payments());

-- Condition Catalog Policies
CREATE POLICY "Active staff can read condition catalog" ON public.condition_catalog FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true));
CREATE POLICY "Super admins can manage condition catalog" ON public.condition_catalog FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_role = 'super_admin'::user_role AND staff_active = true));

-- Patient Medical History Policies
CREATE POLICY "Staff with patient access can read medical history" ON public.patient_medical_history FOR SELECT TO authenticated USING (public.can_current_staff_access_patient(patient_id));
CREATE POLICY "Senior doctors and admins can insert medical history" ON public.patient_medical_history FOR INSERT TO authenticated WITH CHECK (public.can_current_staff_modify_patient_programs(patient_id));
CREATE POLICY "Senior doctors and admins can update medical history" ON public.patient_medical_history FOR UPDATE TO authenticated USING (public.can_current_staff_modify_patient_programs(patient_id)) WITH CHECK (public.can_current_staff_modify_patient_programs(patient_id));
CREATE POLICY "Super admins can delete medical history" ON public.patient_medical_history FOR DELETE TO authenticated USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_role = 'super_admin'::user_role AND staff_active = true));

-- Patient Programs Policies
CREATE POLICY "Staff with patient access can read programs" ON public.patient_programs FOR SELECT TO authenticated USING (public.can_current_staff_access_patient(patient_id));
CREATE POLICY "Senior doctors and admins can insert programs" ON public.patient_programs FOR INSERT TO authenticated WITH CHECK (public.can_current_staff_modify_patient_programs(patient_id));
CREATE POLICY "Senior doctors and admins can update programs" ON public.patient_programs FOR UPDATE TO authenticated USING (public.can_current_staff_modify_patient_programs(patient_id)) WITH CHECK (public.can_current_staff_modify_patient_programs(patient_id));
CREATE POLICY "Super admins and senior doctors can delete programs" ON public.patient_programs FOR DELETE TO authenticated USING (public.can_current_staff_modify_patient_programs(patient_id));

-- Program Conditions Policies
CREATE POLICY "Staff with patient access can read program conditions" ON public.program_conditions FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.patient_programs p WHERE p.id = program_conditions.program_id AND public.can_current_staff_access_patient(p.patient_id)));
CREATE POLICY "Senior doctors and admins can manage program conditions" ON public.program_conditions FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.patient_programs p WHERE p.id = program_conditions.program_id AND public.can_current_staff_modify_patient_programs(p.patient_id)));

-- Treatment Plans Policies
CREATE POLICY "Staff with patient access can read treatment plans" ON public.treatment_plans FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.patient_programs p WHERE p.id = treatment_plans.program_id AND public.can_current_staff_access_patient(p.patient_id)));
CREATE POLICY "Senior doctors and admins can manage treatment plans" ON public.treatment_plans FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.patient_programs p WHERE p.id = treatment_plans.program_id AND public.can_current_staff_modify_patient_programs(p.patient_id)));

-- Plan Modalities Policies
CREATE POLICY "Staff with patient access can read plan modalities" ON public.plan_modalities FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.treatment_plans tp JOIN public.patient_programs p ON p.id = tp.program_id WHERE tp.id = plan_modalities.treatment_plan_id AND public.can_current_staff_access_patient(p.patient_id)));
CREATE POLICY "Senior doctors and admins can manage plan modalities" ON public.plan_modalities FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.treatment_plans tp JOIN public.patient_programs p ON p.id = tp.program_id WHERE tp.id = plan_modalities.treatment_plan_id AND public.can_current_staff_modify_patient_programs(p.patient_id)));

-- Modality Regions Policies
CREATE POLICY "Staff with patient access can read modality regions" ON public.modality_regions FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.plan_modalities pm JOIN public.treatment_plans tp ON tp.id = pm.treatment_plan_id JOIN public.patient_programs p ON p.id = tp.program_id WHERE pm.id = modality_regions.plan_modality_id AND public.can_current_staff_access_patient(p.patient_id)));
CREATE POLICY "Senior doctors and admins can manage modality regions" ON public.modality_regions FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM public.plan_modalities pm JOIN public.treatment_plans tp ON tp.id = pm.treatment_plan_id JOIN public.patient_programs p ON p.id = tp.program_id WHERE pm.id = modality_regions.plan_modality_id AND public.can_current_staff_modify_patient_programs(p.patient_id)));

-- Storage Configuration & Policies
INSERT INTO storage.buckets (id, name, public) VALUES ('patient-documents', 'patient-documents', false) ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Select storage_objects policy" ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'patient-documents' AND (EXISTS (SELECT 1 FROM public.staff s WHERE s.user_id = auth.uid() AND s.is_active = true AND (s.role IN ('super_admin'::public.user_role, 'receptionist'::public.user_role) OR (s.role = 'doctor'::public.user_role AND s.is_senior = true))) OR (path_tokens[1] ~ '^[0-9a-fA-F-]{36}$' AND public.can_current_staff_access_patient(path_tokens[1]::uuid))));
CREATE POLICY "Insert storage_objects policy" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'patient-documents' AND (EXISTS (SELECT 1 FROM public.staff s WHERE s.user_id = auth.uid() AND s.is_active = true AND (s.role IN ('super_admin'::public.user_role, 'receptionist'::public.user_role) OR (s.role = 'doctor'::public.user_role AND s.is_senior = true))) OR (path_tokens[1] ~ '^[0-9a-fA-F-]{36}$' AND public.can_current_staff_access_patient(path_tokens[1]::uuid))));
CREATE POLICY "Update storage_objects policy" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'patient-documents' AND (EXISTS (SELECT 1 FROM public.staff s WHERE s.user_id = auth.uid() AND s.is_active = true AND (s.role IN ('super_admin'::public.user_role, 'receptionist'::public.user_role) OR (s.role = 'doctor'::public.user_role AND s.is_senior = true))) OR (path_tokens[1] ~ '^[0-9a-fA-F-]{36}$' AND public.can_current_staff_access_patient(path_tokens[1]::uuid))));
CREATE POLICY "Delete storage_objects policy" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'patient-documents' AND (EXISTS (SELECT 1 FROM public.staff s WHERE s.user_id = auth.uid() AND s.is_active = true AND (s.role IN ('super_admin'::public.user_role, 'receptionist'::public.user_role) OR (s.role = 'doctor'::public.user_role AND s.is_senior = true))) OR (path_tokens[1] ~ '^[0-9a-fA-F-]{36}$' AND public.can_current_staff_access_patient(path_tokens[1]::uuid))));

-- Seed Condition Catalog Data
INSERT INTO public.condition_catalog (region, condition_name, display_order) VALUES
  -- Shoulder (16)
  ('shoulder', 'Shoulder impingement syndrome', 1),
  ('shoulder', 'Rotator cuff tendinopathy', 2),
  ('shoulder', 'Subacromial bursitis', 3),
  ('shoulder', 'Long head of biceps tendinopathy', 4),
  ('shoulder', 'Glenohumeral OA', 5),
  ('shoulder', 'AC OA', 6),
  ('shoulder', 'Frozen Shoulder', 7),
  ('shoulder', 'Shoulder instability', 8),
  ('shoulder', 'Shoulder dislocation', 9),
  ('shoulder', 'Labral tear', 10),
  ('shoulder', 'SLAP lesion', 11),
  ('shoulder', 'Bankart lesion', 12),
  ('shoulder', 'Calcific tendinopathy', 13),
  ('shoulder', 'Fracture', 14),
  ('shoulder', 'Muscle strain', 15),
  ('shoulder', 'Post-operation Rehabilitation', 16),

  -- Hand (8)
  ('hand', 'De Quervain''s', 1),
  ('hand', 'Trigger fingers', 2),
  ('hand', 'Wrist sprain', 3),
  ('hand', 'Scapholunate ligament injury', 4),
  ('hand', 'TFCC injury', 5),
  ('hand', 'Ganglion cyst', 6),
  ('hand', 'Distal radius fracture', 7),
  ('hand', 'Post-operative rehabilitation', 8),

  -- Lumbar Spine (15)
  ('lumbar_spine', 'Lumbar disc herniation L1-L2', 1),
  ('lumbar_spine', 'Lumbar disc herniation L2-L3', 2),
  ('lumbar_spine', 'Lumbar disc herniation L3-L4', 3),
  ('lumbar_spine', 'Lumbar disc herniation L4-L5', 4),
  ('lumbar_spine', 'Lumbar disc herniation L5-S1', 5),
  ('lumbar_spine', 'Lumbar canal stenosis', 6),
  ('lumbar_spine', 'Foraminal stenosis', 7),
  ('lumbar_spine', 'Spondylosis', 8),
  ('lumbar_spine', 'Facet arthropathy', 9),
  ('lumbar_spine', 'Spondylolisthesis', 10),
  ('lumbar_spine', 'Clinical spinal instability', 11),
  ('lumbar_spine', 'SIJ', 12),
  ('lumbar_spine', 'Lumbar muscle strain', 13),
  ('lumbar_spine', 'Vertebral fracture', 14),
  ('lumbar_spine', 'Post-surgical Rehabilitation', 15),

  -- Thoracic Spine (10)
  ('thoracic_spine', 'Thoracic disc herniation', 1),
  ('thoracic_spine', 'Facet arthropathy', 2),
  ('thoracic_spine', 'Scheuermann''s kyphosis', 3),
  ('thoracic_spine', 'Thoracic hyperkyphosis cause complications', 4),
  ('thoracic_spine', 'Thoracic Scoliosis', 5),
  ('thoracic_spine', 'Costovertebral dysfunction', 6),
  ('thoracic_spine', 'Vertebral fracture', 7),
  ('thoracic_spine', 'Rib fracture', 8),
  ('thoracic_spine', 'Interosseous muscle strain', 9),
  ('thoracic_spine', 'Post surgical Rehabilitation', 10),

  -- Cervical Spine (14)
  ('cervical_spine', 'Cervical disc herniation C2-C3', 1),
  ('cervical_spine', 'Cervical disc herniation C3-C4', 2),
  ('cervical_spine', 'Cervical disc herniation C4-C5', 3),
  ('cervical_spine', 'Cervical disc herniation C5-C6', 4),
  ('cervical_spine', 'Cervical disc herniation C6-C7', 5),
  ('cervical_spine', 'Spondylosis', 6),
  ('cervical_spine', 'Spinal stenosis', 7),
  ('cervical_spine', 'Facet locking', 8),
  ('cervical_spine', 'Cervical myelopathy', 9),
  ('cervical_spine', 'C.S.T', 10),
  ('cervical_spine', 'Cervicogenic headache', 11),
  ('cervical_spine', 'Cervicogenic Dizziness', 12),
  ('cervical_spine', 'Cervicogenic tinnitus', 13),
  ('cervical_spine', 'Post surgical Rehabilitation', 14),

  -- Hip Joint (14)
  ('hip_joint', 'Hip OA', 1),
  ('hip_joint', 'Hip FAI', 2),
  ('hip_joint', 'Acetabular labral tear', 3),
  ('hip_joint', 'Greater trochanteric pain syndrome', 4),
  ('hip_joint', 'Trochanteric bursitis', 5),
  ('hip_joint', 'Proximal hamstring tendinopathy', 6),
  ('hip_joint', 'Adductor strain', 7),
  ('hip_joint', 'Hamstring strain', 8),
  ('hip_joint', 'AVN', 9),
  ('hip_joint', 'Femoral neck stress fracture', 10),
  ('hip_joint', 'Athletic pubalgia', 11),
  ('hip_joint', 'THA', 12),
  ('hip_joint', 'Post fracture rehabilitation', 13),
  ('hip_joint', 'Osteitis pubis', 14),

  -- Knee Joint (16)
  ('knee_joint', 'Knee OA (Right)', 1),
  ('knee_joint', 'Knee OA (Left)', 2),
  ('knee_joint', 'Patellofemoral OA (Right)', 3),
  ('knee_joint', 'Patellofemoral OA (Left)', 4),
  ('knee_joint', 'Patellar tendinopathy', 5),
  ('knee_joint', 'Quadriceps strain', 6),
  ('knee_joint', 'ITBS', 7),
  ('knee_joint', 'ACL partial tear', 8),
  ('knee_joint', 'ACL complete tear', 9),
  ('knee_joint', 'PHMM tear', 10),
  ('knee_joint', 'Patellar instability', 11),
  ('knee_joint', 'Patellar maltracking', 12),
  ('knee_joint', 'Osteochondral lesion', 13),
  ('knee_joint', 'Post operation Rehabilitation', 14),
  ('knee_joint', 'Post operation Fixation', 15),
  ('knee_joint', 'Osgood-Schlatter syndrome', 16),

  -- Ankle Joint (11)
  ('ankle_joint', 'Lateral ankle sprain', 1),
  ('ankle_joint', 'Medial ankle sprain', 2),
  ('ankle_joint', 'Syndesmotic injury', 3),
  ('ankle_joint', 'Chronic ankle instability', 4),
  ('ankle_joint', 'Achilles tendinopathy', 5),
  ('ankle_joint', 'Achilles tendon tear', 6),
  ('ankle_joint', 'Peroneal tendon subluxation', 7),
  ('ankle_joint', 'Ankle OA', 8),
  ('ankle_joint', 'Ankle impingement syndrome', 9),
  ('ankle_joint', 'Osteochondral lesion', 10),
  ('ankle_joint', 'Haglund''s deformity', 11),

  -- Foot (4)
  ('foot', 'Plantar fasciitis', 1),
  ('foot', 'Calcaneal spur', 2),
  ('foot', 'Metatarsalgia', 3),
  ('foot', 'Stress fracture', 4)
ON CONFLICT (region, condition_name) DO NOTHING;

-- Table Grants for authenticated role
-- RLS policies only work on top of base table-level GRANT privileges.
GRANT SELECT, INSERT, UPDATE, DELETE ON public.patient_medical_history TO authenticated;
GRANT SELECT ON public.condition_catalog TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.patient_programs TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.program_conditions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.treatment_plans TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.plan_modalities TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.modality_regions TO authenticated;
