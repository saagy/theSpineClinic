-- ============================================================================
-- Migration: 20260830040000_senior_doctor_patient_access_rls.sql
-- Description: Unify patient, document, and note RLS policies using
--              can_current_staff_access_patient to grant Senior Doctors
--              unconditional access to view all clinic patients.
-- ============================================================================

-- 1. Patients RLS
DROP POLICY IF EXISTS "Doctors can view assigned or appointment patients" ON public.patients;
DROP POLICY IF EXISTS "Doctors can update assigned or appointment patients" ON public.patients;
DROP POLICY IF EXISTS "Staff can view accessible patients" ON public.patients;
DROP POLICY IF EXISTS "Staff can update accessible patients" ON public.patients;

CREATE POLICY "Staff can view accessible patients" ON public.patients
  FOR SELECT TO authenticated
  USING (public.can_current_staff_access_patient(id));

CREATE POLICY "Staff can update accessible patients" ON public.patients
  FOR UPDATE TO authenticated
  USING (public.can_current_staff_access_patient(id))
  WITH CHECK (public.can_current_staff_access_patient(id));

-- 2. Patient Documents RLS
DROP POLICY IF EXISTS "Select patient_documents policy" ON public.patient_documents;
DROP POLICY IF EXISTS "Insert patient_documents policy" ON public.patient_documents;
DROP POLICY IF EXISTS "Update patient_documents policy" ON public.patient_documents;
DROP POLICY IF EXISTS "Delete patient_documents policy" ON public.patient_documents;

CREATE POLICY "Select patient_documents policy" ON public.patient_documents
  FOR SELECT TO authenticated
  USING (public.can_current_staff_access_patient(patient_id));

CREATE POLICY "Insert patient_documents policy" ON public.patient_documents
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.get_auth_staff_profile()
      WHERE staff_active = true AND staff_id = patient_documents.uploaded_by
    )
    AND public.can_current_staff_access_patient(patient_id)
  );

CREATE POLICY "Update patient_documents policy" ON public.patient_documents
  FOR UPDATE TO authenticated
  USING (public.can_current_staff_access_patient(patient_id))
  WITH CHECK (
    file_name = btrim(file_name)
    AND char_length(file_name) BETWEEN 1 AND 255
    AND file_name !~ '[[:cntrl:]]'
    AND public.can_current_staff_access_patient(patient_id)
  );

CREATE POLICY "Delete patient_documents policy" ON public.patient_documents
  FOR DELETE TO authenticated
  USING (public.can_current_staff_access_patient(patient_id));

-- 3. Patient Notes RLS
DROP POLICY IF EXISTS "Select patient_notes policy" ON public.patient_notes;
DROP POLICY IF EXISTS "Insert patient_notes policy" ON public.patient_notes;
DROP POLICY IF EXISTS "Update patient_notes policy" ON public.patient_notes;
DROP POLICY IF EXISTS "Delete patient_notes policy" ON public.patient_notes;

CREATE POLICY "Select patient_notes policy" ON public.patient_notes
  FOR SELECT TO authenticated
  USING (public.can_current_staff_access_patient(patient_id));

CREATE POLICY "Insert patient_notes policy" ON public.patient_notes
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.get_auth_staff_profile()
      WHERE staff_active = true AND staff_id = patient_notes.created_by
    )
    AND public.can_current_staff_access_patient(patient_id)
  );

CREATE POLICY "Update patient_notes policy" ON public.patient_notes
  FOR UPDATE TO authenticated
  USING (public.can_current_staff_access_patient(patient_id))
  WITH CHECK (public.can_current_staff_access_patient(patient_id));

CREATE POLICY "Delete patient_notes policy" ON public.patient_notes
  FOR DELETE TO authenticated
  USING (public.can_current_staff_access_patient(patient_id));
