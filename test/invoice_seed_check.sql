-- Verifies the seeded demo data obeys every invoice invariant.
DO $$
DECLARE r record;
BEGIN
  IF (SELECT count(*) FROM public.service_catalog) <> 10 OR (SELECT count(*) FROM public.invoices) < 150 THEN
    RAISE EXCEPTION 'Seed volume too small: % invoices', (SELECT count(*) FROM public.invoices);
  END IF;
  FOR r IN SELECT i.id, i.net_collected_minor, i.value_minor, i.due_minor FROM public.invoice_register i LOOP
    IF r.net_collected_minor < 0 OR r.net_collected_minor > r.value_minor OR r.due_minor < 0
      OR (SELECT coalesce(sum(collected_minor), 0) FROM public.invoice_line_figures(r.id)) <> r.net_collected_minor
      OR EXISTS (SELECT 1 FROM public.invoice_line_figures(r.id) WHERE collected_minor < 0
        OR collected_minor > value_minor OR sessions_left < 0) THEN
      RAISE EXCEPTION 'Invoice % does not reconcile', r.id;
    END IF;
  END LOOP;
  IF EXISTS (SELECT 1 FROM public.patients p WHERE p.session_balance <> coalesce((SELECT sum(s.pt)
      FROM public.invoices i CROSS JOIN LATERAL public.invoice_remaining_sessions(i.id) s
      WHERE i.patient_id = p.id AND i.voided_at IS NULL), 0)) THEN
    RAISE EXCEPTION 'Session balances do not match invoices';
  END IF;
  IF (SELECT count(DISTINCT status) FROM public.invoice_register) <> 5
    OR NOT EXISTS (SELECT 1 FROM public.invoice_refunds WHERE payback_minor > 0)
    OR NOT EXISTS (SELECT 1 FROM public.invoice_refunds WHERE payback_minor = 0)
    OR NOT EXISTS (SELECT 1 FROM public.invoice_receipts WHERE replaces_receipt_id IS NOT NULL)
    OR NOT EXISTS (SELECT 1 FROM public.invoices WHERE replaces_invoice_id IS NOT NULL)
    OR NOT EXISTS (SELECT 1 FROM public.invoice_receipts WHERE voided_at IS NOT NULL AND
      NOT EXISTS (SELECT 1 FROM public.invoice_receipts n WHERE n.replaces_receipt_id = invoice_receipts.id)) THEN
    RAISE EXCEPTION 'Seed is missing a scenario: %', (SELECT jsonb_object_agg(status, n) FROM
      (SELECT status, count(*) n FROM public.invoice_register GROUP BY status) s);
  END IF;
  IF EXISTS (SELECT 1 FROM public.invoice_receipts WHERE received_at > now() OR recorded_at > now()
      OR received_at > recorded_at OR (replaces_receipt_id IS NULL
        AND received_at < (SELECT created_at FROM public.invoices WHERE id = invoice_id)))
    OR EXISTS (SELECT 1 FROM public.invoices WHERE created_at > now()
      OR (created_at AT TIME ZONE public.clinic_timezone())::date < invoice_date) THEN
    RAISE EXCEPTION 'Seed timestamps are out of order';
  END IF;
END;
$$;
