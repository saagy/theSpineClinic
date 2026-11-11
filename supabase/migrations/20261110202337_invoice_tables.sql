-- Invoices v2: service catalog, invoices, receipts, refunds and collected-money
-- allocations. See docs/billing-plan.md. Amounts are EGP minor units (piasters).
-- Documents are never deleted; mistakes are voided and stay visible.

CREATE TABLE public.service_catalog (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL CHECK (length(btrim(name)) BETWEEN 1 AND 120),
  service_type text NOT NULL CHECK (service_type IN
    ('pt_session', 'traction_session', 'initial_assessment', 'reassessment', 'other')),
  sessions_per_unit integer NOT NULL DEFAULT 1 CHECK (sessions_per_unit BETWEEN 1 AND 100),
  price_minor bigint NOT NULL CHECK (price_minor BETWEEN 1 AND 100000000000),
  attributes_doctors boolean NOT NULL DEFAULT true,
  active boolean NOT NULL DEFAULT true,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  updated_by uuid REFERENCES public.staff(id),
  -- Packages exist only for session types that consume patient balances.
  CHECK (sessions_per_unit = 1 OR service_type IN ('pt_session', 'traction_session'))
);
CREATE UNIQUE INDEX service_catalog_name_key ON public.service_catalog (lower(btrim(name)));

CREATE TABLE public.invoice_number_series (
  branch public.clinic_location NOT NULL,
  kind text NOT NULL CHECK (kind IN ('invoice', 'receipt', 'refund')),
  last_number bigint NOT NULL CHECK (last_number > 0),
  PRIMARY KEY (branch, kind)
);

CREATE TABLE public.invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch public.clinic_location NOT NULL,
  number bigint NOT NULL CHECK (number > 0),
  patient_id uuid NOT NULL REFERENCES public.patients(id) ON DELETE RESTRICT,
  patient_name text NOT NULL,
  file_number bigint NOT NULL,
  invoice_date date NOT NULL CHECK (invoice_date >= DATE '2020-01-01'),
  subtotal_minor bigint NOT NULL CHECK (subtotal_minor BETWEEN 0 AND 1000000000000),
  discount_kind text NOT NULL DEFAULT 'none' CHECK (discount_kind IN ('none', 'percent', 'amount')),
  discount_value bigint NOT NULL DEFAULT 0,
  discount_minor bigint NOT NULL DEFAULT 0,
  total_minor bigint NOT NULL,
  note text CHECK (length(btrim(note)) BETWEEN 1 AND 500),
  currency text NOT NULL DEFAULT 'EGP' CHECK (currency = 'EGP'),
  replaces_invoice_id uuid UNIQUE REFERENCES public.invoices(id),
  created_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  created_by uuid NOT NULL REFERENCES public.staff(id),
  created_by_name text NOT NULL,
  voided_at timestamptz,
  voided_by uuid REFERENCES public.staff(id),
  voided_by_name text,
  void_reason text,
  version integer NOT NULL DEFAULT 1,
  UNIQUE (branch, number),
  CHECK (discount_minor BETWEEN 0 AND subtotal_minor AND total_minor = subtotal_minor - discount_minor),
  CHECK ((discount_kind = 'none' AND discount_value = 0 AND discount_minor = 0)
    OR (discount_kind = 'percent' AND discount_value BETWEEN 1 AND 10000)
    OR (discount_kind = 'amount' AND discount_value = discount_minor AND discount_value > 0)),
  CHECK ((voided_at IS NULL AND voided_by IS NULL AND voided_by_name IS NULL AND void_reason IS NULL)
    OR (voided_at IS NOT NULL AND voided_by IS NOT NULL AND voided_by_name IS NOT NULL
      AND length(btrim(void_reason)) BETWEEN 1 AND 500))
);
CREATE INDEX invoices_patient ON public.invoices (patient_id, invoice_date DESC, created_at DESC);
CREATE INDEX invoices_date ON public.invoices (invoice_date, branch);

CREATE TABLE public.invoice_lines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id uuid NOT NULL REFERENCES public.invoices(id),
  position integer NOT NULL CHECK (position BETWEEN 1 AND 50),
  service_id uuid NOT NULL REFERENCES public.service_catalog(id),
  service_name text NOT NULL,
  service_type text NOT NULL,
  sessions_per_unit integer NOT NULL CHECK (sessions_per_unit > 0),
  quantity integer NOT NULL CHECK (quantity BETWEEN 1 AND 100),
  unit_price_minor bigint NOT NULL CHECK (unit_price_minor > 0),
  gross_minor bigint NOT NULL,
  discount_minor bigint NOT NULL CHECK (discount_minor >= 0),
  net_minor bigint NOT NULL,
  sessions_granted integer NOT NULL,
  UNIQUE (invoice_id, position),
  CHECK (gross_minor = unit_price_minor * quantity),
  CHECK (discount_minor <= gross_minor AND net_minor = gross_minor - discount_minor),
  CHECK (sessions_granted = CASE WHEN service_type IN ('pt_session', 'traction_session')
    THEN quantity * sessions_per_unit ELSE 0 END)
);
CREATE INDEX invoice_lines_service ON public.invoice_lines (service_id);

CREATE TABLE public.invoice_line_doctors (
  line_id uuid NOT NULL REFERENCES public.invoice_lines(id),
  doctor_id uuid NOT NULL REFERENCES public.staff(id),
  doctor_name text NOT NULL,
  PRIMARY KEY (line_id, doctor_id)
);
CREATE INDEX invoice_line_doctors_doctor ON public.invoice_line_doctors (doctor_id);

CREATE TABLE public.invoice_receipts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id uuid NOT NULL REFERENCES public.invoices(id),
  branch public.clinic_location NOT NULL,
  number bigint NOT NULL CHECK (number > 0),
  amount_minor bigint NOT NULL CHECK (amount_minor > 0),
  method text NOT NULL CHECK (method IN ('cash', 'visa')),
  -- received_at is when money changed hands; a correction keeps the original.
  received_at timestamptz NOT NULL,
  recorded_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  recorded_by uuid NOT NULL REFERENCES public.staff(id),
  recorded_by_name text NOT NULL,
  replaces_receipt_id uuid UNIQUE REFERENCES public.invoice_receipts(id),
  voided_at timestamptz,
  voided_by uuid REFERENCES public.staff(id),
  voided_by_name text,
  void_reason text,
  UNIQUE (branch, number),
  CHECK ((voided_at IS NULL AND voided_by IS NULL AND voided_by_name IS NULL AND void_reason IS NULL)
    OR (voided_at IS NOT NULL AND voided_by IS NOT NULL AND voided_by_name IS NOT NULL
      AND length(btrim(void_reason)) BETWEEN 1 AND 500))
);
CREATE INDEX invoice_receipts_invoice ON public.invoice_receipts (invoice_id, recorded_at);
CREATE INDEX invoice_receipts_received ON public.invoice_receipts (received_at, branch);

CREATE TABLE public.invoice_refunds (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id uuid NOT NULL REFERENCES public.invoices(id),
  branch public.clinic_location NOT NULL,
  number bigint NOT NULL CHECK (number > 0),
  value_minor bigint NOT NULL CHECK (value_minor >= 0),
  payback_minor bigint NOT NULL CHECK (payback_minor BETWEEN 0 AND value_minor),
  payback_method text CHECK (payback_method IN ('cash', 'visa')),
  reason text NOT NULL CHECK (length(btrim(reason)) BETWEEN 1 AND 500),
  recorded_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  recorded_by uuid NOT NULL REFERENCES public.staff(id),
  recorded_by_name text NOT NULL,
  voided_at timestamptz,
  voided_by uuid REFERENCES public.staff(id),
  voided_by_name text,
  void_reason text,
  UNIQUE (branch, number),
  CHECK ((payback_minor = 0) = (payback_method IS NULL)),
  CHECK ((voided_at IS NULL AND voided_by IS NULL AND voided_by_name IS NULL AND void_reason IS NULL)
    OR (voided_at IS NOT NULL AND voided_by IS NOT NULL AND voided_by_name IS NOT NULL
      AND length(btrim(void_reason)) BETWEEN 1 AND 500))
);
CREATE INDEX invoice_refunds_invoice ON public.invoice_refunds (invoice_id, recorded_at);
CREATE INDEX invoice_refunds_recorded ON public.invoice_refunds (recorded_at, branch);

CREATE TABLE public.invoice_refund_lines (
  refund_id uuid NOT NULL REFERENCES public.invoice_refunds(id),
  line_id uuid NOT NULL REFERENCES public.invoice_lines(id),
  sessions_cancelled integer NOT NULL CHECK (sessions_cancelled >= 0),
  value_minor bigint NOT NULL CHECK (value_minor >= 0),
  PRIMARY KEY (refund_id, line_id),
  CHECK (sessions_cancelled > 0 OR value_minor > 0)
);
CREATE INDEX invoice_refund_lines_line ON public.invoice_refund_lines (line_id);

-- Signed shares of collected money per invoice line. Receipts add money;
-- refunds remove paid-back money and move freed money between lines.
CREATE TABLE public.invoice_allocations (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  line_id uuid NOT NULL REFERENCES public.invoice_lines(id),
  receipt_id uuid REFERENCES public.invoice_receipts(id),
  refund_id uuid REFERENCES public.invoice_refunds(id),
  amount_minor bigint NOT NULL CHECK (amount_minor <> 0),
  CHECK ((receipt_id IS NULL) <> (refund_id IS NULL)),
  CHECK (receipt_id IS NULL OR amount_minor > 0)
);
CREATE INDEX invoice_allocations_line ON public.invoice_allocations (line_id);
CREATE INDEX invoice_allocations_receipt ON public.invoice_allocations (receipt_id);
CREATE INDEX invoice_allocations_refund ON public.invoice_allocations (refund_id);

-- issue: any active receptionist or super admin may view, invoice and collect.
-- manage: payment receptionists and super admins may discount, void, correct,
-- refund, edit the service catalog and read reports.
CREATE FUNCTION public.invoice_can(p_capability text) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT CASE p_capability
    WHEN 'issue' THEN EXISTS (SELECT 1 FROM public.staff WHERE user_id = auth.uid()
      AND is_active AND role IN ('super_admin', 'receptionist'))
    WHEN 'manage' THEN public.current_staff_can_manage_payments()
    ELSE false END;
$$;
REVOKE ALL ON FUNCTION public.invoice_can(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.invoice_can(text) TO authenticated;

DO $$
DECLARE table_name text;
BEGIN
  FOREACH table_name IN ARRAY ARRAY['service_catalog', 'invoice_number_series', 'invoices',
    'invoice_lines', 'invoice_line_doctors', 'invoice_receipts', 'invoice_refunds',
    'invoice_refund_lines', 'invoice_allocations'] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', table_name);
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON public.%I TO authenticated', table_name);
    IF table_name <> 'invoice_number_series' THEN
      EXECUTE format('CREATE POLICY invoice_read ON public.%I FOR SELECT TO authenticated '
        'USING ((SELECT public.invoice_can(''issue'')))', table_name);
    END IF;
  END LOOP;
END;
$$;
-- No client write policies: execute_invoice_command is the only write path.
