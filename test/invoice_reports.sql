-- Billing reports: access, totals, doctor shares, void log, outstanding
-- balances and services. Requires test/invoice_fixture.sql immediately before.
SET LOCAL ROLE authenticated;
DO $$
DECLARE
  cashier constant text := 'a5000000-0000-0000-0000-000000000002';
  desk constant text := 'a5000000-0000-0000-0000-000000000003';
  doctor constant text := 'a5000000-0000-0000-0000-000000000004';
  dr_a constant text := 'a6000000-0000-0000-0000-000000000004';
  dr_b constant text := 'a6000000-0000-0000-0000-000000000005';
  today date := (now() AT TIME ZONE public.clinic_timezone())::date;
  pt_one uuid; pt_six uuid; tr_six uuid; inv uuid; receipt uuid; r jsonb;
BEGIN
  pt_one := pg_temp.ok(cashier, 'service_save', '{"name":"PT session","service_type":"pt_session",
    "sessions_per_unit":1,"price_minor":50000,"attributes_doctors":true,"active":true}', 'document_id');
  pt_six := pg_temp.ok(cashier, 'service_save', '{"name":"6 PT sessions","service_type":"pt_session",
    "sessions_per_unit":6,"price_minor":300000,"attributes_doctors":true,"active":true}', 'document_id');
  tr_six := pg_temp.ok(cashier, 'service_save', '{"name":"6 traction sessions","service_type":"traction_session",
    "sessions_per_unit":6,"price_minor":120000,"attributes_doctors":false,"active":true}', 'document_id');

  -- A: two doctors and a no-doctor line; desk takes cash, cashier takes Visa at the other branch.
  inv := pg_temp.ok(desk, 'invoice_create', pg_temp.bill(jsonb_build_array(
    pg_temp.line(pt_six, 1, ARRAY[dr_a, dr_b]), pg_temp.line(tr_six, 1)),
    '[{"method":"cash","amount_minor":100000}]'));
  PERFORM pg_temp.ok(cashier, 'receipt_create', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'amount_minor', 320000, 'method', 'visa', 'branch', 'masr_elgedida'));
  -- B: paid in cash, then 1,800 refunded and paid back in cash.
  inv := pg_temp.ok(cashier, 'invoice_create', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_six, 1, ARRAY[dr_a])),
    '[{"method":"cash","amount_minor":300000}]'));
  PERFORM pg_temp.ok(cashier, 'refund_create', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'branch', 'tagamoa', 'reason', 'Stopping', 'payback_minor', 180000, 'payback_method', 'cash',
    'lines', jsonb_build_array(jsonb_build_object('line_id',
      (SELECT id FROM public.invoice_lines WHERE invoice_id = inv), 'sessions', 4, 'value_minor', 180000))));
  -- C: unpaid, with one receipt entered and voided.
  inv := pg_temp.ok(cashier, 'invoice_create', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_one, 1))));
  receipt := pg_temp.ok(cashier, 'receipt_create', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'amount_minor', 10000, 'method', 'cash', 'branch', 'tagamoa'), 'document_id');
  PERFORM pg_temp.ok(cashier, 'receipt_void', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'receipt_id', receipt, 'reason', 'Entered twice'));
  -- D: an odd amount split between two doctors.
  PERFORM pg_temp.ok(cashier, 'invoice_create', pg_temp.bill(jsonb_build_array(
    pg_temp.line(pt_one, 1, ARRAY[dr_a, dr_b])), '[{"method":"cash","amount_minor":33333}]'));

  -- Access: payment staff only; the private builders are not callable.
  PERFORM set_config('request.jwt.claim.sub', desk, true);
  BEGIN
    PERFORM public.invoice_report('money', today, today);
    RAISE EXCEPTION 'Front desk read a report';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  PERFORM set_config('request.jwt.claim.sub', doctor, true);
  BEGIN
    PERFORM public.invoice_report('doctors', today, today);
    RAISE EXCEPTION 'Doctor read a report';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  IF has_function_privilege('authenticated', 'public.invoice_report_money(date, date, public.clinic_location)', 'execute')
    OR has_function_privilege('authenticated', 'public.invoice_report_shares(date, date, public.clinic_location)', 'execute') THEN
    RAISE EXCEPTION 'Report builders are callable by clients';
  END IF;
  PERFORM set_config('request.jwt.claim.sub', cashier, true);
  BEGIN
    PERFORM public.invoice_report('money', today, today - 1);
    RAISE EXCEPTION 'Reversed range accepted';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  BEGIN
    PERFORM public.invoice_report('doctor', today, today);
    RAISE EXCEPTION 'Doctor report without a doctor accepted';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  BEGIN
    PERFORM public.invoice_report('everything', today, today);
    RAISE EXCEPTION 'Unknown report accepted';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;

  -- 1. Money: the voided receipt is in the void log, not the totals.
  r := public.invoice_report('money', today, today);
  IF r->'totals' IS DISTINCT FROM jsonb_build_object('cash_in_minor', 433333, 'visa_in_minor', 320000,
    'cash_out_minor', 180000, 'visa_out_minor', 0, 'row_count', 5)
    OR jsonb_array_length(r->'rows') IS DISTINCT FROM 5
    OR jsonb_array_length(r->'voids') IS DISTINCT FROM 1
    OR r->'voids'->0->>'kind' IS DISTINCT FROM 'receipt'
    OR r->'voids'->0->>'void_reason' IS DISTINCT FROM 'Entered twice'
    OR (SELECT jsonb_object_agg(s->>'name', (s->>'cash_in_minor')::bigint + (s->>'visa_in_minor')::bigint
        - (s->>'cash_out_minor')::bigint) FROM jsonb_array_elements(r->'staff') s)
      IS DISTINCT FROM '{"Desk":100000,"Cashier":473333}'::jsonb THEN
    RAISE EXCEPTION 'Money report wrong: %', r;
  END IF;
  r := public.invoice_report('money', today, today, 'masr_elgedida');
  IF (r->'totals'->>'visa_in_minor')::bigint IS DISTINCT FROM 320000
    OR (r->'totals'->>'cash_in_minor')::bigint IS DISTINCT FROM 0 THEN
    RAISE EXCEPTION 'Money report ignored the branch: %', r;
  END IF;
  IF (public.invoice_report('money', today - 9, today - 1)->'totals'->>'row_count')::int IS DISTINCT FROM 0 THEN
    RAISE EXCEPTION 'Money report ignored the dates';
  END IF;

  -- 2. Revenue: receipts minus paid-back money, per collected line.
  r := public.invoice_report('revenue', today, today);
  IF r->'totals' IS DISTINCT FROM jsonb_build_object('collected_minor', 573333, 'cash_minor', 253333,
    'visa_minor', 320000, 'moved_minor', 0, 'row_count', 7) THEN
    RAISE EXCEPTION 'Revenue report wrong: %', r->'totals';
  END IF;
  r := public.invoice_report('revenue', today, today, NULL, dr_b::uuid);
  IF (r->'totals'->>'collected_minor')::bigint IS DISTINCT FROM 333333 THEN
    RAISE EXCEPTION 'Revenue doctor filter wrong: %', r->'totals';
  END IF;

  -- 3 and 4. Doctor shares are exact and add up to everything collected.
  r := public.invoice_report('doctor', today, today, NULL, dr_a::uuid);
  IF (r->'totals'->>'share_minor')::bigint IS DISTINCT FROM 286666
    OR (r->'totals'->>'cash_minor')::bigint IS DISTINCT FROM 172380 THEN
    RAISE EXCEPTION 'Doctor report wrong: %', r->'totals';
  END IF;
  r := public.invoice_report('doctors', today, today);
  IF (SELECT jsonb_object_agg(coalesce(d->>'doctor_name', 'none'), (d->>'share_minor')::bigint)
      FROM jsonb_array_elements(r->'rows') d)
      IS DISTINCT FROM '{"Dr A":286666,"Dr B":166667,"none":120000}'::jsonb
    OR (r->'totals'->>'share_minor')::bigint IS DISTINCT FROM 573333
    OR r->'rows'->2->>'doctor_id' IS NOT NULL THEN
    RAISE EXCEPTION 'Doctors summary wrong: %', r;
  END IF;

  -- 5. Outstanding: one patient, two open invoices.
  r := public.invoice_report('outstanding', today, today);
  IF r->'totals' IS DISTINCT FROM jsonb_build_object('due_minor', 66667, 'open_invoices', 2, 'row_count', 1)
    OR r->'rows'->0->>'patient_name' IS DISTINCT FROM 'Invoice Patient'
    OR (r->'rows'->0->>'oldest_date')::date IS DISTINCT FROM today THEN
    RAISE EXCEPTION 'Outstanding report wrong: %', r;
  END IF;

  -- 6. Services: billed is the current value after refunds.
  r := public.invoice_report('services', today, today);
  IF r->'totals' IS DISTINCT FROM jsonb_build_object('units', 5, 'billed_minor', 640000,
    'collected_minor', 573333, 'row_count', 5)
    OR (SELECT jsonb_object_agg(s->>'service_name', jsonb_build_array(s->'units', s->'billed_minor', s->'collected_minor'))
      FROM jsonb_array_elements(r->'rows') s) IS DISTINCT FROM
      '{"6 PT sessions":[2,420000,420000],"6 traction sessions":[1,120000,120000],"PT session":[2,100000,33333]}'::jsonb
    OR jsonb_array_length(r->'lines') IS DISTINCT FROM 5 THEN
    RAISE EXCEPTION 'Services report wrong: %', r;
  END IF;

  -- 7. A refund that hands money back and moves money between services.
  -- PT 3,000 (Dr A) + traction 1,200, 2,800 paid in cash: PT holds 2,000 and
  -- traction 800. Refunding 2,000 of PT leaves it at 1,000, so 1,000 comes
  -- off PT: 600 handed back in cash and 400 moved to traction.
  inv := pg_temp.ok(cashier, 'invoice_create', pg_temp.bill(jsonb_build_array(
    pg_temp.line(pt_six, 1, ARRAY[dr_a]), pg_temp.line(tr_six, 1)),
    '[{"method":"cash","amount_minor":280000}]'));
  PERFORM pg_temp.ok(cashier, 'refund_create', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'branch', 'tagamoa', 'reason', 'Stopping PT', 'payback_minor', 60000, 'payback_method', 'cash',
    'lines', jsonb_build_array(jsonb_build_object('line_id',
      (SELECT id FROM public.invoice_lines WHERE invoice_id = inv AND service_type = 'pt_session'),
      'sessions', 4, 'value_minor', 200000))));
  r := public.invoice_report('revenue', today, today);
  IF (SELECT jsonb_agg(jsonb_build_array(x->>'service_name', x->>'method', (x->>'amount_minor')::bigint)
        ORDER BY x->>'service_name', x->>'method' NULLS LAST, (x->>'amount_minor')::bigint)
      FROM jsonb_array_elements(r->'rows') x WHERE x->>'invoice_id' = inv::text AND x->>'kind' = 'refund')
      IS DISTINCT FROM '[["6 PT sessions","cash",-60000],["6 PT sessions",null,-40000],
        ["6 traction sessions",null,40000]]'::jsonb
    OR (r->'totals'->>'cash_minor')::bigint IS DISTINCT FROM 253333 + 280000 - 60000
    OR (r->'totals'->>'moved_minor')::bigint IS DISTINCT FROM 0 THEN
    RAISE EXCEPTION 'Refund rows not split into payback and adjustment: %', r;
  END IF;
  r := public.invoice_report('doctors', today, today);
  IF (SELECT jsonb_object_agg(coalesce(d->>'doctor_name', 'none'),
        jsonb_build_array((d->>'share_minor')::bigint, (d->>'moved_minor')::bigint))
      FROM jsonb_array_elements(r->'rows') d)
      IS DISTINCT FROM '{"Dr A":[386666,-40000],"Dr B":[166667,0],"none":[240000,40000]}'::jsonb THEN
    RAISE EXCEPTION 'Doctor totals changed by the refund split: %', r->'rows';
  END IF;
  -- Money in and out still sees one 600 cash refund.
  r := public.invoice_report('money', today, today);
  IF (r->'totals'->>'cash_out_minor')::bigint IS DISTINCT FROM 180000 + 60000 THEN
    RAISE EXCEPTION 'Money report changed: %', r->'totals';
  END IF;
END;
$$;
ROLLBACK;
