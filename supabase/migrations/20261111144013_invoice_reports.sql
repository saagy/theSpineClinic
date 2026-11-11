-- Billing tab reports (docs/billing-plan.md, slice 6). invoice_report is the
-- only client entry point and requires the manage capability. Days are clinic
-- days. Money is dated by when it changed hands (receipt received_at, refund
-- recorded_at) and belongs to the branch of that receipt or refund. Voided
-- documents are left out of every total and listed in the void log on the day
-- they were voided. Detail rows are capped at 5000; totals are always complete.

-- Active collected-money movements per invoice line. A refund that pays
-- nothing back only moves money between lines, so its method is NULL.
CREATE FUNCTION public.invoice_report_allocations(p_from date, p_to date, p_branch public.clinic_location)
RETURNS TABLE(allocation_id bigint, line_id uuid, moved_at timestamptz, branch public.clinic_location,
  kind text, document_number bigint, method text, amount_minor bigint)
LANGUAGE sql STABLE SET search_path = '' AS $$
  SELECT a.id, a.line_id, rc.received_at, rc.branch, 'receipt', rc.number, rc.method, a.amount_minor
  FROM public.invoice_receipts rc JOIN public.invoice_allocations a ON a.receipt_id = rc.id
  WHERE rc.voided_at IS NULL AND (p_branch IS NULL OR rc.branch = p_branch)
    AND rc.received_at >= (p_from::timestamp AT TIME ZONE public.clinic_timezone())
    AND rc.received_at < ((p_to + 1)::timestamp AT TIME ZONE public.clinic_timezone())
  UNION ALL
  SELECT a.id, a.line_id, rf.recorded_at, rf.branch, 'refund', rf.number, rf.payback_method, a.amount_minor
  FROM public.invoice_refunds rf JOIN public.invoice_allocations a ON a.refund_id = rf.id
  WHERE rf.voided_at IS NULL AND (p_branch IS NULL OR rf.branch = p_branch)
    AND rf.recorded_at >= (p_from::timestamp AT TIME ZONE public.clinic_timezone())
    AND rf.recorded_at < ((p_to + 1)::timestamp AT TIME ZONE public.clinic_timezone());
$$;

-- Each movement split equally among the line's doctors. Cumulative floors
-- keep the parts exact for positive and negative amounts. A line without
-- doctors yields one row with a NULL doctor: clinic-only revenue.
CREATE FUNCTION public.invoice_report_shares(p_from date, p_to date, p_branch public.clinic_location)
RETURNS TABLE(allocation_id bigint, line_id uuid, moved_at timestamptz, branch public.clinic_location,
  kind text, document_number bigint, method text, amount_minor bigint,
  doctor_id uuid, doctor_name text, share_minor bigint)
LANGUAGE sql STABLE SET search_path = '' AS $$
  SELECT m.allocation_id, m.line_id, m.moved_at, m.branch, m.kind, m.document_number, m.method,
    m.amount_minor, d.doctor_id, d.doctor_name,
    CASE WHEN d.doctor_id IS NULL THEN m.amount_minor ELSE
      (floor(m.amount_minor::numeric * d.seat / d.seats)
        - floor(m.amount_minor::numeric * (d.seat - 1) / d.seats))::bigint END
  FROM public.invoice_report_allocations(p_from, p_to, p_branch) m
  LEFT JOIN LATERAL (
    SELECT ld.doctor_id, ld.doctor_name, row_number() OVER (ORDER BY ld.doctor_id) AS seat,
      count(*) OVER () AS seats
    FROM public.invoice_line_doctors ld WHERE ld.line_id = m.line_id
  ) d ON true;
$$;

-- 1. Daily money in and out.
CREATE FUNCTION public.invoice_report_money(p_from date, p_to date, p_branch public.clinic_location)
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
    SELECT 'refund', rf.id, rf.number, rf.branch, rf.recorded_at, rf.payback_method,
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
    SELECT 'refund', rf.id, rf.number, rf.branch, rf.value_minor, rf.voided_at, rf.voided_by_name,
      rf.void_reason, rf.invoice_id
    FROM public.invoice_refunds rf, bounds
    WHERE rf.voided_at >= lo AND rf.voided_at < hi AND (p_branch IS NULL OR rf.branch = p_branch)
  )
  SELECT jsonb_build_object(
    'totals', (SELECT jsonb_build_object(
      'cash_in_minor', coalesce(sum(amount_minor) FILTER (WHERE kind = 'receipt' AND method = 'cash'), 0),
      'visa_in_minor', coalesce(sum(amount_minor) FILTER (WHERE kind = 'receipt' AND method = 'visa'), 0),
      'cash_out_minor', coalesce(sum(amount_minor) FILTER (WHERE kind = 'refund' AND method = 'cash'), 0),
      'visa_out_minor', coalesce(sum(amount_minor) FILTER (WHERE kind = 'refund' AND method = 'visa'), 0),
      'row_count', count(*)) FROM moves),
    'staff', coalesce((SELECT jsonb_agg(to_jsonb(s) ORDER BY s.name, s.staff_id) FROM (
      SELECT recorded_by AS staff_id, max(recorded_by_name) AS name,
        coalesce(sum(amount_minor) FILTER (WHERE kind = 'receipt' AND method = 'cash'), 0) AS cash_in_minor,
        coalesce(sum(amount_minor) FILTER (WHERE kind = 'receipt' AND method = 'visa'), 0) AS visa_in_minor,
        coalesce(sum(amount_minor) FILTER (WHERE kind = 'refund' AND method = 'cash'), 0) AS cash_out_minor,
        coalesce(sum(amount_minor) FILTER (WHERE kind = 'refund' AND method = 'visa'), 0) AS visa_out_minor
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

-- 2. Revenue: one row per collected service allocation. The doctor filter
-- keeps lines credited to that doctor and still shows the full line amount.
CREATE FUNCTION public.invoice_report_revenue(p_from date, p_to date, p_branch public.clinic_location,
  p_doctor uuid)
RETURNS jsonb LANGUAGE sql STABLE SET search_path = '' AS $$
  WITH moves AS (
    SELECT m.*, l.service_name, l.net_minor AS price_minor, i.id AS invoice_id,
      i.number AS invoice_number, i.branch AS invoice_branch, i.patient_id, i.patient_name,
      i.file_number,
      coalesce((SELECT jsonb_agg(d.doctor_name ORDER BY d.doctor_name)
        FROM public.invoice_line_doctors d WHERE d.line_id = m.line_id), '[]'::jsonb) AS doctors
    FROM public.invoice_report_allocations(p_from, p_to, p_branch) m
    JOIN public.invoice_lines l ON l.id = m.line_id
    JOIN public.invoices i ON i.id = l.invoice_id
    WHERE p_doctor IS NULL OR EXISTS (SELECT 1 FROM public.invoice_line_doctors d
      WHERE d.line_id = m.line_id AND d.doctor_id = p_doctor)
  )
  SELECT jsonb_build_object(
    'totals', (SELECT jsonb_build_object(
      'collected_minor', coalesce(sum(amount_minor), 0),
      'cash_minor', coalesce(sum(amount_minor) FILTER (WHERE method = 'cash'), 0),
      'visa_minor', coalesce(sum(amount_minor) FILTER (WHERE method = 'visa'), 0),
      'moved_minor', coalesce(sum(amount_minor) FILTER (WHERE method IS NULL), 0),
      'row_count', count(*)) FROM moves),
    'rows', coalesce((SELECT jsonb_agg(to_jsonb(r) ORDER BY r.moved_at, r.allocation_id) FROM (
      SELECT * FROM moves ORDER BY moved_at, allocation_id LIMIT 5000) r), '[]'::jsonb));
$$;

-- 3. Doctor revenue: one doctor's share of every collected allocation.
CREATE FUNCTION public.invoice_report_doctor(p_from date, p_to date, p_branch public.clinic_location,
  p_doctor uuid)
RETURNS jsonb LANGUAGE sql STABLE SET search_path = '' AS $$
  WITH shares AS (
    SELECT s.*, l.service_name, l.net_minor AS price_minor, i.id AS invoice_id,
      i.number AS invoice_number, i.branch AS invoice_branch, i.patient_id, i.patient_name,
      i.file_number,
      (SELECT count(*) FROM public.invoice_line_doctors d WHERE d.line_id = s.line_id) AS doctor_count
    FROM public.invoice_report_shares(p_from, p_to, p_branch) s
    JOIN public.invoice_lines l ON l.id = s.line_id
    JOIN public.invoices i ON i.id = l.invoice_id
    WHERE s.doctor_id = p_doctor
  )
  SELECT jsonb_build_object(
    'totals', (SELECT jsonb_build_object(
      'share_minor', coalesce(sum(share_minor), 0),
      'cash_minor', coalesce(sum(share_minor) FILTER (WHERE method = 'cash'), 0),
      'visa_minor', coalesce(sum(share_minor) FILTER (WHERE method = 'visa'), 0),
      'moved_minor', coalesce(sum(share_minor) FILTER (WHERE method IS NULL), 0),
      'row_count', count(*)) FROM shares),
    'rows', coalesce((SELECT jsonb_agg(to_jsonb(r) ORDER BY r.moved_at, r.allocation_id) FROM (
      SELECT * FROM shares ORDER BY moved_at, allocation_id LIMIT 5000) r), '[]'::jsonb));
$$;

-- 4. Doctors summary. The NULL doctor row is money on lines without doctor
-- credit, so the rows add up to everything collected.
CREATE FUNCTION public.invoice_report_doctors(p_from date, p_to date, p_branch public.clinic_location)
RETURNS jsonb LANGUAGE sql STABLE SET search_path = '' AS $$
  WITH shares AS (SELECT * FROM public.invoice_report_shares(p_from, p_to, p_branch)),
  grouped AS (
    SELECT s.doctor_id, coalesce(max(st.full_name), max(s.doctor_name)) AS doctor_name,
      sum(s.share_minor) AS share_minor,
      coalesce(sum(s.share_minor) FILTER (WHERE s.method = 'cash'), 0) AS cash_minor,
      coalesce(sum(s.share_minor) FILTER (WHERE s.method = 'visa'), 0) AS visa_minor,
      coalesce(sum(s.share_minor) FILTER (WHERE s.method IS NULL), 0) AS moved_minor
    FROM shares s LEFT JOIN public.staff st ON st.id = s.doctor_id GROUP BY s.doctor_id
  )
  SELECT jsonb_build_object(
    'totals', (SELECT jsonb_build_object(
      'share_minor', coalesce(sum(share_minor), 0),
      'cash_minor', coalesce(sum(share_minor) FILTER (WHERE method = 'cash'), 0),
      'visa_minor', coalesce(sum(share_minor) FILTER (WHERE method = 'visa'), 0),
      'moved_minor', coalesce(sum(share_minor) FILTER (WHERE method IS NULL), 0)) FROM shares),
    'rows', coalesce((SELECT jsonb_agg(to_jsonb(g)
      ORDER BY (g.doctor_id IS NULL), g.share_minor DESC, g.doctor_name) FROM grouped g), '[]'::jsonb));
$$;

-- 5. Outstanding balances as of now, by the invoice's branch.
CREATE FUNCTION public.invoice_report_outstanding(p_branch public.clinic_location)
RETURNS jsonb LANGUAGE sql STABLE SET search_path = '' AS $$
  WITH open AS (
    SELECT i.patient_id, i.file_number, i.invoice_date, f.due_minor
    FROM public.invoices i CROSS JOIN LATERAL public.invoice_figures(i.id) f
    WHERE i.voided_at IS NULL AND f.due_minor > 0 AND (p_branch IS NULL OR i.branch = p_branch)
  ), grouped AS (
    SELECT o.patient_id, p.full_name AS patient_name, max(o.file_number) AS file_number,
      count(*) AS open_invoices, sum(o.due_minor) AS due_minor, min(o.invoice_date) AS oldest_date
    FROM open o JOIN public.patients p ON p.id = o.patient_id GROUP BY o.patient_id, p.full_name
  )
  SELECT jsonb_build_object(
    'totals', (SELECT jsonb_build_object('due_minor', coalesce(sum(due_minor), 0),
      'open_invoices', coalesce(sum(open_invoices), 0), 'row_count', count(*)) FROM grouped),
    'rows', coalesce((SELECT jsonb_agg(to_jsonb(r) ORDER BY r.due_minor DESC, r.patient_name) FROM (
      SELECT * FROM grouped ORDER BY due_minor DESC, patient_name LIMIT 5000) r), '[]'::jsonb));
$$;

-- 6. Services sold on invoices dated in the range (by the invoice's branch):
-- units, current billed value and money collected on those lines to date.
CREATE FUNCTION public.invoice_report_services(p_from date, p_to date, p_branch public.clinic_location)
RETURNS jsonb LANGUAGE sql STABLE SET search_path = '' AS $$
  WITH sold AS (
    SELECT l.id AS line_id, l.service_id, l.service_type, l.quantity, f.value_minor AS billed_minor,
      f.collected_minor, i.id AS invoice_id, i.number AS invoice_number, i.branch AS invoice_branch,
      i.invoice_date, i.created_at, i.patient_id, i.patient_name, i.file_number
    FROM public.invoices i
    CROSS JOIN LATERAL public.invoice_line_figures(i.id) f
    JOIN public.invoice_lines l ON l.id = f.line_id
    WHERE i.voided_at IS NULL AND i.invoice_date BETWEEN p_from AND p_to
      AND (p_branch IS NULL OR i.branch = p_branch)
  ), grouped AS (
    SELECT s.service_id, c.name AS service_name, c.service_type, sum(s.quantity) AS units,
      count(DISTINCT s.invoice_id) AS invoice_count, sum(s.billed_minor) AS billed_minor,
      sum(s.collected_minor) AS collected_minor
    FROM sold s JOIN public.service_catalog c ON c.id = s.service_id
    GROUP BY s.service_id, c.name, c.service_type
  )
  SELECT jsonb_build_object(
    'totals', (SELECT jsonb_build_object('units', coalesce(sum(quantity), 0),
      'billed_minor', coalesce(sum(billed_minor), 0),
      'collected_minor', coalesce(sum(collected_minor), 0), 'row_count', count(*)) FROM sold),
    'rows', coalesce((SELECT jsonb_agg(to_jsonb(g) ORDER BY g.billed_minor DESC, g.service_name)
      FROM grouped g), '[]'::jsonb),
    'lines', coalesce((SELECT jsonb_agg(to_jsonb(r) ORDER BY r.invoice_date, r.created_at, r.line_id) FROM (
      SELECT * FROM sold ORDER BY invoice_date, created_at, line_id LIMIT 5000) r), '[]'::jsonb));
$$;

REVOKE ALL ON FUNCTION
  public.invoice_report_allocations(date, date, public.clinic_location),
  public.invoice_report_shares(date, date, public.clinic_location),
  public.invoice_report_money(date, date, public.clinic_location),
  public.invoice_report_revenue(date, date, public.clinic_location, uuid),
  public.invoice_report_doctor(date, date, public.clinic_location, uuid),
  public.invoice_report_doctors(date, date, public.clinic_location),
  public.invoice_report_outstanding(public.clinic_location),
  public.invoice_report_services(date, date, public.clinic_location)
  FROM PUBLIC, anon, authenticated;

-- Client entry point. Payment receptionists and super admins only.
CREATE FUNCTION public.invoice_report(p_kind text, p_from date, p_to date,
  p_branch public.clinic_location DEFAULT NULL, p_doctor uuid DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  IF NOT public.invoice_can('manage') THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE = '42501';
  END IF;
  IF p_from IS NULL OR p_to IS NULL OR p_to < p_from OR p_to - p_from > 366
    OR p_kind IS NULL OR p_kind NOT IN ('money', 'revenue', 'doctor', 'doctors', 'outstanding', 'services')
    OR (p_kind = 'doctor' AND p_doctor IS NULL) THEN
    RAISE EXCEPTION 'Invalid report request' USING ERRCODE = '22023';
  END IF;
  RETURN CASE p_kind
    WHEN 'money' THEN public.invoice_report_money(p_from, p_to, p_branch)
    WHEN 'revenue' THEN public.invoice_report_revenue(p_from, p_to, p_branch, p_doctor)
    WHEN 'doctor' THEN public.invoice_report_doctor(p_from, p_to, p_branch, p_doctor)
    WHEN 'doctors' THEN public.invoice_report_doctors(p_from, p_to, p_branch)
    WHEN 'outstanding' THEN public.invoice_report_outstanding(p_branch)
    WHEN 'services' THEN public.invoice_report_services(p_from, p_to, p_branch)
  END;
END;
$$;
REVOKE ALL ON FUNCTION public.invoice_report(text, date, date, public.clinic_location, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.invoice_report(text, date, date, public.clinic_location, uuid) TO authenticated;
