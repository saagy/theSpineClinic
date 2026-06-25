-- Migration: Add deactivated_at timestamp to disambiguate pending vs deactivated staff
--
-- Problem: is_active = false was overloaded — it meant both "pending admin approval"
-- (self-registered) and "deactivated by admin" (toggled off). The admin pending-
-- applications query returned all inactive staff, causing deactivated doctors to
-- reappear in the registration requests list with Approve/Reject buttons.
--
-- Solution: Add deactivated_at timestamptz NULL.
--   is_active = false AND deactivated_at IS NULL  → pending (new self-registration)
--   is_active = false AND deactivated_at IS NOT NULL → deactivated (admin toggled off)
--   is_active = true → active (unchanged)
--
-- All existing is_active = true login/RLS/RPC gates remain untouched.

ALTER TABLE public.staff ADD COLUMN IF NOT EXISTS deactivated_at timestamptz DEFAULT NULL;

-- Backfill: mark all currently-inactive rows as deactivated.
-- This immediately removes deactivated staff from the pending list.
UPDATE public.staff SET deactivated_at = now() WHERE is_active = false AND deactivated_at IS NULL;
