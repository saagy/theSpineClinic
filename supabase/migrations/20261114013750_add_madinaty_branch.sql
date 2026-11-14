-- Adds the Madinaty branch. Branch-scoped data (patients, staff, invoices,
-- document number series) already keys on clinic_location, and
-- billing_next_number starts a new series on first use, so no other change
-- is needed. Enum values cannot be removed once added.
ALTER TYPE public.clinic_location ADD VALUE IF NOT EXISTS 'madinaty';
