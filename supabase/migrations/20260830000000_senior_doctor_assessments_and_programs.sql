-- =============================================================================
-- Migration: Senior Doctor Assessments, Medical History, Programs, & Treatment Plans
-- =============================================================================

-- 1. Custom Enum Types
DO $$ BEGIN
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
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE public.program_status AS ENUM (
    'active',
    'completed',
    'archived'
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE public.modality_type AS ENUM (
    'muscle_pain',
    'mass_built',
    'tecar',
    'tecar_focal',
    'neurodynamic_non_wb',
    'neurodynamic_wb'
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE public.laterality AS ENUM (
    'right',
    'left',
    'both'
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- 2. Clean up 'check_up' appointments by migrating to 'reassessment'
UPDATE public.appointments
   SET type = 'reassessment'::public.appointment_type
 WHERE type::text = 'check_up';

-- 3. Staff table enhancement (is_senior flag)
ALTER TABLE public.staff
  ADD COLUMN IF NOT EXISTS is_senior boolean NOT NULL DEFAULT false;

-- 4. Create Tables

-- Medical History (1:1 with patients)
CREATE TABLE IF NOT EXISTS public.patient_medical_history (
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

-- Condition Catalog (Reference / Seed Table)
CREATE TABLE IF NOT EXISTS public.condition_catalog (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  region         public.body_region NOT NULL,
  condition_name text NOT NULL,
  display_order  integer NOT NULL DEFAULT 0,
  created_at     timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT unique_region_condition UNIQUE (region, condition_name)
);
ALTER TABLE public.condition_catalog ENABLE ROW LEVEL SECURITY;

-- Patient Programs (1:N with patients)
CREATE TABLE IF NOT EXISTS public.patient_programs (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id             uuid NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  created_by             uuid NOT NULL REFERENCES public.staff(id) ON DELETE RESTRICT,
  status                 public.program_status NOT NULL DEFAULT 'active'::public.program_status,
  examination            text,
  imaging_notes          text,
  exacerbating_positions text,
  relieving_positions    text,
  notes                  text,
  created_at             timestamptz NOT NULL DEFAULT now(),
  updated_at             timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.patient_programs ENABLE ROW LEVEL SECURITY;

-- Program Conditions Junction (N:N program <-> condition_catalog)
CREATE TABLE IF NOT EXISTS public.program_conditions (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id   uuid NOT NULL REFERENCES public.patient_programs(id) ON DELETE CASCADE,
  condition_id uuid NOT NULL REFERENCES public.condition_catalog(id) ON DELETE CASCADE,
  CONSTRAINT unique_program_condition UNIQUE (program_id, condition_id)
);
ALTER TABLE public.program_conditions ENABLE ROW LEVEL SECURITY;

-- Treatment Plans (1:N with patient_programs)
CREATE TABLE IF NOT EXISTS public.treatment_plans (
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

-- Plan Modalities (1:N with treatment_plans)
CREATE TABLE IF NOT EXISTS public.plan_modalities (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  treatment_plan_id uuid NOT NULL REFERENCES public.treatment_plans(id) ON DELETE CASCADE,
  modality_type     public.modality_type NOT NULL,
  notes             text,
  CONSTRAINT unique_plan_modality UNIQUE (treatment_plan_id, modality_type)
);
ALTER TABLE public.plan_modalities ENABLE ROW LEVEL SECURITY;

-- Modality Regions (1:N with plan_modalities for multi-region configurations)
CREATE TABLE IF NOT EXISTS public.modality_regions (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_modality_id uuid NOT NULL REFERENCES public.plan_modalities(id) ON DELETE CASCADE,
  target_region    text NOT NULL,
  laterality       public.laterality,
  time_minutes     integer NOT NULL DEFAULT 15
);
ALTER TABLE public.modality_regions ENABLE ROW LEVEL SECURITY;

-- 5. Alter patient_documents to optionally link to a program
ALTER TABLE public.patient_documents
  ADD COLUMN IF NOT EXISTS program_id uuid REFERENCES public.patient_programs(id) ON DELETE SET NULL;

-- 6. Indexes
CREATE INDEX IF NOT EXISTS idx_medical_history_patient ON public.patient_medical_history(patient_id);
CREATE INDEX IF NOT EXISTS idx_condition_catalog_region ON public.condition_catalog(region, display_order);
CREATE INDEX IF NOT EXISTS idx_patient_programs_patient ON public.patient_programs(patient_id, status);
CREATE INDEX IF NOT EXISTS idx_program_conditions_program ON public.program_conditions(program_id);
CREATE INDEX IF NOT EXISTS idx_treatment_plans_program ON public.treatment_plans(program_id, is_active);
CREATE INDEX IF NOT EXISTS idx_plan_modalities_plan ON public.plan_modalities(treatment_plan_id);
CREATE INDEX IF NOT EXISTS idx_modality_regions_modality ON public.modality_regions(plan_modality_id);
CREATE INDEX IF NOT EXISTS idx_patient_documents_program ON public.patient_documents(program_id);

-- 7. Helper Functions for Security & Permissions

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

-- 8. Row Level Security Policies

-- Condition Catalog Policies
DO $$ BEGIN
  CREATE POLICY "Active staff can read condition catalog"
    ON public.condition_catalog FOR SELECT TO authenticated
    USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active = true));
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE POLICY "Super admins can manage condition catalog"
    ON public.condition_catalog FOR ALL TO authenticated
    USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_role = 'super_admin'::public.user_role AND staff_active = true));
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Patient Medical History Policies
DO $$ BEGIN
  CREATE POLICY "Staff with patient access can read medical history"
    ON public.patient_medical_history FOR SELECT TO authenticated
    USING (public.can_current_staff_access_patient(patient_id));
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE POLICY "Senior doctors and admins can insert medical history"
    ON public.patient_medical_history FOR INSERT TO authenticated
    WITH CHECK (public.can_current_staff_modify_patient_programs(patient_id));
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE POLICY "Senior doctors and admins can update medical history"
    ON public.patient_medical_history FOR UPDATE TO authenticated
    USING (public.can_current_staff_modify_patient_programs(patient_id))
    WITH CHECK (public.can_current_staff_modify_patient_programs(patient_id));
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE POLICY "Super admins can delete medical history"
    ON public.patient_medical_history FOR DELETE TO authenticated
    USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_role = 'super_admin'::public.user_role AND staff_active = true));
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Patient Programs Policies
DO $$ BEGIN
  CREATE POLICY "Staff with patient access can read programs"
    ON public.patient_programs FOR SELECT TO authenticated
    USING (public.can_current_staff_access_patient(patient_id));
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE POLICY "Senior doctors and admins can insert programs"
    ON public.patient_programs FOR INSERT TO authenticated
    WITH CHECK (public.can_current_staff_modify_patient_programs(patient_id));
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE POLICY "Senior doctors and admins can update programs"
    ON public.patient_programs FOR UPDATE TO authenticated
    USING (public.can_current_staff_modify_patient_programs(patient_id))
    WITH CHECK (public.can_current_staff_modify_patient_programs(patient_id));
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE POLICY "Super admins and senior doctors can delete programs"
    ON public.patient_programs FOR DELETE TO authenticated
    USING (public.can_current_staff_modify_patient_programs(patient_id));
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Program Conditions Policies
DO $$ BEGIN
  CREATE POLICY "Staff with patient access can read program conditions"
    ON public.program_conditions FOR SELECT TO authenticated
    USING (EXISTS (
      SELECT 1 FROM public.patient_programs p
      WHERE p.id = program_conditions.program_id
        AND public.can_current_staff_access_patient(p.patient_id)
    ));
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE POLICY "Senior doctors and admins can manage program conditions"
    ON public.program_conditions FOR ALL TO authenticated
    USING (EXISTS (
      SELECT 1 FROM public.patient_programs p
      WHERE p.id = program_conditions.program_id
        AND public.can_current_staff_modify_patient_programs(p.patient_id)
    ));
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Treatment Plans Policies
DO $$ BEGIN
  CREATE POLICY "Staff with patient access can read treatment plans"
    ON public.treatment_plans FOR SELECT TO authenticated
    USING (EXISTS (
      SELECT 1 FROM public.patient_programs p
      WHERE p.id = treatment_plans.program_id
        AND public.can_current_staff_access_patient(p.patient_id)
    ));
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE POLICY "Senior doctors and admins can manage treatment plans"
    ON public.treatment_plans FOR ALL TO authenticated
    USING (EXISTS (
      SELECT 1 FROM public.patient_programs p
      WHERE p.id = treatment_plans.program_id
        AND public.can_current_staff_modify_patient_programs(p.patient_id)
    ));
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Plan Modalities Policies
DO $$ BEGIN
  CREATE POLICY "Staff with patient access can read plan modalities"
    ON public.plan_modalities FOR SELECT TO authenticated
    USING (EXISTS (
      SELECT 1 FROM public.treatment_plans tp
      JOIN public.patient_programs p ON p.id = tp.program_id
      WHERE tp.id = plan_modalities.treatment_plan_id
        AND public.can_current_staff_access_patient(p.patient_id)
    ));
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE POLICY "Senior doctors and admins can manage plan modalities"
    ON public.plan_modalities FOR ALL TO authenticated
    USING (EXISTS (
      SELECT 1 FROM public.treatment_plans tp
      JOIN public.patient_programs p ON p.id = tp.program_id
      WHERE tp.id = plan_modalities.treatment_plan_id
        AND public.can_current_staff_modify_patient_programs(p.patient_id)
    ));
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Modality Regions Policies
DO $$ BEGIN
  CREATE POLICY "Staff with patient access can read modality regions"
    ON public.modality_regions FOR SELECT TO authenticated
    USING (EXISTS (
      SELECT 1 FROM public.plan_modalities pm
      JOIN public.treatment_plans tp ON tp.id = pm.treatment_plan_id
      JOIN public.patient_programs p ON p.id = tp.program_id
      WHERE pm.id = modality_regions.plan_modality_id
        AND public.can_current_staff_access_patient(p.patient_id)
    ));
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE POLICY "Senior doctors and admins can manage modality regions"
    ON public.modality_regions FOR ALL TO authenticated
    USING (EXISTS (
      SELECT 1 FROM public.plan_modalities pm
      JOIN public.treatment_plans tp ON tp.id = pm.treatment_plan_id
      JOIN public.patient_programs p ON p.id = tp.program_id
      WHERE pm.id = modality_regions.plan_modality_id
        AND public.can_current_staff_modify_patient_programs(p.patient_id)
    ));
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- 9. Seed Condition Catalog Data
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
  ('knee_joint', 'Knee OA Rt', 1),
  ('knee_joint', 'Knee OA Lt', 2),
  ('knee_joint', 'Patellofemoral OA Rt', 3),
  ('knee_joint', 'Patellofemoral OA Lt', 4),
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

-- 10. Table Grants for authenticated role
-- RLS policies only work on top of base table-level GRANT privileges.
GRANT SELECT, INSERT, UPDATE, DELETE ON public.patient_medical_history TO authenticated;
GRANT SELECT ON public.condition_catalog TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.patient_programs TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.program_conditions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.treatment_plans TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.plan_modalities TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.modality_regions TO authenticated;
