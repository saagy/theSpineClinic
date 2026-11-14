-- Billing reports: a refund's rows say which money left the drawer.
--
-- A refund's line allocations mix two things: money handed back to the
-- patient, and paid money that moved from a reduced service to services that
-- still had a balance. Before this change every row of a refund carried the
-- refund's payback method, so moved money looked like cash or Visa coming in.
-- Now each refund row is split: the money handed back keeps the payback
-- method, and everything else is a refund adjustment (method NULL).
--
-- Only lines that lost money can hold money handed back. The payback is
-- shared between them in proportion to what each lost, with cumulative
-- integer division so the parts add up exactly. Totals are unchanged: a
-- refund's cash or Visa rows still add up to its payback, its adjustment rows
-- add up to zero, and each line and doctor keeps the same net amount.
-- Stored allocations are not touched; only how reports read them changes.

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
  SELECT s.id, s.line_id, s.recorded_at, s.branch, 'refund', s.number, part.method, part.amount
  FROM (
    SELECT a.id, a.line_id, a.amount_minor, rf.recorded_at, rf.branch, rf.number,
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
