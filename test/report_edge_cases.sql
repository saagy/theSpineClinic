-- Report edge cases: three-way doctor splits, corrections that change the
-- doctor, cancelled paid invoices, deactivated and renamed doctors, refunds
-- on shared lines, day boundaries, and sessions that are undone, handed to
-- another doctor or done by a doctor who has since left.
-- Requires test/invoice_fixture.sql immediately before.
INSERT INTO auth.users(id,email) VALUES
 ('a5000000-0000-0000-0000-000000000006','inv-doctor-c@example.test');
INSERT INTO public.staff(id,user_id,full_name,email,role) VALUES
 ('a6000000-0000-0000-0000-000000000006','a5000000-0000-0000-0000-000000000006','Dr C','inv-doctor-c@example.test','doctor');

SET LOCAL ROLE authenticated;
DO $$
DECLARE
  cashier constant text := 'a5000000-0000-0000-0000-000000000002';
  dr_a constant text := 'a6000000-0000-0000-0000-000000000004';
  dr_b constant text := 'a6000000-0000-0000-0000-000000000005';
  dr_c constant text := 'a6000000-0000-0000-0000-000000000006';
  today date := (now() AT TIME ZONE public.clinic_timezone())::date;
  pt_one uuid; pt_six uuid; inv uuid; fixed uuid; r jsonb; shares jsonb;
BEGIN
  pt_one := pg_temp.ok(cashier, 'service_save', '{"name":"PT session","service_type":"pt_session",
    "sessions_per_unit":1,"price_minor":50000,"attributes_doctors":true,"active":true}', 'document_id');
  pt_six := pg_temp.ok(cashier, 'service_save', '{"name":"6 PT sessions","service_type":"pt_session",
    "sessions_per_unit":6,"price_minor":300000,"attributes_doctors":true,"active":true}', 'document_id');

  -- 1. Three doctors share 500.00: the parts differ by at most one piaster
  -- and add up exactly.
  PERFORM pg_temp.ok(cashier, 'invoice_create', pg_temp.bill(jsonb_build_array(
    pg_temp.line(pt_one, 1, ARRAY[dr_a, dr_b, dr_c])), '[{"method":"cash","amount_minor":50000}]'));
  r := public.invoice_report('doctors', today, today);
  shares := (SELECT jsonb_object_agg(d->>'doctor_name', (d->>'share_minor')::bigint)
    FROM jsonb_array_elements(r->'rows') d);
  IF (shares->>'Dr A')::bigint + (shares->>'Dr B')::bigint + (shares->>'Dr C')::bigint <> 50000
    OR (SELECT max(v::bigint) - min(v::bigint) FROM jsonb_each_text(shares) AS x(k, v)) > 1 THEN
    RAISE EXCEPTION 'Three-way split wrong: %', shares;
  END IF;

  -- 2. A correction that names another doctor moves the money to them. The
  -- drawer totals and the day the money was taken do not change.
  inv := pg_temp.ok(cashier, 'invoice_create', pg_temp.bill(jsonb_build_array(
    pg_temp.line(pt_six, 1, ARRAY[dr_a])), '[{"method":"cash","amount_minor":300000}]'));
  fixed := pg_temp.ok(cashier, 'invoice_correct', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'reason', 'Wrong doctor', 'invoice', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_six, 1, ARRAY[dr_b])))));
  r := public.invoice_report('doctor', today, today, NULL, dr_a::uuid);
  IF (r->'totals'->>'share_minor')::bigint <> (shares->>'Dr A')::bigint THEN
    RAISE EXCEPTION 'Corrected-away doctor kept money: %', r->'totals'; END IF;
  r := public.invoice_report('doctor', today, today, NULL, dr_b::uuid);
  IF (r->'totals'->>'share_minor')::bigint <> (shares->>'Dr B')::bigint + 300000 THEN
    RAISE EXCEPTION 'Correction did not credit the new doctor: %', r->'totals'; END IF;
  r := public.invoice_report('money', today, today);
  IF (r->'totals'->>'cash_in_minor')::bigint <> 350000 OR (r->'totals'->>'cash_out_minor')::bigint <> 0 THEN
    RAISE EXCEPTION 'Correction changed the drawer: %', r->'totals'; END IF;
  r := public.invoice_report('services', today, today);
  IF (r->'totals'->>'billed_minor')::bigint <> 350000 OR (r->'totals'->>'units')::int <> 2 THEN
    RAISE EXCEPTION 'Corrected invoice counted twice in services: %', r->'totals'; END IF;

  -- 3. A refund on a line two doctors share comes off both, to the piaster.
  inv := pg_temp.ok(cashier, 'invoice_create', pg_temp.bill(jsonb_build_array(
    pg_temp.line(pt_six, 1, ARRAY[dr_a, dr_c])), '[{"method":"visa","amount_minor":300000}]'));
  PERFORM pg_temp.ok(cashier, 'refund_create', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'branch', 'tagamoa', 'reason', 'Stopping', 'payback_minor', 100001, 'payback_method', 'cash',
    'lines', jsonb_build_array(jsonb_build_object('line_id',
      (SELECT id FROM public.invoice_lines WHERE invoice_id = inv), 'sessions', 2, 'value_minor', 100001))));
  r := public.invoice_report('doctors', today, today);
  shares := (SELECT jsonb_object_agg(d->>'doctor_name', (d->>'share_minor')::bigint)
    FROM jsonb_array_elements(r->'rows') d);
  -- Collected so far: 50,000 + 300,000 + (300,000 - 100,001) = 549,999.
  IF (r->'totals'->>'share_minor')::bigint <> 549999
      OR (SELECT sum(v::bigint) FROM jsonb_each_text(shares) AS x(k, v)) <> 549999 THEN
    RAISE EXCEPTION 'Shares after a refund do not add up: % %', r->'totals', shares;
  END IF;
  IF (public.invoice_report('revenue', today, today)->'totals'->>'collected_minor')::bigint <> 549999 THEN
    RAISE EXCEPTION 'Revenue disagrees with doctor shares'; END IF;

  -- 4. Cancelling a paid invoice removes its money from every report.
  inv := pg_temp.ok(cashier, 'invoice_create', pg_temp.bill(jsonb_build_array(
    pg_temp.line(pt_one, 1, ARRAY[dr_c])), '[{"method":"cash","amount_minor":50000}]'));
  PERFORM pg_temp.ok(cashier, 'invoice_void_all', jsonb_build_object('id', inv,
    'version', pg_temp.version(inv), 'reason', 'Wrong patient'));
  r := public.invoice_report('doctors', today, today);
  IF (r->'totals'->>'share_minor')::bigint <> 549999 THEN
    RAISE EXCEPTION 'Cancelled invoice still in doctor revenue: %', r->'totals'; END IF;
  IF (public.invoice_report('outstanding', today, today)->'totals'->>'due_minor')::bigint <> 0 THEN
    RAISE EXCEPTION 'Cancelled invoice still owed'; END IF;
  r := public.invoice_report('money', today, today);
  IF (r->'totals'->>'cash_in_minor')::bigint <> 350000
      OR NOT EXISTS (SELECT 1 FROM jsonb_array_elements(r->'voids') v WHERE v->>'void_reason' = 'Wrong patient') THEN
    RAISE EXCEPTION 'Cancelled payment not moved to the cancelled list: %', r; END IF;
END;
$$;

-- 5. A doctor who is renamed and then deactivated keeps their revenue and
-- sessions, under their current name.
RESET ROLE;
SELECT set_config('request.jwt.claim.sub', '', true);
UPDATE public.staff SET full_name = 'Dr C Renamed', is_active = false, deactivated_at = now()
  WHERE id = 'a6000000-0000-0000-0000-000000000006';
-- 6. Day boundary: money taken in the last second of yesterday belongs to
-- yesterday only.
UPDATE public.invoice_receipts SET received_at =
    ((now() AT TIME ZONE public.clinic_timezone())::date::timestamp - interval '1 second')
      AT TIME ZONE public.clinic_timezone()
  WHERE method = 'visa' AND voided_at IS NULL;
-- Sessions: (a) checked in then undone, (b) handed from Dr A to Dr B,
-- (c) done by the doctor who has since left, (d) last minute of the day.
INSERT INTO public.appointments(id, patient_id, type, status, use_package, scheduled_at)
SELECT ('a8000000-0000-0000-0000-00000000000' || n)::uuid, 'a7000000-0000-0000-0000-000000000001',
  'normal_pt_session', 'checked_in', false,
  (((now() AT TIME ZONE public.clinic_timezone())::date - 2)::timestamp + make_interval(hours => h, mins => m))
    AT TIME ZONE public.clinic_timezone()
FROM (VALUES (1, 9, 0), (2, 10, 0), (3, 11, 0), (4, 23, 59)) AS x(n, h, m);
INSERT INTO public.appointment_doctors(appointment_id, doctor_id, is_active) VALUES
 ('a8000000-0000-0000-0000-000000000001', 'a6000000-0000-0000-0000-000000000004', true),
 ('a8000000-0000-0000-0000-000000000002', 'a6000000-0000-0000-0000-000000000004', false),
 ('a8000000-0000-0000-0000-000000000002', 'a6000000-0000-0000-0000-000000000005', true),
 ('a8000000-0000-0000-0000-000000000003', 'a6000000-0000-0000-0000-000000000006', true),
 ('a8000000-0000-0000-0000-000000000004', 'a6000000-0000-0000-0000-000000000004', true);
UPDATE public.appointments SET status = 'scheduled' WHERE id = 'a8000000-0000-0000-0000-000000000001';

SET LOCAL ROLE authenticated;
DO $$
DECLARE
  today date := (now() AT TIME ZONE public.clinic_timezone())::date;
  r jsonb; names jsonb;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', 'a5000000-0000-0000-0000-000000000002', true);
  r := public.invoice_report('doctors', today - 1, today);
  names := (SELECT jsonb_object_agg(d->>'doctor_name', (d->>'share_minor')::bigint)
    FROM jsonb_array_elements(r->'rows') d);
  IF NOT names ? 'Dr C Renamed' OR names ? 'Dr C' OR (r->'totals'->>'share_minor')::bigint <> 549999 THEN
    RAISE EXCEPTION 'Deactivated doctor missing or misnamed: %', names; END IF;

  -- The Visa payment moved to yesterday; the cash refund on it stays today.
  IF (public.invoice_report('money', today, today)->'totals'->>'visa_in_minor')::bigint <> 0
      OR (public.invoice_report('money', today - 1, today - 1)->'totals'->>'visa_in_minor')::bigint <> 300000
      OR (public.invoice_report('doctors', today - 1, today - 1)->'totals'->>'share_minor')::bigint <> 300000
      OR (public.invoice_report('doctors', today, today)->'totals'->>'share_minor')::bigint <> 249999 THEN
    RAISE EXCEPTION 'Day boundary wrong';
  END IF;

  r := public.doctor_session_report(today - 2, today - 2);
  -- (b), (c) and (d) count; (a) waits under "not checked in yet".
  IF r->'totals' IS DISTINCT FROM jsonb_build_object('sessions', 3, 'pt_sessions', 3, 'assessments', 0,
      'reassessments', 0, 'shared', 0, 'credits', 3, 'pending', 1, 'doctors', 3)
    OR (SELECT jsonb_object_agg(x->>'doctor_name', jsonb_build_array(x->'total', x->'pending'))
        FROM jsonb_array_elements(r->'rows') x)
      IS DISTINCT FROM '{"Dr A":[1,1],"Dr B":[1,0],"Dr C Renamed":[1,0]}'::jsonb THEN
    RAISE EXCEPTION 'Session edge cases wrong: % %', r->'totals', r->'rows';
  END IF;
  IF (public.doctor_session_report(today - 1, today - 1)->'totals'->>'sessions') <> '0' THEN
    RAISE EXCEPTION 'A 23:59 session leaked into the next day'; END IF;
END;
$$;
ROLLBACK;
