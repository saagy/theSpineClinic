-- Invoice issuing, permissions, discounts, receipts, refunds and allocations.
-- Requires test/invoice_fixture.sql immediately before this file.
SET LOCAL ROLE authenticated;
DO $$
DECLARE
  cashier constant text := 'a5000000-0000-0000-0000-000000000002';
  desk constant text := 'a5000000-0000-0000-0000-000000000003';
  doctor constant text := 'a5000000-0000-0000-0000-000000000004';
  dr_a constant text := 'a6000000-0000-0000-0000-000000000004';
  dr_b constant text := 'a6000000-0000-0000-0000-000000000005';
  pt_single uuid; pt_six uuid; tr_six uuid; assess uuid;
  inv uuid; refund_line uuid; tr_line uuid; req uuid := gen_random_uuid(); first jsonb;
BEGIN
  -- Catalog: payment receptionists manage it; others cannot.
  PERFORM pg_temp.denied(desk, 'service_save', '{"name":"X"}');
  PERFORM pg_temp.denied(doctor, 'service_save', '{"name":"X"}');
  pt_single := pg_temp.ok(cashier, 'service_save', '{"name":"PT session","service_type":"pt_session",
    "sessions_per_unit":1,"price_minor":50000,"attributes_doctors":true,"active":true}', 'document_id');
  pt_six := pg_temp.ok(cashier, 'service_save', '{"name":"6 PT sessions","service_type":"pt_session",
    "sessions_per_unit":6,"price_minor":300000,"attributes_doctors":true,"active":true}', 'document_id');
  tr_six := pg_temp.ok(cashier, 'service_save', '{"name":"6 traction sessions","service_type":"traction_session",
    "sessions_per_unit":6,"price_minor":120000,"attributes_doctors":false,"active":true}', 'document_id');
  assess := pg_temp.ok(cashier, 'service_save', '{"name":"Initial assessment","service_type":"initial_assessment",
    "sessions_per_unit":1,"price_minor":80000,"attributes_doctors":true,"active":true}', 'document_id');
  PERFORM pg_temp.fails(cashier, 'service_save', '{"name":" pt SESSION","service_type":"pt_session",
    "sessions_per_unit":1,"price_minor":1,"attributes_doctors":true,"active":true}', 'duplicate');
  PERFORM pg_temp.fails(cashier, 'service_save', '{"name":"Assessment pack","service_type":"reassessment",
    "sessions_per_unit":6,"price_minor":1,"attributes_doctors":true,"active":true}', 'invalid_request');
  PERFORM pg_temp.fails(cashier, 'service_save', jsonb_build_object('id', assess, 'version', 9,
    'name','Initial assessment','service_type','initial_assessment','sessions_per_unit',1,
    'price_minor',1,'attributes_doctors',true,'active',true), 'stale');

  -- Front desk issues and collects, split between two doctors and a no-doctor line.
  PERFORM pg_temp.denied(doctor, 'invoice_create', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_single, 1))));
  inv := pg_temp.ok(desk, 'invoice_create', pg_temp.bill(jsonb_build_array(
    pg_temp.line(pt_six, 1, ARRAY[dr_a, dr_b]), pg_temp.line(tr_six, 1)),
    '[{"method":"cash","amount_minor":100000}]'));
  PERFORM pg_temp.expect(inv, 420000, 100000, 320000, 'partially_paid');
  IF (SELECT pt FROM pg_temp.balance()) IS DISTINCT FROM 6 OR (SELECT traction FROM pg_temp.balance()) IS DISTINCT FROM 6 THEN
    RAISE EXCEPTION 'Package sessions not granted';
  END IF;
  IF (SELECT array_agg(collected_minor ORDER BY line_position) FROM public.invoice_line_figures(inv))
    IS DISTINCT FROM ARRAY[71428, 28572]::bigint[] THEN RAISE EXCEPTION 'Receipt not split by line value'; END IF;
  IF (SELECT count(*) FROM public.invoice_line_doctors d JOIN public.invoice_lines l ON l.id = d.line_id
    WHERE l.invoice_id = inv) IS DISTINCT FROM 2 THEN RAISE EXCEPTION 'Line doctors missing'; END IF;

  -- Front desk limits and validation.
  PERFORM pg_temp.fails(desk, 'invoice_create', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_single, 1)),
    '[]', '{"kind":"percent","value":1000}'), 'discount_not_allowed');
  -- The front desk dates invoices today; only payment staff use a past date.
  PERFORM pg_temp.fails(desk, 'invoice_create', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_single, 1)))
    || jsonb_build_object('invoice_date', (now() AT TIME ZONE public.clinic_timezone())::date - 1),
    'backdate_not_allowed');
  PERFORM pg_temp.fails(desk, 'invoice_create',
    pg_temp.bill(jsonb_build_array(pg_temp.line(tr_six, 1, ARRAY[dr_a]))), 'invalid_doctors');
  PERFORM pg_temp.fails(desk, 'invoice_create', pg_temp.bill(jsonb_build_array(
    pg_temp.line(pt_single, 1) || '{"unit_price_minor":1}')), 'catalog_changed');
  PERFORM pg_temp.fails(desk, 'invoice_create', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_single, 1)))
    || jsonb_build_object('invoice_date', (now() AT TIME ZONE public.clinic_timezone())::date + 1), 'invalid_invoice');
  PERFORM pg_temp.fails(desk, 'invoice_create', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_single, 1)),
    '[{"method":"cash","amount_minor":60000}]'), 'receipt_limit');
  PERFORM pg_temp.fails(desk, 'receipt_create', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'amount_minor', 320001, 'method', 'visa', 'branch', 'tagamoa'), 'receipt_limit');
  PERFORM pg_temp.fails(desk, 'receipt_create', jsonb_build_object('id', inv, 'version', 99,
    'amount_minor', 1, 'method', 'visa', 'branch', 'tagamoa'), 'stale');
  PERFORM pg_temp.ok(desk, 'receipt_create', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'amount_minor', 320000, 'method', 'visa', 'branch', 'masr_elgedida'));
  PERFORM pg_temp.expect(inv, 420000, 420000, 0, 'paid');
  PERFORM pg_temp.denied(desk, 'refund_create', jsonb_build_object('id', inv));

  -- Refund example 1: paid 3,000, 4 unused sessions, 1,800 agreed and paid back.
  inv := pg_temp.ok(cashier, 'invoice_create', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_six, 1, ARRAY[dr_a])),
    '[{"method":"cash","amount_minor":300000}]'));
  refund_line := (SELECT id FROM public.invoice_lines WHERE invoice_id = inv);
  PERFORM pg_temp.fails(cashier, 'refund_create', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'branch', 'tagamoa', 'reason', 'Stopping', 'payback_minor', 0, 'payback_method', 'cash',
    'lines', jsonb_build_array(jsonb_build_object('line_id', refund_line, 'sessions', 4, 'value_minor', 180000))), 'stale');
  PERFORM pg_temp.fails(cashier, 'refund_create', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'branch', 'tagamoa', 'reason', 'Stopping', 'payback_minor', 180000, 'payback_method', 'cash',
    'lines', jsonb_build_array(jsonb_build_object('line_id', refund_line, 'sessions', 7, 'value_minor', 180000))), 'refund_limit');
  PERFORM pg_temp.ok(cashier, 'refund_create', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'branch', 'tagamoa', 'reason', 'Stopping', 'payback_minor', 180000, 'payback_method', 'cash',
    'lines', jsonb_build_array(jsonb_build_object('line_id', refund_line, 'sessions', 4, 'value_minor', 180000))));
  PERFORM pg_temp.expect(inv, 120000, 120000, 0, 'refunded');
  IF (SELECT pt FROM pg_temp.balance()) IS DISTINCT FROM 8 THEN RAISE EXCEPTION 'Refund did not cancel sessions'; END IF;

  -- Example 2: paid 1,000; the patient owes nothing more; nothing is paid back.
  inv := pg_temp.ok(cashier, 'invoice_create', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_six, 1)),
    '[{"method":"visa","amount_minor":100000}]'));
  PERFORM pg_temp.ok(cashier, 'refund_create', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'branch', 'tagamoa', 'reason', 'Stopping', 'payback_minor', 0, 'lines', jsonb_build_array(jsonb_build_object(
      'line_id', (SELECT id FROM public.invoice_lines WHERE invoice_id = inv), 'sessions', 4, 'value_minor', 200000))));
  PERFORM pg_temp.expect(inv, 100000, 100000, 0, 'refunded');

  -- Example 3: paid 1,000; 200 is still owed after the agreed refund.
  inv := pg_temp.ok(cashier, 'invoice_create', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_six, 1)),
    '[{"method":"cash","amount_minor":100000}]'));
  PERFORM pg_temp.ok(cashier, 'refund_create', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'branch', 'tagamoa', 'reason', 'Stopping', 'payback_minor', 0, 'lines', jsonb_build_array(jsonb_build_object(
      'line_id', (SELECT id FROM public.invoice_lines WHERE invoice_id = inv), 'sessions', 4, 'value_minor', 180000))));
  PERFORM pg_temp.expect(inv, 120000, 100000, 20000, 'partially_paid');

  -- Free session and fixed discount, both recorded with exact line splits.
  inv := pg_temp.ok(cashier, 'invoice_create', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_single, 1)),
    '[]', '{"kind":"percent","value":10000}'));
  PERFORM pg_temp.expect(inv, 0, 0, 0, 'paid');
  inv := pg_temp.ok(cashier, 'invoice_create', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_single, 2),
    pg_temp.line(assess, 1)), '[{"method":"cash","amount_minor":10000},{"method":"visa","amount_minor":5000}]',
    '{"kind":"amount","value":5001}'));
  PERFORM pg_temp.expect(inv, 174999, 15000, 159999, 'partially_paid');
  IF (SELECT array_agg(discount_minor ORDER BY position) FROM public.invoice_lines WHERE invoice_id = inv)
    IS DISTINCT FROM ARRAY[2778, 2223]::bigint[] THEN RAISE EXCEPTION 'Discount not split by line value'; END IF;
  PERFORM pg_temp.fails(cashier, 'invoice_create', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_single, 1)),
    '[]', '{"kind":"amount","value":50001}'), 'invalid_discount');

  -- A refund on one line moves leftover money to lines that still have room.
  inv := pg_temp.ok(cashier, 'invoice_create', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_six, 1, ARRAY[dr_a]),
    pg_temp.line(tr_six, 1)), '[{"method":"cash","amount_minor":210000}]'));
  tr_line := (SELECT id FROM public.invoice_lines WHERE invoice_id = inv AND position = 2);
  PERFORM pg_temp.ok(cashier, 'refund_create', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'branch', 'tagamoa', 'reason', 'PT not needed', 'payback_minor', 90000, 'payback_method', 'visa',
    'lines', jsonb_build_array(jsonb_build_object('line_id',
      (SELECT id FROM public.invoice_lines WHERE invoice_id = inv AND position = 1), 'sessions', 6, 'value_minor', 300000))));
  PERFORM pg_temp.expect(inv, 120000, 120000, 0, 'refunded');
  IF (SELECT collected_minor FROM public.invoice_line_figures(inv) WHERE line_id = tr_line) IS DISTINCT FROM 120000 THEN
    RAISE EXCEPTION 'Freed money did not move to the open line';
  END IF;

  -- Retries return the stored outcome; a changed payload under the same ID is rejected.
  PERFORM set_config('request.jwt.claim.sub', desk, true);
  first := public.execute_invoice_command(req, 'invoice_create', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_single, 1))));
  IF public.execute_invoice_command(req, 'invoice_create', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_single, 1))))
    IS DISTINCT FROM first OR (SELECT count(*) FROM public.invoices WHERE id = (first->>'invoice_id')::uuid) IS DISTINCT FROM 1 THEN
    RAISE EXCEPTION 'Retry was not idempotent';
  END IF;
  BEGIN
    PERFORM public.execute_invoice_command(req, 'invoice_create', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_single, 2))));
    RAISE EXCEPTION 'Changed retry payload accepted';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;

  -- Doctors read nothing; numbers are sequential per branch and kind.
  PERFORM set_config('request.jwt.claim.sub', doctor, true);
  IF (SELECT count(*) FROM public.invoice_register) IS DISTINCT FROM 0 OR public.invoice_detail(inv) IS NOT NULL THEN
    RAISE EXCEPTION 'Doctor can read invoices';
  END IF;
  PERFORM set_config('request.jwt.claim.sub', desk, true);
  IF (SELECT array_agg(number ORDER BY number) FROM public.invoices WHERE branch = 'tagamoa')
    IS DISTINCT FROM ARRAY[1,2,3,4,5,6,7,8]::bigint[] THEN RAISE EXCEPTION 'Invoice numbering has gaps'; END IF;
END;
$$;
ROLLBACK;
