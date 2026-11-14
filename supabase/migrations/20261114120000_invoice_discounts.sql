-- Discounts on an issued invoice. A payment receptionist or the admin can
-- lower an invoice after it was issued without editing it: the invoice keeps
-- its number, its receipts stay as they are, and the discount is its own
-- dated document with a reason (an adjustment, like a credit note).
--
-- A discount is stored with refunds because it changes the same figures: it
-- lowers the invoice value line by line and, when the patient already paid
-- more than the new value, records the money handed back. It never cancels
-- sessions. It has its own number series per branch, so refund numbers stay
-- consecutive. Editing an invoice remains the way to correct a mistake.

ALTER TABLE public.invoice_number_series DROP CONSTRAINT invoice_number_series_kind_check;
ALTER TABLE public.invoice_number_series ADD CONSTRAINT invoice_number_series_kind_check
  CHECK (kind IN ('invoice', 'receipt', 'refund', 'discount'));

ALTER TABLE public.invoice_refunds ADD COLUMN kind text NOT NULL DEFAULT 'refund'
  CHECK (kind IN ('refund', 'discount'));
ALTER TABLE public.invoice_refunds DROP CONSTRAINT invoice_refunds_branch_number_key;
ALTER TABLE public.invoice_refunds ADD CONSTRAINT invoice_refunds_branch_kind_number_key
  UNIQUE (branch, kind, number);

-- Payload: discount {kind: percent|amount, value} (basis points or piasters),
-- payback_minor (the amount the screen showed), payback_method, branch,
-- reason. A percentage is of the invoice value now. The discount is shared
-- between lines in proportion to each line's value now.
CREATE FUNCTION public.invoice_record_discount(p_invoice public.invoices, p_data jsonb, p_actor uuid)
RETURNS uuid LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE
  discount_kind text := p_data#>>'{discount,kind}';
  rate bigint := (p_data#>>'{discount,value}')::bigint;
  method text := nullif(p_data->>'payback_method', '');
  branch public.clinic_location := (p_data->>'branch')::public.clinic_location;
  figures record; discount bigint; payback bigint; discount_id uuid;
BEGIN
  IF p_invoice.voided_at IS NOT NULL THEN RAISE EXCEPTION 'invoice_voided' USING ERRCODE = 'P0001'; END IF;
  IF branch IS NULL OR discount_kind IS NULL OR rate IS NULL THEN
    RAISE EXCEPTION 'invalid_request' USING ERRCODE = 'P0001';
  END IF;
  SELECT * INTO figures FROM public.invoice_figures(p_invoice.id);
  discount := CASE discount_kind
    WHEN 'percent' THEN round(figures.value_minor::numeric * rate / 10000)::bigint
    WHEN 'amount' THEN rate END;
  IF discount IS NULL OR (discount_kind = 'percent' AND rate NOT BETWEEN 1 AND 10000)
    OR discount < 1 OR discount > figures.value_minor THEN
    RAISE EXCEPTION 'invalid_discount' USING ERRCODE = 'P0001';
  END IF;
  payback := greatest(figures.net_collected_minor - (figures.value_minor - discount), 0);
  IF payback IS DISTINCT FROM (p_data->>'payback_minor')::bigint THEN
    RAISE EXCEPTION 'stale' USING ERRCODE = 'P0001';
  END IF;
  IF (payback > 0) <> (method IS NOT NULL) THEN
    RAISE EXCEPTION 'invalid_request' USING ERRCODE = 'P0001';
  END IF;
  INSERT INTO public.invoice_refunds(invoice_id, branch, number, kind, value_minor, payback_minor,
    payback_method, reason, recorded_by, recorded_by_name)
  VALUES (p_invoice.id, branch, public.invoice_next_number(branch, 'discount'), 'discount', discount,
    payback, method, btrim(p_data->>'reason'), p_actor, public.invoice_actor_name(p_actor))
  RETURNING id INTO discount_id;
  -- Cumulative integer division keeps the parts exact: they add up to the discount.
  WITH open_lines AS (
    SELECT line_id, line_position, value_minor FROM public.invoice_line_figures(p_invoice.id)
    WHERE value_minor > 0
  ), weighted AS (
    SELECT *, sum(value_minor) OVER (ORDER BY line_position) AS cumulative,
      sum(value_minor) OVER () AS total FROM open_lines
  ), parts AS (
    SELECT line_id, div(discount::numeric * cumulative, total)
      - div(discount::numeric * (cumulative - value_minor), total) AS part FROM weighted
  )
  INSERT INTO public.invoice_refund_lines(refund_id, line_id, sessions_cancelled, value_minor)
  SELECT discount_id, line_id, 0, part FROM parts WHERE part > 0;
  PERFORM public.invoice_reallocate_refund(p_invoice.id, discount_id, payback);
  RETURN discount_id;
END;
$$;
REVOKE ALL ON FUNCTION public.invoice_record_discount(public.invoices, jsonb, uuid)
  FROM PUBLIC, anon, authenticated;

-- Refunds are patient-requested reductions; discounts are reported apart.
-- refunded_minor keeps its name and now counts refunds only; discounts
-- added after issue are later_discount_minor. Value and due are unchanged.
CREATE OR REPLACE VIEW public.invoice_register WITH (security_invoker = true) AS
SELECT i.*, f.refunded_minor - ld.minor AS refunded_minor, f.value_minor, f.received_minor,
  f.paid_back_minor, f.net_collected_minor,
  CASE WHEN i.voided_at IS NULL THEN f.due_minor ELSE 0 END AS due_minor,
  CASE
    WHEN i.voided_at IS NOT NULL THEN 'voided'
    WHEN f.due_minor = 0 AND f.refunded_minor - ld.minor > 0 THEN 'refunded'
    WHEN f.due_minor = 0 THEN 'paid'
    WHEN f.net_collected_minor > 0 THEN 'partially_paid'
    ELSE 'unpaid'
  END AS status,
  s.services, s.doctors, ld.minor AS later_discount_minor
FROM public.invoices i
CROSS JOIN LATERAL public.invoice_figures(i.id) f
CROSS JOIN LATERAL (
  SELECT coalesce(sum(value_minor), 0)::bigint AS minor FROM public.invoice_refunds
  WHERE invoice_id = i.id AND voided_at IS NULL AND kind = 'discount'
) ld
LEFT JOIN LATERAL (
  SELECT string_agg(CASE WHEN l.quantity > 1 THEN l.quantity || ' × ' ELSE '' END || l.service_name,
      ', ' ORDER BY l.position) AS services,
    (SELECT coalesce(jsonb_agg(DISTINCT d.doctor_name), '[]'::jsonb)
      FROM public.invoice_line_doctors d JOIN public.invoice_lines dl ON dl.id = d.line_id
      WHERE dl.invoice_id = i.id) AS doctors
  FROM public.invoice_lines l WHERE l.invoice_id = i.id
) s ON true;

-- Report rows name the document: a discount's rows say discount, not refund.
CREATE OR REPLACE FUNCTION public.invoice_report_allocations(p_from date, p_to date,
  p_branch public.clinic_location)
RETURNS TABLE(allocation_id bigint, line_id uuid, moved_at timestamptz, branch public.clinic_location,
  kind text, document_number bigint, method text, amount_minor bigint)
LANGUAGE sql STABLE SET search_path = '' AS $$
  SELECT a.id, a.line_id, rc.received_at, rc.branch, 'receipt', rc.number, rc.method, a.amount_minor
  FROM public.invoice_receipts rc JOIN public.invoice_allocations a ON a.receipt_id = rc.id
  WHERE rc.voided_at IS NULL AND (p_branch IS NULL OR rc.branch = p_branch)
    AND rc.received_at >= (p_from::timestamp AT TIME ZONE public.clinic_timezone())
    AND rc.received_at < ((p_to + 1)::timestamp AT TIME ZONE public.clinic_timezone())
  UNION ALL
  SELECT s.id, s.line_id, s.recorded_at, s.branch, s.kind, s.number, part.method, part.amount
  FROM (
    SELECT a.id, a.line_id, a.amount_minor, rf.recorded_at, rf.branch, rf.kind, rf.number,
      rf.payback_method, rf.payback_minor,
      sum(-a.amount_minor) FILTER (WHERE a.amount_minor < 0)
        OVER (PARTITION BY rf.id ORDER BY a.id) AS lost_so_far,
      sum(-a.amount_minor) FILTER (WHERE a.amount_minor < 0) OVER (PARTITION BY rf.id) AS lost
    FROM public.invoice_refunds rf JOIN public.invoice_allocations a ON a.refund_id = rf.id
    WHERE rf.voided_at IS NULL AND (p_branch IS NULL OR rf.branch = p_branch)
      AND rf.recorded_at >= (p_from::timestamp AT TIME ZONE public.clinic_timezone())
      AND rf.recorded_at < ((p_to + 1)::timestamp AT TIME ZONE public.clinic_timezone())
  ) s
  -- The share of the payback this row handed back, as a negative amount.
  CROSS JOIN LATERAL (
    SELECT CASE WHEN s.amount_minor < 0 AND s.payback_minor > 0 THEN
      -(div(s.payback_minor::numeric * s.lost_so_far, s.lost)
        - div(s.payback_minor::numeric * (s.lost_so_far + s.amount_minor), s.lost))::bigint
      ELSE 0 END AS handed_back
  ) p
  CROSS JOIN LATERAL (VALUES
    (s.payback_method, p.handed_back),
    (NULL::text, s.amount_minor - p.handed_back)
  ) AS part(method, amount)
  WHERE part.amount <> 0;
$$;
REVOKE ALL ON FUNCTION public.invoice_report_allocations(date, date, public.clinic_location)
  FROM PUBLIC, anon, authenticated;

-- Money handed back by a discount leaves the drawer like a refund's.
CREATE OR REPLACE FUNCTION public.invoice_report_money(p_from date, p_to date, p_branch public.clinic_location)
RETURNS jsonb LANGUAGE sql STABLE SET search_path = '' AS $$
  WITH bounds AS (
    SELECT (p_from::timestamp AT TIME ZONE public.clinic_timezone()) AS lo,
      ((p_to + 1)::timestamp AT TIME ZONE public.clinic_timezone()) AS hi
  ), moves AS (
    SELECT 'receipt' AS kind, rc.id, rc.number, rc.branch, rc.received_at AS moved_at, rc.method,
      rc.amount_minor, rc.recorded_by, rc.recorded_by_name, rc.invoice_id
    FROM public.invoice_receipts rc, bounds
    WHERE rc.voided_at IS NULL AND rc.received_at >= lo AND rc.received_at < hi
      AND (p_branch IS NULL OR rc.branch = p_branch)
    UNION ALL
    SELECT rf.kind, rf.id, rf.number, rf.branch, rf.recorded_at, rf.payback_method,
      rf.payback_minor, rf.recorded_by, rf.recorded_by_name, rf.invoice_id
    FROM public.invoice_refunds rf, bounds
    WHERE rf.voided_at IS NULL AND rf.payback_minor > 0 AND rf.recorded_at >= lo AND rf.recorded_at < hi
      AND (p_branch IS NULL OR rf.branch = p_branch)
  ), voids AS (
    SELECT 'invoice' AS kind, i.id, i.number, i.branch, i.total_minor AS amount_minor, i.voided_at,
      i.voided_by_name, i.void_reason, i.id AS invoice_id
    FROM public.invoices i, bounds
    WHERE i.voided_at >= lo AND i.voided_at < hi AND (p_branch IS NULL OR i.branch = p_branch)
    UNION ALL
    SELECT 'receipt', rc.id, rc.number, rc.branch, rc.amount_minor, rc.voided_at, rc.voided_by_name,
      rc.void_reason, rc.invoice_id
    FROM public.invoice_receipts rc, bounds
    WHERE rc.voided_at >= lo AND rc.voided_at < hi AND (p_branch IS NULL OR rc.branch = p_branch)
    UNION ALL
    SELECT rf.kind, rf.id, rf.number, rf.branch, rf.value_minor, rf.voided_at, rf.voided_by_name,
      rf.void_reason, rf.invoice_id
    FROM public.invoice_refunds rf, bounds
    WHERE rf.voided_at >= lo AND rf.voided_at < hi AND (p_branch IS NULL OR rf.branch = p_branch)
  )
  SELECT jsonb_build_object(
    'totals', (SELECT jsonb_build_object(
      'cash_in_minor', coalesce(sum(amount_minor) FILTER (WHERE kind = 'receipt' AND method = 'cash'), 0),
      'visa_in_minor', coalesce(sum(amount_minor) FILTER (WHERE kind = 'receipt' AND method = 'visa'), 0),
      'cash_out_minor', coalesce(sum(amount_minor) FILTER (WHERE kind <> 'receipt' AND method = 'cash'), 0),
      'visa_out_minor', coalesce(sum(amount_minor) FILTER (WHERE kind <> 'receipt' AND method = 'visa'), 0),
      'row_count', count(*)) FROM moves),
    'staff', coalesce((SELECT jsonb_agg(to_jsonb(s) ORDER BY s.name, s.staff_id) FROM (
      SELECT recorded_by AS staff_id, max(recorded_by_name) AS name,
        coalesce(sum(amount_minor) FILTER (WHERE kind = 'receipt' AND method = 'cash'), 0) AS cash_in_minor,
        coalesce(sum(amount_minor) FILTER (WHERE kind = 'receipt' AND method = 'visa'), 0) AS visa_in_minor,
        coalesce(sum(amount_minor) FILTER (WHERE kind <> 'receipt' AND method = 'cash'), 0) AS cash_out_minor,
        coalesce(sum(amount_minor) FILTER (WHERE kind <> 'receipt' AND method = 'visa'), 0) AS visa_out_minor
      FROM moves GROUP BY recorded_by) s), '[]'::jsonb),
    'rows', coalesce((SELECT jsonb_agg(to_jsonb(r) ORDER BY r.moved_at, r.id) FROM (
      SELECT m.kind, m.id, m.number, m.branch, m.moved_at, m.method, m.amount_minor,
        m.recorded_by_name, i.id AS invoice_id, i.number AS invoice_number,
        i.branch AS invoice_branch, i.patient_id, i.patient_name, i.file_number
      FROM moves m JOIN public.invoices i ON i.id = m.invoice_id
      ORDER BY m.moved_at, m.id LIMIT 5000) r), '[]'::jsonb),
    'voids', coalesce((SELECT jsonb_agg(to_jsonb(v) ORDER BY v.voided_at, v.id) FROM (
      SELECT x.kind, x.id, x.number, x.branch, x.amount_minor, x.voided_at, x.voided_by_name,
        x.void_reason, i.id AS invoice_id, i.number AS invoice_number,
        i.branch AS invoice_branch, i.patient_id, i.patient_name, i.file_number
      FROM voids x JOIN public.invoices i ON i.id = x.invoice_id
      ORDER BY x.voided_at, x.id LIMIT 5000) v), '[]'::jsonb));
$$;
REVOKE ALL ON FUNCTION public.invoice_report_money(date, date, public.clinic_location)
  FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.invoice_command_capability(p_kind text) RETURNS text
LANGUAGE sql IMMUTABLE SET search_path = '' AS $$
  SELECT CASE
    WHEN p_kind IN ('invoice_create', 'receipt_create') THEN 'issue'
    WHEN p_kind IN ('service_save', 'invoice_void', 'invoice_void_all', 'invoice_correct',
      'receipt_void', 'receipt_correct', 'refund_create', 'refund_void', 'discount_create') THEN 'manage'
  END;
$$;
REVOKE ALL ON FUNCTION public.invoice_command_capability(text) FROM PUBLIC, anon, authenticated;

-- Same dispatcher as 20261113120000, plus discount_create. A discount is
-- cancelled with refund_void, like a refund.
CREATE OR REPLACE FUNCTION public.execute_invoice_command(p_request_id uuid, p_kind text, p_payload jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  actor uuid := (SELECT id FROM public.staff WHERE user_id = auth.uid() AND is_active);
  capability text := public.invoice_command_capability(p_kind);
  previous public.mutation_receipts;
  invoice public.invoices;
  invoice_id uuid := (p_payload->>'id')::uuid;
  document_id uuid;
  kind_key text := 'invoice:' || p_kind;
  request_hash text := encode(sha256(convert_to(p_payload::text, 'UTF8')), 'hex');
  reason text := nullif(btrim(p_payload->>'reason'), '');
  payment jsonb;
  outcome jsonb;
  error_key text;
BEGIN
  IF p_request_id IS NULL OR p_payload IS NULL OR capability IS NULL THEN
    RAISE EXCEPTION 'Invalid invoice request' USING ERRCODE = '22023';
  END IF;
  IF actor IS NULL OR NOT public.invoice_can(capability) THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE = '42501';
  END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended(p_request_id::text, 0));
  SELECT * INTO previous FROM public.mutation_receipts WHERE request_id = p_request_id;
  IF FOUND THEN
    IF previous.actor_id <> actor OR previous.kind <> kind_key OR previous.payload_hash <> request_hash THEN
      RAISE EXCEPTION 'Request identity mismatch' USING ERRCODE = '22023';
    END IF;
    RETURN previous.outcome;
  END IF;
  BEGIN
    IF p_kind NOT IN ('service_save', 'invoice_create') THEN
      SELECT * INTO invoice FROM public.invoices WHERE id = invoice_id FOR UPDATE;
      IF NOT FOUND OR invoice.version IS DISTINCT FROM (p_payload->>'version')::integer THEN
        RAISE EXCEPTION 'stale' USING ERRCODE = 'P0001';
      END IF;
    END IF;
    IF p_kind IN ('invoice_void', 'invoice_void_all', 'invoice_correct', 'receipt_void',
      'receipt_correct', 'refund_create', 'refund_void', 'discount_create')
      AND (reason IS NULL OR length(reason) > 500) THEN
      RAISE EXCEPTION 'reason_required' USING ERRCODE = 'P0001';
    END IF;
    CASE p_kind
      WHEN 'service_save' THEN document_id := public.invoice_save_service(p_payload, actor);
      WHEN 'invoice_create' THEN
        IF jsonb_array_length(coalesce(p_payload->'payments', '[]')) > 2 OR EXISTS (
          SELECT 1 FROM jsonb_array_elements(coalesce(p_payload->'payments', '[]')) p
          GROUP BY p->>'method' HAVING count(*) > 1) THEN
          RAISE EXCEPTION 'invalid_request' USING ERRCODE = 'P0001';
        END IF;
        invoice_id := public.invoice_create(p_payload, actor, public.invoice_can('manage'), NULL);
        FOR payment IN SELECT value FROM jsonb_array_elements(coalesce(p_payload->'payments', '[]')) LOOP
          SELECT * INTO invoice FROM public.invoices WHERE id = invoice_id;
          PERFORM public.invoice_record_receipt(invoice, (payment->>'amount_minor')::bigint,
            payment->>'method', invoice.branch, NULL, NULL, actor);
        END LOOP;
      WHEN 'receipt_create' THEN
        document_id := public.invoice_record_receipt(invoice, (p_payload->>'amount_minor')::bigint,
          p_payload->>'method', (p_payload->>'branch')::public.clinic_location, NULL, NULL, actor);
      WHEN 'receipt_correct' THEN document_id := public.invoice_correct_receipt(invoice, p_payload, actor);
      WHEN 'receipt_void' THEN
        PERFORM public.invoice_void_receipt(invoice, (p_payload->>'receipt_id')::uuid, reason, actor);
      WHEN 'refund_create' THEN document_id := public.invoice_record_refund(invoice, p_payload, actor);
      WHEN 'discount_create' THEN document_id := public.invoice_record_discount(invoice, p_payload, actor);
      WHEN 'refund_void' THEN
        PERFORM public.invoice_void_refund(invoice, (p_payload->>'refund_id')::uuid, reason, actor);
      WHEN 'invoice_void' THEN PERFORM public.invoice_void(invoice, reason, actor);
      WHEN 'invoice_void_all' THEN PERFORM public.invoice_void_with_receipts(invoice, reason, actor);
      WHEN 'invoice_correct' THEN
        document_id := public.invoice_correct(invoice, p_payload, actor);
        invoice_id := document_id;
    END CASE;
    IF p_kind IN ('receipt_create', 'receipt_correct', 'receipt_void', 'refund_create', 'refund_void',
      'discount_create') THEN
      UPDATE public.invoices SET version = version + 1 WHERE id = invoice.id;
    END IF;
    outcome := jsonb_build_object('ok', true, 'invoice_id', invoice_id, 'document_id', document_id);
  EXCEPTION
    WHEN raise_exception THEN
      GET STACKED DIAGNOSTICS error_key = MESSAGE_TEXT;
      outcome := jsonb_build_object('ok', false, 'error', error_key);
    WHEN unique_violation THEN
      outcome := '{"ok":false,"error":"duplicate"}';
    WHEN data_exception OR integrity_constraint_violation OR no_data_found OR invalid_text_representation THEN
      outcome := '{"ok":false,"error":"invalid_request"}';
  END;
  INSERT INTO public.mutation_receipts(request_id, actor_id, kind, payload_hash, outcome)
    VALUES (p_request_id, actor, kind_key, request_hash, outcome);
  RETURN outcome;
END;
$$;
