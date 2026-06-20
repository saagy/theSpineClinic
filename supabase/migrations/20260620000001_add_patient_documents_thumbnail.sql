-- Migration: add optional thumbnail_url to public.patient_documents.
--
-- Phase 1 cost-reduction work — populated by the Flutter upload pipeline
-- for any image upload. PDF rows and legacy image rows stay NULL.
--
-- Nullable column: existing rows are valid without modification.
-- New rows are inserted with the thumbnail URL alongside the full URL.

ALTER TABLE public.patient_documents
  ADD COLUMN IF NOT EXISTS thumbnail_url TEXT;

COMMENT ON COLUMN public.patient_documents.thumbnail_url IS
  'Optional URL to a 320x320 JPEG thumbnail used in list views to minimize bandwidth.';
