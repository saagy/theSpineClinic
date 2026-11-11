-- Read side for the Payments tab. Security-invoker objects run under the
-- caller's RLS, so only staff with the issue capability see any rows.

GRANT EXECUTE ON FUNCTION public.invoice_line_figures(uuid), public.invoice_figures(uuid),
  public.invoice_remaining_sessions(uuid) TO authenticated;

CREATE VIEW public.invoice_register WITH (security_invoker = true) AS
SELECT i.*, f.refunded_minor, f.value_minor, f.received_minor, f.paid_back_minor,
  f.net_collected_minor, CASE WHEN i.voided_at IS NULL THEN f.due_minor ELSE 0 END AS due_minor,
  CASE
    WHEN i.voided_at IS NOT NULL THEN 'voided'
    WHEN f.due_minor = 0 AND f.refunded_minor > 0 THEN 'refunded'
    WHEN f.due_minor = 0 THEN 'paid'
    WHEN f.net_collected_minor > 0 THEN 'partially_paid'
    ELSE 'unpaid'
  END AS status,
  s.services, s.doctors
FROM public.invoices i
CROSS JOIN LATERAL public.invoice_figures(i.id) f
LEFT JOIN LATERAL (
  SELECT string_agg(CASE WHEN l.quantity > 1 THEN l.quantity || ' × ' ELSE '' END || l.service_name,
      ', ' ORDER BY l.position) AS services,
    (SELECT coalesce(jsonb_agg(DISTINCT d.doctor_name), '[]'::jsonb)
      FROM public.invoice_line_doctors d JOIN public.invoice_lines dl ON dl.id = d.line_id
      WHERE dl.invoice_id = i.id) AS doctors
  FROM public.invoice_lines l WHERE l.invoice_id = i.id
) s ON true;
GRANT SELECT ON public.invoice_register TO authenticated;

-- Complete invoice document: figures, lines with doctors and remaining
-- amounts, receipts and refunds (each with its refund lines), oldest first.
CREATE FUNCTION public.invoice_detail(p_id uuid)
RETURNS jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $$
  SELECT to_jsonb(r) || jsonb_build_object(
    'lines', coalesce((SELECT jsonb_agg(to_jsonb(l) || jsonb_build_object(
        'value_minor', f.value_minor, 'collected_minor', f.collected_minor,
        'sessions_left', f.sessions_left,
        'doctors', coalesce((SELECT jsonb_agg(jsonb_build_object('id', d.doctor_id, 'name', d.doctor_name)
          ORDER BY d.doctor_name) FROM public.invoice_line_doctors d WHERE d.line_id = l.id), '[]'::jsonb))
      ORDER BY l.position)
      FROM public.invoice_lines l JOIN public.invoice_line_figures(r.id) f ON f.line_id = l.id
      WHERE l.invoice_id = r.id), '[]'::jsonb),
    'receipts', coalesce((SELECT jsonb_agg(to_jsonb(rc) ORDER BY rc.recorded_at, rc.id)
      FROM public.invoice_receipts rc WHERE rc.invoice_id = r.id), '[]'::jsonb),
    'refunds', coalesce((SELECT jsonb_agg(to_jsonb(rf) || jsonb_build_object('lines',
        (SELECT jsonb_agg(to_jsonb(rl) ORDER BY rl.line_id) FROM public.invoice_refund_lines rl
          WHERE rl.refund_id = rf.id)) ORDER BY rf.recorded_at, rf.id)
      FROM public.invoice_refunds rf WHERE rf.invoice_id = r.id), '[]'::jsonb),
    'replaced_by', (SELECT jsonb_build_object('id', n.id, 'number', n.number, 'branch', n.branch)
      FROM public.invoices n WHERE n.replaces_invoice_id = r.id),
    'replaces', (SELECT jsonb_build_object('id', o.id, 'number', o.number, 'branch', o.branch)
      FROM public.invoices o WHERE o.id = r.replaces_invoice_id))
  FROM public.invoice_register r WHERE r.id = p_id;
$$;

-- Totals for a patient's Payments tab header. Voided invoices are excluded.
CREATE FUNCTION public.invoice_patient_summary(p_patient_id uuid,
  OUT due_minor bigint, OUT net_collected_minor bigint, OUT invoice_count integer,
  OUT open_count integer)
LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $$
  SELECT coalesce(sum(due_minor), 0)::bigint, coalesce(sum(net_collected_minor), 0)::bigint,
    count(*)::integer, (count(*) FILTER (WHERE due_minor > 0))::integer
  FROM public.invoice_register WHERE patient_id = p_patient_id AND voided_at IS NULL;
$$;

REVOKE ALL ON FUNCTION public.invoice_detail(uuid), public.invoice_patient_summary(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.invoice_detail(uuid), public.invoice_patient_summary(uuid) TO authenticated;
