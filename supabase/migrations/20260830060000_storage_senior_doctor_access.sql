-- ============================================================================
-- Migration: 20260830060000_storage_senior_doctor_access.sql
-- Description: Grant Senior Doctors access to storage.objects for patient-documents,
--              matching the patient_documents table RLS policies.
-- ============================================================================

DROP POLICY IF EXISTS "Select storage_objects policy" ON storage.objects;
DROP POLICY IF EXISTS "Insert storage_objects policy" ON storage.objects;
DROP POLICY IF EXISTS "Update storage_objects policy" ON storage.objects;
DROP POLICY IF EXISTS "Delete storage_objects policy" ON storage.objects;

CREATE POLICY "Select storage_objects policy" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'patient-documents'
    AND (
      EXISTS (
        SELECT 1 FROM public.staff s
        WHERE s.user_id = auth.uid()
          AND s.is_active = true
          AND (
            s.role IN ('super_admin'::public.user_role, 'receptionist'::public.user_role)
            OR (s.role = 'doctor'::public.user_role AND s.is_senior = true)
          )
      )
      OR (
        path_tokens[1] ~ '^[0-9a-fA-F-]{36}$'
        AND public.can_current_staff_access_patient(path_tokens[1]::uuid)
      )
    )
  );

CREATE POLICY "Insert storage_objects policy" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'patient-documents'
    AND (
      EXISTS (
        SELECT 1 FROM public.staff s
        WHERE s.user_id = auth.uid()
          AND s.is_active = true
          AND (
            s.role IN ('super_admin'::public.user_role, 'receptionist'::public.user_role)
            OR (s.role = 'doctor'::public.user_role AND s.is_senior = true)
          )
      )
      OR (
        path_tokens[1] ~ '^[0-9a-fA-F-]{36}$'
        AND public.can_current_staff_access_patient(path_tokens[1]::uuid)
      )
    )
  );

CREATE POLICY "Update storage_objects policy" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'patient-documents'
    AND (
      EXISTS (
        SELECT 1 FROM public.staff s
        WHERE s.user_id = auth.uid()
          AND s.is_active = true
          AND (
            s.role IN ('super_admin'::public.user_role, 'receptionist'::public.user_role)
            OR (s.role = 'doctor'::public.user_role AND s.is_senior = true)
          )
      )
      OR (
        path_tokens[1] ~ '^[0-9a-fA-F-]{36}$'
        AND public.can_current_staff_access_patient(path_tokens[1]::uuid)
      )
    )
  );

CREATE POLICY "Delete storage_objects policy" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'patient-documents'
    AND (
      EXISTS (
        SELECT 1 FROM public.staff s
        WHERE s.user_id = auth.uid()
          AND s.is_active = true
          AND (
            s.role IN ('super_admin'::public.user_role, 'receptionist'::public.user_role)
            OR (s.role = 'doctor'::public.user_role AND s.is_senior = true)
          )
      )
      OR (
        path_tokens[1] ~ '^[0-9a-fA-F-]{36}$'
        AND public.can_current_staff_access_patient(path_tokens[1]::uuid)
      )
    )
  );
