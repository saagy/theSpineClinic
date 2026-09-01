-- Migration: 20260901000000_add_treatment_modalities.sql
-- Description: Add new modalities (release, met, mobilization, mulligan, exercise) to modality_type enum.

ALTER TYPE public.modality_type ADD VALUE IF NOT EXISTS 'release';
ALTER TYPE public.modality_type ADD VALUE IF NOT EXISTS 'met';
ALTER TYPE public.modality_type ADD VALUE IF NOT EXISTS 'mobilization';
ALTER TYPE public.modality_type ADD VALUE IF NOT EXISTS 'mulligan';
ALTER TYPE public.modality_type ADD VALUE IF NOT EXISTS 'exercise';
