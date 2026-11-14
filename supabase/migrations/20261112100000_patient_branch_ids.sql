-- Patient ID numbers per branch.
-- Each branch counts its own patients from 1. Moving a patient to another
-- branch gives them the next number there; moving back restores the number
-- they had before. Numbers are never reused.

CREATE TABLE public.patient_number_series (
  clinic public.clinic_location PRIMARY KEY,
  last_number bigint NOT NULL CHECK (last_number >= 0)
);
ALTER TABLE public.patient_number_series ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.patient_number_series FROM PUBLIC, anon, authenticated;

-- Every number a patient has held, one per branch.
CREATE TABLE public.patient_branch_ids (
  patient_id uuid NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  clinic public.clinic_location NOT NULL,
  file_number bigint NOT NULL CHECK (file_number > 0),
  assigned_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (patient_id, clinic),
  UNIQUE (clinic, file_number)
);
ALTER TABLE public.patient_branch_ids ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.patient_branch_ids FROM PUBLIC, anon, authenticated;

-- Renumber the existing (test) patients from 1 in each branch, oldest first.
ALTER TABLE public.patients ALTER COLUMN file_number DROP IDENTITY;
ALTER TABLE public.patients DROP CONSTRAINT patients_file_number_key;
ALTER TABLE public.patients DISABLE TRIGGER USER;
UPDATE public.patients p SET file_number = n.number
FROM (
  SELECT id, row_number() OVER (PARTITION BY clinic ORDER BY created_at, id) AS number
  FROM public.patients
) n
WHERE n.id = p.id;
ALTER TABLE public.patients ENABLE TRIGGER USER;
ALTER TABLE public.patients
  ADD CONSTRAINT patients_clinic_file_number_key UNIQUE (clinic, file_number);

INSERT INTO public.patient_branch_ids(patient_id, clinic, file_number)
SELECT id, clinic, file_number FROM public.patients;
INSERT INTO public.patient_number_series(clinic, last_number)
SELECT clinic, max(file_number) FROM public.patients GROUP BY clinic;

-- One-off: the existing (test) invoices follow the renumbering. From here
-- on an invoice keeps the ID the patient had when it was issued.
ALTER TABLE public.invoices DISABLE TRIGGER USER;
UPDATE public.invoices i SET file_number = p.file_number
FROM public.patients p WHERE p.id = i.patient_id AND i.file_number <> p.file_number;
ALTER TABLE public.invoices ENABLE TRIGGER USER;

CREATE FUNCTION public.patient_next_number(p_clinic public.clinic_location)
RETURNS bigint LANGUAGE sql SET search_path = '' AS $$
  INSERT INTO public.patient_number_series AS series(clinic, last_number)
  VALUES (p_clinic, 1)
  ON CONFLICT (clinic) DO UPDATE SET last_number = series.last_number + 1
  RETURNING last_number;
$$;
REVOKE ALL ON FUNCTION public.patient_next_number(public.clinic_location)
  FROM PUBLIC, anon, authenticated;

-- New patients take the next number of their branch. A patient moved to
-- another branch takes the number they had there before, or the next one.
CREATE FUNCTION public.assign_patient_file_number() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  previous bigint;
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.file_number := public.patient_next_number(NEW.clinic);
    RETURN NEW;
  END IF;
  IF NEW.clinic IS DISTINCT FROM OLD.clinic THEN
    SELECT b.file_number INTO previous FROM public.patient_branch_ids b
    WHERE b.patient_id = NEW.id AND b.clinic = NEW.clinic;
    IF previous IS NULL THEN
      previous := public.patient_next_number(NEW.clinic);
      INSERT INTO public.patient_branch_ids(patient_id, clinic, file_number)
      VALUES (NEW.id, NEW.clinic, previous);
    END IF;
    NEW.file_number := previous;
  END IF;
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.assign_patient_file_number() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER assign_patient_file_number BEFORE INSERT OR UPDATE OF clinic ON public.patients
FOR EACH ROW EXECUTE FUNCTION public.assign_patient_file_number();

CREATE FUNCTION public.record_patient_file_number() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  INSERT INTO public.patient_branch_ids(patient_id, clinic, file_number)
  VALUES (NEW.id, NEW.clinic, NEW.file_number);
  RETURN NULL;
END;
$$;
REVOKE ALL ON FUNCTION public.record_patient_file_number() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER record_patient_file_number AFTER INSERT ON public.patients
FOR EACH ROW EXECUTE FUNCTION public.record_patient_file_number();

-- Outstanding balances list the patient's current ID, not the one printed
-- on an older invoice.
CREATE OR REPLACE FUNCTION public.invoice_report_outstanding(p_branch public.clinic_location)
RETURNS jsonb LANGUAGE sql STABLE SET search_path = '' AS $$
  WITH open AS (
    SELECT i.patient_id, i.invoice_date, f.due_minor
    FROM public.invoices i CROSS JOIN LATERAL public.invoice_figures(i.id) f
    WHERE i.voided_at IS NULL AND f.due_minor > 0 AND (p_branch IS NULL OR i.branch = p_branch)
  ), grouped AS (
    SELECT o.patient_id, p.full_name AS patient_name, p.file_number,
      count(*) AS open_invoices, sum(o.due_minor) AS due_minor, min(o.invoice_date) AS oldest_date
    FROM open o JOIN public.patients p ON p.id = o.patient_id
    GROUP BY o.patient_id, p.full_name, p.file_number
  )
  SELECT jsonb_build_object(
    'totals', (SELECT jsonb_build_object('due_minor', coalesce(sum(due_minor), 0),
      'open_invoices', coalesce(sum(open_invoices), 0), 'row_count', count(*)) FROM grouped),
    'rows', coalesce((SELECT jsonb_agg(to_jsonb(r) ORDER BY r.due_minor DESC, r.patient_name) FROM (
      SELECT * FROM grouped ORDER BY due_minor DESC, patient_name LIMIT 5000) r), '[]'::jsonb));
$$;
