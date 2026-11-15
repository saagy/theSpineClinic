-- A visit the patient did not come to. It uses no session and is not a
-- pending visit any more. Added on its own so later migrations can use it.
ALTER TYPE public.appointment_status ADD VALUE IF NOT EXISTS 'no_show';
