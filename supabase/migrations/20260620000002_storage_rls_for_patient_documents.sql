-- Migration: Storage RLS for the patient-documents bucket.
--
-- Single guard: caller must be an authenticated staff member with
-- is_active = true. Returns 4xx for unauthenticated callers, idle
-- accounts, and accounts flagged inactive.
--
-- FOR ALL covers SELECT, INSERT, UPDATE, DELETE on storage.objects.
-- USING controls visibility of existing rows (SELECT / DELETE / UPDATE).
-- WITH CHECK controls what new rows can contain (INSERT / UPDATE).
-- Both clauses repeat the same guard because INSERT has no existing
-- row to test against — so WITH CHECK is what enforces the policy
-- for new objects.

CREATE POLICY "Active staff have full access to patient-documents"
ON storage.objects
FOR ALL TO authenticated
USING (
  bucket_id = 'patient-documents'
  AND EXISTS (
    SELECT 1 FROM public.get_auth_staff_profile()
    WHERE staff_active = true
  )
)
WITH CHECK (
  bucket_id = 'patient-documents'
  AND EXISTS (
    SELECT 1 FROM public.get_auth_staff_profile()
    WHERE staff_active = true
  )
);

-- Defense-in-depth: explicitly mark the bucket private so that any
-- unauthenticated URL cached or copied in error returns 403.
UPDATE storage.buckets
SET public = false
WHERE id = 'patient-documents';
