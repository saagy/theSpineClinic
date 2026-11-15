-- Visit history, earlier days' outcomes, attended visits, the package rule,
-- the all-day session hold, balance corrections, and the Services and
-- Balances due changes (migration 20261115120100).
-- Requires test/invoice_fixture.sql immediately before; ends with ROLLBACK.

-- Returns the error a statement raises, or NULL when it succeeds.
CREATE FUNCTION pg_temp.err(p_sql text) RETURNS text LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN NULL;
EXCEPTION WHEN OTHERS THEN
  RETURN SQLERRM;
END;
$$;

CREATE FUNCTION pg_temp.as_user(p_user text) RETURNS void LANGUAGE sql AS $$
  SELECT set_config('request.jwt.claim.sub', p_user, true);
$$;

CREATE FUNCTION pg_temp.at_today(p_minutes integer) RETURNS timestamptz LANGUAGE sql AS $$
  SELECT (((now() AT TIME ZONE public.clinic_timezone())::date)::timestamp
    + make_interval(mins => p_minutes)) AT TIME ZONE public.clinic_timezone();
$$;

-- 1. Reports: a fully refunded package is not sold; old balances are aged.
SET LOCAL ROLE authenticated;
DO $$
DECLARE
  cashier constant text := 'a5000000-0000-0000-0000-000000000002';
  today date := (now() AT TIME ZONE public.clinic_timezone())::date;
  pt_six uuid; inv uuid; r jsonb;
BEGIN
  pt_six := pg_temp.ok(cashier, 'service_save', '{"name":"6 PT sessions","service_type":"pt_session",
    "sessions_per_unit":6,"price_minor":300000,"attributes_doctors":false,"active":true}', 'document_id');
  inv := pg_temp.ok(cashier, 'invoice_create', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_six, 1))));
  PERFORM pg_temp.ok(cashier, 'refund_create', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'branch', 'tagamoa', 'reason', 'Changed their mind', 'payback_minor', 0,
    'lines', jsonb_build_array(jsonb_build_object('line_id',
      (SELECT id FROM public.invoice_lines WHERE invoice_id = inv), 'sessions', 6, 'value_minor', 300000))));
  r := public.invoice_report('services', today, today);
  IF (r->'totals'->>'units')::int <> 0 OR jsonb_array_length(r->'rows') <> 0 THEN
    RAISE EXCEPTION 'Fully refunded package counted as sold: %', r;
  END IF;
  -- A partly refunded package still counts.
  inv := pg_temp.ok(cashier, 'invoice_create', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_six, 1))));
  PERFORM pg_temp.ok(cashier, 'refund_create', jsonb_build_object('id', inv, 'version', pg_temp.version(inv),
    'branch', 'tagamoa', 'reason', 'Stopping', 'payback_minor', 0,
    'lines', jsonb_build_array(jsonb_build_object('line_id',
      (SELECT id FROM public.invoice_lines WHERE invoice_id = inv), 'sessions', 2, 'value_minor', 100000))));
  IF (public.invoice_report('services', today, today)->'totals'->>'units')::int <> 1 THEN
    RAISE EXCEPTION 'Partly refunded package not counted';
  END IF;
  -- 45 days old, unpaid: the 31-60 bucket.
  PERFORM pg_temp.ok(cashier, 'invoice_create', pg_temp.bill(jsonb_build_array(pg_temp.line(pt_six, 1)))
    || jsonb_build_object('invoice_date', today - 45));
  r := public.invoice_report('outstanding', today, today)->'totals';
  IF (r->>'due_31_60_minor')::bigint <> 300000 OR (r->>'due_0_30_minor')::bigint <> 200000
      OR (r->>'due_61_90_minor')::bigint <> 0 OR (r->>'due_over_90_minor')::bigint <> 0
      OR (r->>'due_minor')::bigint <> 500000 THEN
    RAISE EXCEPTION 'Balances due not aged: %', r;
  END IF;
END;
$$;

-- Fixture: two visits recorded three days ago, and one cancelled three days
-- ago for a visit five days from now. The invoices above left 10 PT
-- sessions; the checked-in visit uses one.
RESET ROLE;
SELECT pg_temp.as_user('');
INSERT INTO public.appointments(id, patient_id, type, status, use_package, scheduled_at, status_changed_at) VALUES
 ('a9000000-0000-0000-0000-000000000001', 'a7000000-0000-0000-0000-000000000001', 'normal_pt_session',
   'checked_in', true, now() - interval '3 days', now() - interval '3 days'),
 ('a9000000-0000-0000-0000-000000000002', 'a7000000-0000-0000-0000-000000000001', 'normal_pt_session',
   'no_show', true, now() - interval '3 days', now() - interval '3 days'),
 ('a9000000-0000-0000-0000-000000000003', 'a7000000-0000-0000-0000-000000000001', 'normal_pt_session',
   'cancelled', true, now() + interval '5 days', now() - interval '3 days');
INSERT INTO public.appointment_doctors(appointment_id, doctor_id, is_active)
SELECT id, 'a6000000-0000-0000-0000-000000000004', true FROM public.appointments
WHERE id::text LIKE 'a9000000%';

-- 2. Visits.
SET LOCAL ROLE authenticated;
DO $$
DECLARE
  cashier constant text := 'a5000000-0000-0000-0000-000000000002';
  desk constant text := 'a5000000-0000-0000-0000-000000000003';
  desk_staff constant uuid := 'a6000000-0000-0000-0000-000000000003';
  dr_a constant uuid := 'a6000000-0000-0000-0000-000000000004';
  pat constant uuid := 'a7000000-0000-0000-0000-000000000001';
  old_visit constant uuid := 'a9000000-0000-0000-0000-000000000001';
  missed constant uuid := 'a9000000-0000-0000-0000-000000000002';
  later constant uuid := 'a9000000-0000-0000-0000-000000000003';
  a uuid; b uuid; e public.appointment_events; msg text;
BEGIN
  IF (SELECT pt FROM pg_temp.balance()) <> 9 THEN
    RAISE EXCEPTION 'Fixture balance %', pg_temp.balance(); END IF;

  -- Booking always uses the package and is recorded with who booked it.
  PERFORM pg_temp.as_user(desk);
  PERFORM public.book_recurring_appointments(pat, 'normal_pt_session', ARRAY[pg_temp.at_today(12 * 60)],
    false, desk_staff, ARRAY[dr_a]);
  SELECT id INTO a FROM public.appointments WHERE patient_id = pat AND created_by = desk_staff;
  IF NOT (SELECT use_package FROM public.appointments WHERE id = a) THEN
    RAISE EXCEPTION 'Booked PT visit does not use the package'; END IF;
  SELECT * INTO e FROM public.appointment_events WHERE appointment_id = a;
  IF e.kind <> 'booked' OR e.actor_name <> 'Desk' THEN RAISE EXCEPTION 'Booking not recorded: %', e; END IF;

  -- Today's outcomes change freely, and each change is recorded.
  PERFORM public.set_appointment_status(a, 'checked_in');
  IF (SELECT pt FROM pg_temp.balance()) <> 8 THEN RAISE EXCEPTION 'Check-in did not use a session'; END IF;
  PERFORM public.set_appointment_status(a, 'scheduled');
  PERFORM public.set_appointment_status(a, 'no_show');
  IF (SELECT pt FROM pg_temp.balance()) <> 9 THEN RAISE EXCEPTION 'No-show used a session'; END IF;
  IF (SELECT array_agg(coalesce(from_status::text, '-') || '>' || to_status ORDER BY id)
      FROM public.appointment_events WHERE appointment_id = a AND kind = 'status')
      IS DISTINCT FROM ARRAY['scheduled>checked_in', 'checked_in>scheduled', 'scheduled>no_show'] THEN
    RAISE EXCEPTION 'Status history wrong';
  END IF;

  -- A visit that was ever checked in is kept.
  msg := pg_temp.err(format('DELETE FROM public.appointments WHERE id = %L', a));
  IF msg IS DISTINCT FROM 'visit_was_attended' THEN RAISE EXCEPTION 'Attended visit deleted: %', msg; END IF;
  -- One that never was can be deleted, and the deletion is recorded.
  PERFORM public.book_recurring_appointments(pat, 'initial_assessment', ARRAY[pg_temp.at_today(13 * 60)],
    false, desk_staff, ARRAY[dr_a]);
  SELECT id INTO b FROM public.appointments WHERE patient_id = pat AND type = 'initial_assessment';
  IF (SELECT use_package FROM public.appointments WHERE id = b) THEN
    RAISE EXCEPTION 'Assessment uses the package'; END IF;
  DELETE FROM public.appointments WHERE id = b;
  IF NOT EXISTS (SELECT 1 FROM public.appointment_events WHERE appointment_id = b AND kind = 'deleted'
      AND actor_name = 'Desk') THEN
    RAISE EXCEPTION 'Deletion not recorded'; END IF;

  -- An earlier day's outcome: the desk cannot change it, payment staff need a reason.
  msg := pg_temp.err(format('SELECT public.set_appointment_status(%L, ''scheduled'')', old_visit));
  IF msg IS DISTINCT FROM 'visit_outcome_locked' THEN RAISE EXCEPTION 'Desk changed old outcome: %', msg; END IF;
  msg := pg_temp.err(format('SELECT public.set_appointment_status(%L, ''scheduled'', ''Wrong patient'')', old_visit));
  IF msg IS DISTINCT FROM 'visit_outcome_locked' THEN RAISE EXCEPTION 'Desk reason accepted: %', msg; END IF;
  PERFORM pg_temp.as_user(cashier);
  msg := pg_temp.err(format('SELECT public.set_appointment_status(%L, ''scheduled'', ''  '')', old_visit));
  IF msg IS DISTINCT FROM 'visit_outcome_locked' THEN RAISE EXCEPTION 'Blank reason accepted: %', msg; END IF;
  msg := pg_temp.err(format('UPDATE public.appointments SET status = ''scheduled'' WHERE id = %L', missed));
  IF msg IS DISTINCT FROM 'visit_outcome_locked' THEN RAISE EXCEPTION 'Direct update bypassed lock: %', msg; END IF;
  PERFORM public.set_appointment_status(old_visit, 'scheduled', ' Checked in on the wrong patient ');
  IF (SELECT pt FROM pg_temp.balance()) <> 10 THEN RAISE EXCEPTION 'Undone check-in did not return the session'; END IF;
  SELECT * INTO e FROM public.appointment_events WHERE appointment_id = old_visit ORDER BY id DESC LIMIT 1;
  IF e.reason IS DISTINCT FROM 'Checked in on the wrong patient' OR e.actor_name <> 'Cashier' THEN
    RAISE EXCEPTION 'Reason not recorded: %', e; END IF;
  -- Reopened today, it is today's outcome again: the desk may record it.
  PERFORM pg_temp.as_user(desk);
  PERFORM public.set_appointment_status(old_visit, 'no_show');
  -- A cancellation for a visit still ahead stays free to restore.
  PERFORM public.set_appointment_status(later, 'scheduled');

  -- The doctor sessions report leaves no-shows out of pending.
  PERFORM pg_temp.as_user(cashier);
  IF EXISTS (SELECT 1 FROM jsonb_array_elements(public.doctor_session_report(current_date - 4, current_date)->'pending') p
      WHERE (p->>'appointment_id')::uuid IN (missed, old_visit)) THEN
    RAISE EXCEPTION 'No-show listed as pending'; END IF;

  msg := pg_temp.err(format('SELECT public.set_appointment_status(%L, ''checked_in'')', gen_random_uuid()));
  IF msg IS DISTINCT FROM 'visit_not_found' THEN RAISE EXCEPTION 'Missing visit: %', msg; END IF;
END;
$$;

-- 3. Sessions are held all day; balances change only through the commands.
RESET ROLE;
SELECT pg_temp.as_user('');
-- Balance 10. Two package visits earlier today and the restored later one
-- hold three sessions; the 12:00 visit was a no-show and holds none.
INSERT INTO public.appointments(patient_id, type, status, use_package, scheduled_at)
SELECT 'a7000000-0000-0000-0000-000000000001', 'normal_pt_session', 'scheduled', true, pg_temp.at_today(n)
FROM generate_series(1, 2) n;
DO $$
DECLARE msg text;
BEGIN
  msg := pg_temp.err('SELECT public.invoice_adjust_sessions(''a7000000-0000-0000-0000-000000000001'', -8, 0)');
  IF msg IS DISTINCT FROM 'sessions_in_use' THEN
    RAISE EXCEPTION 'Earlier visits today did not hold their sessions: %', msg; END IF;
  PERFORM public.invoice_adjust_sessions('a7000000-0000-0000-0000-000000000001', -7, 0);
  IF (SELECT pt FROM pg_temp.balance()) <> 3 THEN RAISE EXCEPTION 'Free session not removable'; END IF;
END;
$$;

SET LOCAL ROLE authenticated;
DO $$
DECLARE
  cashier constant text := 'a5000000-0000-0000-0000-000000000002';
  desk constant text := 'a5000000-0000-0000-0000-000000000003';
  doctor constant text := 'a5000000-0000-0000-0000-000000000004';
  pat constant uuid := 'a7000000-0000-0000-0000-000000000001';
  adj public.patient_balance_adjustments; msg text;
BEGIN
  PERFORM pg_temp.as_user(cashier);
  msg := pg_temp.err(format('UPDATE public.patients SET session_balance = 50 WHERE id = %L', pat));
  IF msg NOT LIKE 'Permission denied%' THEN RAISE EXCEPTION 'Direct balance write accepted: %', msg; END IF;
  msg := pg_temp.err(format('INSERT INTO public.patients(full_name, phone_number, clinic, traction_balance)
    VALUES (''New'', ''01000000999'', ''tagamoa'', 5)'));
  IF msg NOT LIKE 'Permission denied%' THEN RAISE EXCEPTION 'New patient with balance accepted: %', msg; END IF;
  msg := pg_temp.err(format('SELECT public.adjust_patient_balance(%L, 2, 0, 5, 1, ''Old file'')', pat));
  IF msg IS DISTINCT FROM 'balance_changed' THEN RAISE EXCEPTION 'Stale balance accepted: %', msg; END IF;
  msg := pg_temp.err(format('SELECT public.adjust_patient_balance(%L, 3, 0, 5, 1, '' '')', pat));
  IF msg IS DISTINCT FROM 'invalid_adjustment' THEN RAISE EXCEPTION 'Blank reason accepted: %', msg; END IF;
  msg := pg_temp.err(format('SELECT public.adjust_patient_balance(%L, 3, 0, -1, 1, ''Old file'')', pat));
  IF msg IS DISTINCT FROM 'invalid_adjustment' THEN RAISE EXCEPTION 'Negative balance accepted: %', msg; END IF;
  msg := pg_temp.err(format('SELECT public.adjust_patient_balance(%L, 3, 0, 3, 0, ''Old file'')', pat));
  IF msg IS DISTINCT FROM 'invalid_adjustment' THEN RAISE EXCEPTION 'No-change accepted: %', msg; END IF;
  PERFORM pg_temp.as_user(desk);
  msg := pg_temp.err(format('SELECT public.adjust_patient_balance(%L, 3, 0, 5, 1, ''Old file'')', pat));
  IF msg NOT LIKE 'Permission denied%' THEN RAISE EXCEPTION 'Front desk adjusted a balance: %', msg; END IF;

  PERFORM pg_temp.as_user(cashier);
  PERFORM public.adjust_patient_balance(pat, 3, 0, 5, 1, '  Carried over from the paper file ');
  IF (SELECT pt FROM pg_temp.balance()) <> 5 OR (SELECT traction FROM pg_temp.balance()) <> 1 THEN
    RAISE EXCEPTION 'Balance not adjusted: %', pg_temp.balance(); END IF;
  SELECT * INTO adj FROM public.patient_balance_adjustments WHERE patient_id = pat;
  IF (adj.pt_before, adj.pt_after, adj.traction_before, adj.traction_after, adj.reason, adj.adjusted_by_name)
      IS DISTINCT FROM (3, 5, 0, 1, 'Carried over from the paper file', 'Cashier') THEN
    RAISE EXCEPTION 'Adjustment not recorded: %', adj; END IF;
  -- Anyone with access to the patient sees the record.
  PERFORM pg_temp.as_user(doctor);
  IF NOT EXISTS (SELECT 1 FROM public.patient_balance_adjustments WHERE patient_id = pat) THEN
    RAISE EXCEPTION 'Assigned doctor cannot see the adjustment'; END IF;
END;
$$;
ROLLBACK;
