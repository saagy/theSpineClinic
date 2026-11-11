-- Voids, corrections, the refund barrier, booked-session protection and
-- request resolution. Requires test/invoice_fixture.sql immediately before.
CREATE TEMP TABLE ids(name text PRIMARY KEY, id uuid);
GRANT ALL ON ids TO authenticated;
SET LOCAL ROLE authenticated;
DO $$
DECLARE
  cashier constant text := 'a5000000-0000-0000-0000-000000000002';
  desk constant text := 'a5000000-0000-0000-0000-000000000003';
  pt_six uuid; pt_one uuid; inv uuid; receipt uuid; fixed uuid; r public.invoice_receipts;
BEGIN
  pt_six := pg_temp.ok(cashier, 'service_save', '{"name":"6 PT sessions","service_type":"pt_session",
    "sessions_per_unit":6,"price_minor":300000,"attributes_doctors":true,"active":true}', 'document_id');
  pt_one := pg_temp.ok(cashier, 'service_save', '{"name":"PT session","service_type":"pt_session",
    "sessions_per_unit":1,"price_minor":50000,"attributes_doctors":true,"active":true}', 'document_id');
  INSERT INTO ids VALUES ('pt_six', pt_six), ('pt_one', pt_one);

  -- Receipt correction keeps when the money was received and links the original.
  inv := pg_temp.ok(desk, 'invoice_create', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_six, 1)),
    '[{"method":"cash","amount_minor":100000}]'));
  receipt := (SELECT id FROM public.invoice_receipts WHERE invoice_id = inv);
  PERFORM pg_temp.denied(desk, 'receipt_void', jsonb_build_object('id', inv));
  PERFORM pg_temp.fails(cashier, 'receipt_void', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'receipt_id', receipt, 'reason', '  '), 'reason_required');
  fixed := pg_temp.ok(cashier, 'receipt_correct', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'receipt_id', receipt, 'amount_minor', 150000, 'method', 'visa', 'branch', 'tagamoa',
    'reason', 'Wrong amount'), 'document_id');
  SELECT * INTO r FROM public.invoice_receipts WHERE id = fixed;
  IF r.replaces_receipt_id IS DISTINCT FROM receipt OR r.received_at IS DISTINCT FROM (SELECT received_at FROM public.invoice_receipts
    WHERE id = receipt) OR (SELECT voided_at FROM public.invoice_receipts WHERE id = receipt) IS NULL THEN
    RAISE EXCEPTION 'Receipt correction lost its audit link';
  END IF;
  PERFORM pg_temp.expect(inv, 300000, 150000, 150000, 'partially_paid');

  -- An invoice with active money cannot be voided; afterwards its sessions go.
  PERFORM pg_temp.fails(cashier, 'invoice_void', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'reason', 'Wrong patient'), 'has_payments');
  PERFORM pg_temp.ok(cashier, 'receipt_void', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'receipt_id', fixed, 'reason', 'Entered twice'));
  PERFORM pg_temp.ok(cashier, 'invoice_void', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'reason', 'Wrong patient'));
  PERFORM pg_temp.expect(inv, 300000, 0, 0, 'voided');
  PERFORM pg_temp.fails(cashier, 'invoice_void', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'reason', 'Again'), 'already_voided');
  IF (SELECT pt FROM pg_temp.balance()) IS DISTINCT FROM 0 THEN RAISE EXCEPTION 'Voided invoice kept its sessions'; END IF;

  -- A later refund blocks voiding earlier money until the refund is voided.
  inv := pg_temp.ok(cashier, 'invoice_create', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_six, 1)),
    '[{"method":"cash","amount_minor":300000}]'));
  receipt := (SELECT id FROM public.invoice_receipts WHERE invoice_id = inv);
  fixed := pg_temp.ok(cashier, 'refund_create', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'branch', 'tagamoa', 'reason', 'Stopping', 'payback_minor', 100000, 'payback_method', 'cash',
    'lines', jsonb_build_array(jsonb_build_object('line_id', (SELECT id FROM public.invoice_lines
      WHERE invoice_id = inv), 'sessions', 2, 'value_minor', 100000))), 'document_id');
  PERFORM pg_temp.fails(cashier, 'receipt_void', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'receipt_id', receipt, 'reason', 'Mistake'), 'refund_after');
  PERFORM pg_temp.fails(cashier, 'invoice_correct', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'reason', 'Fix', 'invoice', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_six, 1)))), 'has_refunds');
  PERFORM pg_temp.ok(cashier, 'refund_void', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'refund_id', fixed, 'reason', 'Refund entered by mistake'));
  PERFORM pg_temp.expect(inv, 300000, 300000, 0, 'paid');
  IF (SELECT pt FROM pg_temp.balance()) IS DISTINCT FROM 6 THEN RAISE EXCEPTION 'Voided refund did not restore sessions'; END IF;
  PERFORM pg_temp.ok(cashier, 'receipt_void', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'receipt_id', receipt, 'reason', 'Mistake'));
  INSERT INTO ids VALUES ('unpaid', inv);

  inv := pg_temp.ok(cashier, 'invoice_create', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_six, 1)),
    '[{"method":"cash","amount_minor":100000}]'));
  INSERT INTO ids VALUES ('used', inv);
END;
$$;

-- Simulate yesterday's payment, three used sessions and three future bookings.
RESET ROLE;
SELECT set_config('request.jwt.claim.sub', '', true);
UPDATE public.invoice_receipts SET received_at = received_at - interval '1 day'
  WHERE invoice_id = (SELECT id FROM ids WHERE name = 'used');
INSERT INTO public.appointments(patient_id, type, scheduled_at, status, use_package)
SELECT 'a7000000-0000-0000-0000-000000000001', 'normal_pt_session', now() + n * interval '1 day',
  'scheduled', true FROM generate_series(1, 3) n;
INSERT INTO public.appointments(patient_id, type, scheduled_at, status, use_package)
SELECT 'a7000000-0000-0000-0000-000000000001', 'normal_pt_session', now() - n * interval '1 day',
  'checked_in', true FROM generate_series(1, 3) n;
SET LOCAL ROLE authenticated;

DO $$
DECLARE
  cashier constant text := 'a5000000-0000-0000-0000-000000000002';
  desk constant text := 'a5000000-0000-0000-0000-000000000003';
  used uuid := (SELECT id FROM ids WHERE name = 'used');
  pt_six uuid := (SELECT id FROM ids WHERE name = 'pt_six');
  pt_one uuid := (SELECT id FROM ids WHERE name = 'pt_one');
  fixed uuid; original timestamptz; req uuid := gen_random_uuid();
BEGIN
  PERFORM set_config('request.jwt.claim.sub', cashier, true);
  IF (SELECT pt FROM pg_temp.balance()) IS DISTINCT FROM 9 THEN RAISE EXCEPTION 'Fixture balance %', pg_temp.balance(); END IF;
  original := (SELECT received_at FROM public.invoice_receipts WHERE invoice_id = used);
  PERFORM pg_temp.denied(desk, 'invoice_correct', jsonb_build_object('id', used));
  -- Correcting a partly used package succeeds; money moves with its original time.
  fixed := pg_temp.ok(cashier, 'invoice_correct', jsonb_build_object('id', used, 'version', pg_temp.version(used),
    'reason', 'Forgot discount', 'invoice', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_six, 1)), '[]',
      '{"kind":"percent","value":1000}')));
  PERFORM pg_temp.expect(used, 300000, 0, 0, 'voided');
  PERFORM pg_temp.expect(fixed, 270000, 100000, 170000, 'partially_paid');
  IF (SELECT replaces_invoice_id FROM public.invoices WHERE id = fixed) IS DISTINCT FROM used
    OR (SELECT received_at FROM public.invoice_receipts WHERE invoice_id = fixed) IS DISTINCT FROM original
    OR (SELECT pt FROM pg_temp.balance()) IS DISTINCT FROM 9 THEN
    RAISE EXCEPTION 'Invoice correction did not carry money, links or sessions';
  END IF;
  PERFORM pg_temp.fails(cashier, 'invoice_correct', jsonb_build_object('id', fixed, 'version', pg_temp.version(fixed),
    'reason', 'Smaller', 'invoice', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_one, 1))))
    , 'correction_below_paid');

  -- Sessions committed to future bookings cannot be removed.
  PERFORM pg_temp.ok(cashier, 'invoice_void', jsonb_build_object('id', (SELECT id FROM ids WHERE name = 'unpaid'),
    'version', pg_temp.version((SELECT id FROM ids WHERE name = 'unpaid')), 'reason', 'Not needed'));
  PERFORM pg_temp.fails(cashier, 'refund_create', jsonb_build_object('id', fixed, 'version', pg_temp.version(fixed),
    'branch', 'tagamoa', 'reason', 'Stopping', 'payback_minor', 0, 'lines', jsonb_build_array(jsonb_build_object(
      'line_id', (SELECT id FROM public.invoice_lines WHERE invoice_id = fixed), 'sessions', 1, 'value_minor', 0))),
    'sessions_in_use');

  -- A resolved request can never commit later.
  PERFORM set_config('request.jwt.claim.sub', desk, true);
  IF public.resolve_invoice_command(req, 'receipt_create')->>'error' IS DISTINCT FROM 'cancelled' THEN
    RAISE EXCEPTION 'Request was not tombstoned';
  END IF;
  BEGIN
    PERFORM public.execute_invoice_command(req, 'receipt_create', jsonb_build_object('id', fixed,
      'version', pg_temp.version(fixed), 'amount_minor', 1, 'method', 'cash', 'branch', 'tagamoa'));
    RAISE EXCEPTION 'Resolved request committed';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
END;
$$;
ROLLBACK;
