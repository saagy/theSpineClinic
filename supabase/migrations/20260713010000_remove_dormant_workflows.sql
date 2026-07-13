-- Remove unused replacement, clinic-package configuration, and terminal
-- appointment states while preserving existing pre-production data.

UPDATE public.appointments
SET status = 'checked_in'::public.appointment_status
WHERE status = 'completed'::public.appointment_status;

UPDATE public.appointments
SET status = 'scheduled'::public.appointment_status
WHERE status = 'no_show'::public.appointment_status;

DROP TRIGGER IF EXISTS trigger_appointment_package_deduction
ON public.appointments;
DROP FUNCTION IF EXISTS public.handle_package_deduction();

ALTER TABLE public.appointments ALTER COLUMN status DROP DEFAULT;
CREATE TYPE public.appointment_status_simplified AS ENUM (
  'scheduled',
  'checked_in',
  'cancelled'
);
ALTER TABLE public.appointments
  ALTER COLUMN status TYPE public.appointment_status_simplified
  USING (status::text::public.appointment_status_simplified);
DROP TYPE public.appointment_status;
ALTER TYPE public.appointment_status_simplified RENAME TO appointment_status;
ALTER TABLE public.appointments
  ALTER COLUMN status SET DEFAULT 'scheduled'::public.appointment_status;

CREATE OR REPLACE FUNCTION public.handle_package_deduction()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
  bucket text;
BEGIN
  IF NEW.type = 'normal_pt_session'::public.appointment_type THEN
    bucket := 'session_balance';
  ELSIF NEW.type = 'spinal_traction_session'::public.appointment_type THEN
    bucket := 'traction_balance';
  ELSE
    RETURN NEW;
  END IF;

  IF OLD.status = 'scheduled'::public.appointment_status
     AND NEW.status = 'checked_in'::public.appointment_status
     AND NEW.use_package = true THEN
    EXECUTE format(
      'UPDATE public.patients SET %I = %I - 1 WHERE id = $1',
      bucket,
      bucket
    ) USING NEW.patient_id;
  ELSIF OLD.status = 'checked_in'::public.appointment_status
     AND NEW.status IN (
       'scheduled'::public.appointment_status,
       'cancelled'::public.appointment_status
     )
     AND OLD.use_package = true THEN
    EXECUTE format(
      'UPDATE public.patients SET %I = %I + 1 WHERE id = $1',
      bucket,
      bucket
    ) USING NEW.patient_id;
  END IF;

  RETURN NEW;
END;
$function$;

CREATE TRIGGER trigger_appointment_package_deduction
AFTER UPDATE ON public.appointments
FOR EACH ROW EXECUTE FUNCTION public.handle_package_deduction();

DROP TRIGGER IF EXISTS tr_enforce_appointment_doctor_roles
ON public.appointment_doctors;
DROP TRIGGER IF EXISTS tr_enforce_replacement_doctor_roles
ON public.doctor_replacements;

CREATE OR REPLACE FUNCTION public.prevent_referenced_doctor_role_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  IF OLD.role = 'doctor'::public.user_role
     AND NEW.role <> 'doctor'::public.user_role
     AND (
       EXISTS (
         SELECT 1 FROM public.patient_doctors WHERE doctor_id = OLD.id
       )
       OR EXISTS (
         SELECT 1 FROM public.appointment_doctors WHERE doctor_id = OLD.id
       )
     ) THEN
    RAISE EXCEPTION 'Reassign this doctor before changing their role.'
      USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.book_recurring_appointments(
  p_patient_id uuid,
  p_type public.appointment_type,
  p_slots timestamptz[],
  p_use_package boolean,
  p_creator_id uuid,
  p_doctor_ids uuid[]
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  v_slot timestamptz;
  v_appt_id uuid;
  v_doc_id uuid;
BEGIN
  FOREACH v_slot IN ARRAY p_slots LOOP
    INSERT INTO public.appointments (
      patient_id,
      type,
      scheduled_at,
      status,
      use_package,
      created_by
    ) VALUES (
      p_patient_id,
      p_type,
      v_slot,
      'scheduled'::public.appointment_status,
      p_use_package,
      p_creator_id
    ) RETURNING id INTO v_appt_id;

    FOREACH v_doc_id IN ARRAY p_doctor_ids LOOP
      INSERT INTO public.appointment_doctors (
        appointment_id,
        doctor_id,
        is_active,
        added_by
      ) VALUES (
        v_appt_id,
        v_doc_id,
        true,
        p_creator_id
      );
    END LOOP;
  END LOOP;
END;
$function$;

-- These drops intentionally avoid CASCADE. The migration must fail instead of
-- silently removing an unexpected security policy or database dependency.
DROP TABLE public.doctor_replacements;
ALTER TABLE public.appointment_doctors
  DROP COLUMN replaced_doctor_id,
  DROP COLUMN is_replacement;
DROP TABLE public.clinic_settings;

CREATE TRIGGER tr_enforce_appointment_doctor_roles
BEFORE INSERT OR UPDATE OF doctor_id
ON public.appointment_doctors
FOR EACH ROW EXECUTE FUNCTION public.enforce_doctor_reference_roles('doctor_id');
