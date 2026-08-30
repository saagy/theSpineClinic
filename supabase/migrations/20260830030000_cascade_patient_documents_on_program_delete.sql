-- Migration: Update patient_documents.program_id FK to ON DELETE CASCADE
ALTER TABLE public.patient_documents
  DROP CONSTRAINT IF EXISTS patient_documents_program_id_fkey;

ALTER TABLE public.patient_documents
  ADD CONSTRAINT patient_documents_program_id_fkey
    FOREIGN KEY (program_id)
    REFERENCES public.patient_programs(id)
    ON DELETE CASCADE;
