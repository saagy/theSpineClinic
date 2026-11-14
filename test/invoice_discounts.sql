-- Discounts on an issued invoice: permissions, the split between lines,
-- money handed back, the refund barrier, cancelling, reports and the
-- invoice keeping its number and receipts.
-- Requires test/invoice_fixture.sql immediately before this file.
SET LOCAL ROLE authenticated;
DO $$
DECLARE
  cashier constant text := 'a5000000-0000-0000-0000-000000000002';
  desk constant text := 'a5000000-0000-0000-0000-000000000003';
  dr_a constant text := 'a6000000-0000-0000-0000-000000000004';
  today date := (now() AT TIME ZONE public.clinic_timezone())::date;
  pt_six uuid; tr_six uuid; inv uuid; free_inv uuid; receipt uuid; first_discount uuid;
  second_discount uuid; refund uuid; pt_line uuid; report jsonb; revenue jsonb;
BEGIN
  pt_six := pg_temp.ok(cashier, 'service_save', '{"name":"6 PT sessions","service_type":"pt_session",
    "sessions_per_unit":6,"price_minor":300000,"attributes_doctors":true,"active":true}', 'document_id');
  tr_six := pg_temp.ok(cashier, 'service_save', '{"name":"6 traction sessions","service_type":"traction_session",
    "sessions_per_unit":6,"price_minor":120000,"attributes_doctors":false,"active":true}', 'document_id');

  -- The front desk issues the invoice and takes a first payment.
  inv := pg_temp.ok(desk, 'invoice_create', pg_temp.bill(jsonb_build_array(
    pg_temp.line(pt_six, 1, ARRAY[dr_a]), pg_temp.line(tr_six, 1)),
    '[{"method":"cash","amount_minor":210000}]'));
  receipt := (SELECT id FROM public.invoice_receipts WHERE invoice_id = inv);
  pt_line := (SELECT id FROM public.invoice_lines WHERE invoice_id = inv AND position = 1);
  PERFORM pg_temp.expect(inv, 420000, 210000, 210000, 'partially_paid');

  -- Only payment staff give discounts, always with a reason.
  PERFORM pg_temp.denied(desk, 'discount_create', jsonb_build_object('id', inv));
  PERFORM pg_temp.fails(cashier, 'discount_create', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'discount', '{"kind":"percent","value":1000}'::jsonb, 'payback_minor', 0, 'branch', 'tagamoa'), 'reason_required');
  PERFORM pg_temp.fails(cashier, 'discount_create', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'discount', '{"kind":"percent","value":0}'::jsonb, 'payback_minor', 0, 'branch', 'tagamoa',
    'reason', 'Loyal patient'), 'invalid_discount');
  PERFORM pg_temp.fails(cashier, 'discount_create', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'discount', '{"kind":"amount","value":420001}'::jsonb, 'payback_minor', 0, 'branch', 'tagamoa',
    'reason', 'Loyal patient'), 'invalid_discount');
  PERFORM pg_temp.fails(cashier, 'discount_create', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'discount', '{"kind":"percent","value":1000}'::jsonb, 'payback_minor', 100, 'branch', 'tagamoa',
    'reason', 'Loyal patient'), 'stale');

  -- 10% of 4,200 is 420, split 300 to PT and 120 to traction. Nothing is
  -- handed back: the 2,100 paid is below the new value of 3,780.
  first_discount := pg_temp.ok(cashier, 'discount_create', jsonb_build_object('id', inv,
    'version', pg_temp.version(inv), 'discount', '{"kind":"percent","value":1000}'::jsonb, 'payback_minor', 0,
    'branch', 'tagamoa', 'reason', 'Head receptionist approved 10%'), 'document_id');
  PERFORM pg_temp.expect(inv, 378000, 210000, 168000, 'partially_paid');
  IF (SELECT array_agg(value_minor ORDER BY line_position) FROM public.invoice_line_figures(inv))
    IS DISTINCT FROM ARRAY[270000, 108000]::bigint[] THEN RAISE EXCEPTION 'Discount not split by line value'; END IF;
  IF (SELECT row(kind, number, payback_minor, payback_method) FROM public.invoice_refunds WHERE id = first_discount)
    IS DISTINCT FROM row('discount'::text, 1::bigint, 0::bigint, NULL::text) THEN
    RAISE EXCEPTION 'Discount document not numbered in its own series';
  END IF;
  IF (SELECT row(refunded_minor, later_discount_minor, number, discount_minor) FROM public.invoice_register WHERE id = inv)
    IS DISTINCT FROM row(0::bigint, 42000::bigint, 1::bigint, 0::bigint)
    OR (SELECT count(*) FROM public.invoice_receipts WHERE invoice_id = inv AND voided_at IS NULL) <> 1
    OR EXISTS (SELECT 1 FROM public.invoice_receipts WHERE id = receipt AND voided_at IS NOT NULL) THEN
    RAISE EXCEPTION 'A discount must keep the invoice number and its receipts';
  END IF;
  IF (SELECT row(pt, traction) FROM pg_temp.balance()) IS DISTINCT FROM row(6, 6) THEN
    RAISE EXCEPTION 'A discount must not change session balances';
  END IF;

  -- Paid in full, then a second discount hands 500 back in cash.
  PERFORM pg_temp.ok(desk, 'receipt_create', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'amount_minor', 168000, 'method', 'visa', 'branch', 'tagamoa'));
  PERFORM pg_temp.expect(inv, 378000, 378000, 0, 'paid');
  PERFORM pg_temp.fails(cashier, 'discount_create', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'discount', '{"kind":"amount","value":50000}'::jsonb, 'payback_minor', 50000, 'branch', 'tagamoa',
    'reason', 'Goodwill'), 'invalid_request');
  second_discount := pg_temp.ok(cashier, 'discount_create', jsonb_build_object('id', inv,
    'version', pg_temp.version(inv), 'discount', '{"kind":"amount","value":50000}'::jsonb, 'payback_minor', 50000,
    'payback_method', 'cash', 'branch', 'tagamoa', 'reason', 'Goodwill'), 'document_id');
  -- A discount is not a refund: the paid invoice stays Paid.
  PERFORM pg_temp.expect(inv, 328000, 328000, 0, 'paid');
  IF (SELECT number FROM public.invoice_refunds WHERE id = second_discount) <> 2 THEN
    RAISE EXCEPTION 'Discount numbers must run on';
  END IF;

  -- The handed-back money leaves the drawer under the discount's name, and
  -- the revenue report still adds up to the drawer.
  PERFORM set_config('request.jwt.claim.sub', cashier, true);
  report := public.invoice_report('money', today, today, NULL, NULL);
  IF (report#>>'{totals,cash_out_minor}')::bigint <> 50000
    OR NOT EXISTS (SELECT 1 FROM jsonb_array_elements(report->'rows') r
      WHERE r->>'kind' = 'discount' AND (r->>'amount_minor')::bigint = 50000 AND r->>'method' = 'cash') THEN
    RAISE EXCEPTION 'Money report misses the discount payback: %', report->'totals';
  END IF;
  revenue := public.invoice_report('revenue', today, today, NULL, NULL);
  IF (revenue#>>'{totals,collected_minor}')::bigint <> 328000
    OR (revenue#>>'{totals,moved_minor}')::bigint <> 0
    OR EXISTS (SELECT 1 FROM jsonb_array_elements(revenue->'rows') r WHERE r->>'kind' = 'refund') THEN
    RAISE EXCEPTION 'Revenue report does not reconcile with discounts: %', revenue->'totals';
  END IF;

  -- Earlier money documents are locked by the later discount; editing and
  -- cancelling the invoice wait until the discounts are cancelled.
  PERFORM pg_temp.fails(cashier, 'receipt_void', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'receipt_id', receipt, 'reason', 'Mistake'), 'refund_after');
  PERFORM pg_temp.fails(cashier, 'refund_void', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'refund_id', first_discount, 'reason', 'Mistake'), 'refund_after');
  PERFORM pg_temp.fails(cashier, 'invoice_void_all', jsonb_build_object('id', inv,
    'version', pg_temp.version(inv), 'reason', 'Mistake'), 'refunds_first');

  -- A refund after a discount works from the discounted line value.
  PERFORM pg_temp.fails(cashier, 'refund_create', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'lines', jsonb_build_array(jsonb_build_object('line_id', pt_line, 'sessions', 0, 'value_minor', 300000)),
    'payback_minor', 300000, 'payback_method', 'cash', 'branch', 'tagamoa', 'reason', 'Stops PT'), 'refund_limit');
  refund := pg_temp.ok(cashier, 'refund_create', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'lines', jsonb_build_array(jsonb_build_object('line_id', pt_line, 'sessions', 2, 'value_minor', 80000)),
    'payback_minor', 80000, 'payback_method', 'cash', 'branch', 'tagamoa', 'reason', 'Stops PT'), 'document_id');
  PERFORM pg_temp.expect(inv, 248000, 248000, 0, 'refunded');
  IF (SELECT row(refunded_minor, later_discount_minor) FROM public.invoice_register WHERE id = inv)
    IS DISTINCT FROM row(80000::bigint, 92000::bigint) THEN RAISE EXCEPTION 'Refunds and discounts mixed up'; END IF;

  -- Cancelling, latest first, restores the value and the money handed back.
  PERFORM pg_temp.ok(cashier, 'refund_void', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'refund_id', refund, 'reason', 'Entered by mistake'));
  PERFORM pg_temp.ok(cashier, 'refund_void', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'refund_id', second_discount, 'reason', 'Entered by mistake'));
  PERFORM pg_temp.expect(inv, 378000, 378000, 0, 'paid');
  report := public.invoice_report('money', today, today, NULL, NULL);
  IF (report#>>'{totals,cash_out_minor}')::bigint <> 0
    OR NOT EXISTS (SELECT 1 FROM jsonb_array_elements(report->'voids') v
      WHERE v->>'kind' = 'discount' AND (v->>'amount_minor')::bigint = 50000) THEN
    RAISE EXCEPTION 'Cancelled discount missing from the cancelled list';
  END IF;
  PERFORM pg_temp.fails(cashier, 'invoice_correct', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'reason', 'Wrong doctor', 'invoice', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_six, 1)))), 'has_refunds');

  -- A 100% discount makes an unpaid invoice free; nothing is left to discount.
  free_inv := pg_temp.ok(desk, 'invoice_create', pg_temp.bill(jsonb_build_array(pg_temp.line(tr_six, 1))));
  PERFORM pg_temp.ok(cashier, 'discount_create', jsonb_build_object('id', free_inv,
    'version', pg_temp.version(free_inv), 'discount', '{"kind":"percent","value":10000}'::jsonb, 'payback_minor', 0,
    'branch', 'tagamoa', 'reason', 'Free sessions for staff family'));
  PERFORM pg_temp.expect(free_inv, 0, 0, 0, 'paid');
  PERFORM pg_temp.fails(cashier, 'discount_create', jsonb_build_object('id', free_inv,
    'version', pg_temp.version(free_inv), 'discount', '{"kind":"percent","value":1000}'::jsonb, 'payback_minor', 0,
    'branch', 'tagamoa', 'reason', 'Again'), 'invalid_discount');
END;
$$;
ROLLBACK;
