-- Migration: fix document delete RLS for doctors + clean up broken records.
--
-- Root cause: the table `DELETE` policy on `patient_documents`
-- restricted to super_admin/receptionist, while an old broad `FOR ALL`
-- storage policy OR'-rided into the new DELETE policy and let any
-- active staff delete blobs. The client deleted blobs BEFORE the DB
-- row — so doctors could nuke the storage object before the DB DELETE
-- threw — leaving broken visible records.
--
-- The fix:
--   1. Drop the old broad storage policy.
--   2. Replace the table DELETE policy: any active staff, doctors
--      limited to patients they can view (same access check as SELECT).
--   3. Replace the storage DELETE policy: same logic but keyed on
--      `path_tokens[1]` (the patient folder name in the object path).
--   4. Delete the broken `patient_documents` rows whose storage blob
--      was already removed by the bug.
--
-- After this migration: any active staff who can VIEW a patient's
-- documents can also DELETE them. Doctors see documents for assigned,
-- replacement, and active-appointment patients; super_admin/receptionist
-- see ALL.
--
-- Orphan blobs in storage (blobs with no DB row) cannot be removed
-- directly via SQL — Supabase protects deletion of `storage.objects`.
-- The client-side `deletePatientStorageFolder` sweeps them up the next
-- time the affected patient is deleted.

-- Step 1: Drop the old broad storage policy.
DROP POLICY IF EXISTS "Active staff have full access to patient-documents"
  ON storage.objects;

-- Step 2: Replace the table DELETE policy.
DROP POLICY IF EXISTS "Delete patient_documents policy" ON public.patient_documents;
CREATE POLICY "Delete patient_documents policy" ON public.patient_documents
FOR DELETE TO authenticated USING (
  EXISTS (
    SELECT 1 FROM get_auth_staff_profile()
    WHERE staff_active = true
    AND (
      staff_role IN ('super_admin'::user_role, 'receptionist'::user_role)
      OR (
        staff_role = 'doctor'::user_role
        AND (
          patient_id IN (
            SELECT pd.patient_id FROM patient_doctors pd
            WHERE pd.doctor_id = get_auth_staff_profile.staff_id
          )
          OR patient_id IN (
            SELECT pd.patient_id
            FROM patient_doctors pd
            JOIN doctor_replacements dr ON dr.absent_doctor_id = pd.doctor_id
            WHERE dr.covering_doctor_id = get_auth_staff_profile.staff_id
            AND dr.replacement_date = CURRENT_DATE
          )
          OR patient_id IN (
            SELECT a.patient_id
            FROM appointments a
            JOIN appointment_doctors ad ON ad.appointment_id = a.id
            WHERE ad.doctor_id = get_auth_staff_profile.staff_id
            AND ad.is_active = true
          )
          OR patient_id IN (
            SELECT a.patient_id
            FROM appointments a
            JOIN appointment_doctors ad ON ad.appointment_id = a.id
            JOIN doctor_replacements dr ON dr.absent_doctor_id = ad.doctor_id
            WHERE dr.covering_doctor_id = get_auth_staff_profile.staff_id
            AND dr.replacement_date = CURRENT_DATE
            AND ad.is_active = true
          )
        )
      )
    )
  )
);

-- Step 3: Replace the storage DELETE policy on storage.objects for the
-- patient-documents bucket. Same doctor access pattern expressed via
-- `path_tokens[1]` (1-based Supabase path array; first segment is the
-- patient folder name).
DROP POLICY IF EXISTS "Delete storage_objects policy" ON storage.objects;
CREATE POLICY "Delete storage_objects policy" ON storage.objects
FOR DELETE TO authenticated USING (
  bucket_id = 'patient-documents'
  AND EXISTS (
    SELECT 1 FROM get_auth_staff_profile()
    WHERE staff_active = true
    AND (
      staff_role IN ('super_admin'::user_role, 'receptionist'::user_role)
      OR (
        staff_role = 'doctor'::user_role
        AND (
          objects.path_tokens[1] IN (
            SELECT pd.patient_id::text FROM patient_doctors pd
            WHERE pd.doctor_id = get_auth_staff_profile.staff_id
          )
          OR objects.path_tokens[1] IN (
            SELECT pd.patient_id::text
            FROM patient_doctors pd
            JOIN doctor_replacements dr ON dr.absent_doctor_id = pd.doctor_id
            WHERE dr.covering_doctor_id = get_auth_staff_profile.staff_id
            AND dr.replacement_date = CURRENT_DATE
          )
          OR objects.path_tokens[1] IN (
            SELECT a.patient_id::text
            FROM appointments a
            JOIN appointment_doctors ad ON ad.appointment_id = a.id
            WHERE ad.doctor_id = get_auth_staff_profile.staff_id
            AND ad.is_active = true
          )
          OR objects.path_tokens[1] IN (
            SELECT a.patient_id::text
            FROM appointments a
            JOIN appointment_doctors ad ON ad.appointment_id = a.id
            JOIN doctor_replacements dr ON dr.absent_doctor_id = ad.doctor_id
            WHERE dr.covering_doctor_id = get_auth_staff_profile.staff_id
            AND dr.replacement_date = CURRENT_DATE
            AND ad.is_active = true
          )
        )
      )
    )
  )
);

-- Step 4: Delete the broken patient_documents rows whose blob is gone.
DELETE FROM patient_documents
WHERE NOT EXISTS (
  SELECT 1 FROM storage.objects so
  WHERE so.bucket_id = 'patient-documents'
    AND so.name = split_part(replace(file_url, '%2F', '/'), 'patient-documents/', 2)
);
