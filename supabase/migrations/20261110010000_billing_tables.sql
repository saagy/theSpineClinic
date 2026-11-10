ALTER TABLE public.patients ADD COLUMN file_number bigint GENERATED ALWAYS AS IDENTITY;
ALTER TABLE public.patients ADD CONSTRAINT patients_file_number_key UNIQUE (file_number);

CREATE FUNCTION public.guard_patient_file_number() RETURNS trigger
LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
  IF NEW.file_number IS DISTINCT FROM OLD.file_number THEN
    RAISE EXCEPTION 'Patient file number is permanent' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER guard_patient_file_number BEFORE UPDATE OF file_number ON public.patients
FOR EACH ROW EXECUTE FUNCTION public.guard_patient_file_number();
REVOKE ALL ON FUNCTION public.guard_patient_file_number() FROM PUBLIC, anon, authenticated;

CREATE TABLE public.billing_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL CHECK (length(btrim(name)) BETWEEN 1 AND 160),
  kind text NOT NULL DEFAULT 'service' CHECK (kind IN ('service', 'package')),
  price_minor bigint NOT NULL CHECK (price_minor BETWEEN 1 AND 10000000000),
  active boolean NOT NULL DEFAULT true,
  covered_service_id uuid REFERENCES public.billing_items(id),
  session_count integer,
  validity_days integer CHECK (validity_days > 0),
  insurance_eligible boolean NOT NULL DEFAULT false,
  version integer NOT NULL DEFAULT 1,
  CHECK ((kind = 'service' AND covered_service_id IS NULL AND session_count IS NULL AND validity_days IS NULL)
      OR (kind = 'package' AND covered_service_id IS NOT NULL AND covered_service_id <> id
          AND session_count IS NOT NULL AND session_count > 0))
);

CREATE TABLE public.billing_number_series (
  branch public.clinic_location NOT NULL,
  kind text NOT NULL CHECK (kind IN ('invoice', 'receipt', 'return', 'refund')),
  last_number bigint NOT NULL CHECK (last_number > 0),
  PRIMARY KEY (branch, kind)
);

CREATE TABLE public.billing_invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES public.patients(id) ON DELETE RESTRICT,
  file_number bigint NOT NULL,
  patient_name text NOT NULL,
  branch public.clinic_location NOT NULL,
  doctor_id uuid NOT NULL REFERENCES public.staff(id),
  doctor_name text NOT NULL,
  consultant_id uuid REFERENCES public.staff(id),
  consultant_name text,
  service_date date NOT NULL,
  discount_bps integer NOT NULL CHECK (discount_bps BETWEEN 0 AND 10000),
  total_minor bigint NOT NULL CHECK (total_minor BETWEEN 0 AND 1000000000000),
  currency text NOT NULL DEFAULT 'EGP' CHECK (currency = 'EGP'),
  version integer NOT NULL DEFAULT 1,
  number bigint,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  created_by uuid NOT NULL REFERENCES public.staff(id),
  issued_at timestamptz,
  issued_by uuid REFERENCES public.staff(id),
  UNIQUE (branch, number),
  CHECK ((number IS NULL AND issued_at IS NULL AND issued_by IS NULL)
      OR (number > 0 AND issued_at IS NOT NULL AND issued_by IS NOT NULL))
);
CREATE INDEX billing_invoices_patient ON public.billing_invoices(patient_id);
CREATE INDEX billing_invoices_register ON public.billing_invoices(created_at DESC, id DESC);

CREATE TABLE public.billing_invoice_lines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id uuid NOT NULL REFERENCES public.billing_invoices(id) ON DELETE CASCADE,
  item_id uuid NOT NULL REFERENCES public.billing_items(id),
  item_name text NOT NULL,
  position integer NOT NULL CHECK (position > 0),
  quantity integer NOT NULL CHECK (quantity BETWEEN 1 AND 1000),
  price_minor bigint NOT NULL CHECK (price_minor > 0),
  net_minor bigint NOT NULL CHECK (net_minor BETWEEN 0 AND price_minor * quantity),
  UNIQUE (invoice_id, position),
  UNIQUE (invoice_id, item_id)
);

CREATE TABLE public.billing_movements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id uuid NOT NULL REFERENCES public.billing_invoices(id),
  branch public.clinic_location NOT NULL,
  kind text NOT NULL CHECK (kind IN ('receipt', 'return', 'refund')),
  number bigint NOT NULL CHECK (number > 0),
  amount_minor bigint NOT NULL CHECK (amount_minor >= 0),
  method text CHECK (method IN ('cash', 'visa')),
  reason text CHECK (length(btrim(reason)) BETWEEN 1 AND 500),
  recorded_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  recorded_by uuid NOT NULL REFERENCES public.staff(id),
  actor_name text NOT NULL,
  debt_reduced_minor bigint NOT NULL DEFAULT 0 CHECK (debt_reduced_minor BETWEEN 0 AND amount_minor),
  CHECK ((kind = 'return' AND reason IS NOT NULL AND method IS NULL)
    OR (kind <> 'return' AND amount_minor > 0 AND method IS NOT NULL AND debt_reduced_minor = 0
        AND (kind = 'receipt' OR reason IS NOT NULL))),
  UNIQUE (branch, kind, number)
);
CREATE INDEX billing_movements_invoice ON public.billing_movements(invoice_id, recorded_at, id);

CREATE TABLE public.billing_allocations (
  movement_id uuid NOT NULL REFERENCES public.billing_movements(id),
  line_id uuid NOT NULL REFERENCES public.billing_invoice_lines(id),
  amount_minor bigint NOT NULL CHECK (amount_minor >= 0),
  quantity integer CHECK (quantity > 0),
  PRIMARY KEY (movement_id, line_id)
);
CREATE INDEX billing_allocations_line ON public.billing_allocations(line_id);

CREATE FUNCTION public.billing_can(p_capability text) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT CASE p_capability
    WHEN 'transact' THEN public.current_staff_can_manage_payments()
    WHEN 'catalog' THEN EXISTS (
      SELECT 1 FROM public.staff WHERE user_id = auth.uid() AND is_active AND role = 'super_admin'
    )
    ELSE false END;
$$;
REVOKE ALL ON FUNCTION public.billing_can(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.billing_can(text) TO authenticated;

DO $$
DECLARE table_name text;
BEGIN
  FOREACH table_name IN ARRAY ARRAY['billing_items', 'billing_number_series', 'billing_invoices',
    'billing_invoice_lines', 'billing_movements', 'billing_allocations'] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', table_name);
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON public.%I TO authenticated', table_name);
    IF table_name <> 'billing_number_series' THEN
      EXECUTE format('CREATE POLICY billing_read ON public.%I FOR SELECT TO authenticated USING ((SELECT public.billing_can(''transact'')))', table_name);
    END IF;
  END LOOP;
END;
$$;
-- Client writes have no RLS policy. Checked functions are the only write path.

