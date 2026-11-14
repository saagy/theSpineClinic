-- Doctor sessions report: access, what counts, shared sessions, traction,
-- pending appointments, branch and doctor filters, clinic days.
-- Requires test/invoice_fixture.sql immediately before.
INSERT INTO public.patients(id,full_name,phone_number,clinic) VALUES
 ('a7000000-0000-0000-0000-000000000002','Session Patient','01000000102','masr_elgedida');

DO $$
DECLARE
  dr_a constant uuid := 'a6000000-0000-0000-0000-000000000004';
  dr_b constant uuid := 'a6000000-0000-0000-0000-000000000005';
  tg constant uuid := 'a7000000-0000-0000-0000-000000000001';
  mg constant uuid := 'a7000000-0000-0000-0000-000000000002';
  day constant date := (now() AT TIME ZONE public.clinic_timezone())::date - 3;
BEGIN
  -- (type, status, patient, clinic-local hour on `day`, doctors)
  WITH plan(type, status, patient, hour, doctors) AS (VALUES
    ('normal_pt_session', 'checked_in', tg, 9, ARRAY[dr_a, dr_b]),   -- shared
    ('normal_pt_session', 'checked_in', tg, 10, ARRAY[dr_a]),
    ('initial_assessment', 'checked_in', mg, 11, ARRAY[dr_a]),        -- other branch
    ('reassessment', 'checked_in', tg, 0, ARRAY[dr_b]),               -- first minute of the day
    ('spinal_traction_session', 'checked_in', tg, 12, ARRAY[dr_a]),   -- never counted
    ('normal_pt_session', 'cancelled', tg, 13, ARRAY[dr_a]),          -- never counted
    ('normal_pt_session', 'scheduled', tg, 14, ARRAY[dr_b]),          -- past, not checked in
    ('normal_pt_session', 'checked_in', tg, 24, ARRAY[dr_a])          -- next day, outside
  ), made AS (
    INSERT INTO public.appointments(patient_id, type, status, use_package, scheduled_at)
    SELECT patient, type::public.appointment_type, status::public.appointment_status, false,
      (day::timestamp + make_interval(hours => hour)) AT TIME ZONE public.clinic_timezone()
    FROM plan RETURNING id, scheduled_at
  )
  INSERT INTO public.appointment_doctors(appointment_id, doctor_id)
  SELECT m.id, unnest(p.doctors) FROM made m
  JOIN plan p ON (day::timestamp + make_interval(hours => p.hour)) AT TIME ZONE public.clinic_timezone()
    = m.scheduled_at;
  -- A doctor removed from an appointment is not credited.
  UPDATE public.appointment_doctors SET is_active = false
    WHERE doctor_id = dr_b AND appointment_id = (SELECT id FROM public.appointments
      WHERE patient_id = tg AND type = 'normal_pt_session' AND status = 'checked_in'
      AND scheduled_at = (day::timestamp + interval '10 hours') AT TIME ZONE public.clinic_timezone());
END;
$$;

SET LOCAL ROLE authenticated;
DO $$
DECLARE
  cashier constant text := 'a5000000-0000-0000-0000-000000000002';
  desk constant text := 'a5000000-0000-0000-0000-000000000003';
  doctor constant text := 'a5000000-0000-0000-0000-000000000004';
  admin constant text := 'a5000000-0000-0000-0000-000000000001';
  dr_a constant uuid := 'a6000000-0000-0000-0000-000000000004';
  dr_b constant uuid := 'a6000000-0000-0000-0000-000000000005';
  day constant date := (now() AT TIME ZONE public.clinic_timezone())::date - 3;
  r jsonb;
  denied boolean;
BEGIN
  -- Front desk receptionists and doctors cannot read it.
  FOREACH r IN ARRAY ARRAY[to_jsonb(desk), to_jsonb(doctor)] LOOP
    PERFORM set_config('request.jwt.claim.sub', r #>> '{}', true);
    denied := false;
    BEGIN
      PERFORM public.doctor_session_report(day, day);
    EXCEPTION WHEN insufficient_privilege THEN denied := true;
    END;
    IF NOT denied THEN RAISE EXCEPTION 'Sessions report was not denied for %', r; END IF;
  END LOOP;

  PERFORM set_config('request.jwt.claim.sub', cashier, true);
  BEGIN
    PERFORM public.doctor_session_report(day, day + 367);
    RAISE EXCEPTION 'A period over 366 days was accepted';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;

  -- All branches: 4 checked-in sessions, one shared, so 5 credits.
  r := public.doctor_session_report(day, day);
  IF r->'totals' IS DISTINCT FROM jsonb_build_object('sessions', 4, 'pt_sessions', 2,
    'assessments', 1, 'reassessments', 1, 'shared', 1, 'credits', 5, 'pending', 1, 'doctors', 2) THEN
    RAISE EXCEPTION 'Sessions totals wrong: %', r->'totals';
  END IF;
  IF (SELECT jsonb_object_agg(x->>'doctor_name', jsonb_build_array(x->'pt_sessions', x->'assessments',
      x->'reassessments', x->'total', x->'shared', x->'pending')) FROM jsonb_array_elements(r->'rows') x)
    IS DISTINCT FROM '{"Dr A":[2,1,0,3,1,0],"Dr B":[1,0,1,2,1,1]}'::jsonb THEN
    RAISE EXCEPTION 'Sessions per doctor wrong: %', r->'rows';
  END IF;
  IF jsonb_array_length(r->'sessions') <> 5
    OR (SELECT x->'shared_with' FROM jsonb_array_elements(r->'sessions') x
      WHERE (x->>'doctor_id')::uuid = dr_a AND x->>'type' = 'normal_pt_session'
      ORDER BY x->>'scheduled_at' LIMIT 1) IS DISTINCT FROM '["Dr B"]'::jsonb
    OR r->'pending'->0->'doctors' IS DISTINCT FROM '["Dr B"]'::jsonb THEN
    RAISE EXCEPTION 'Session lines wrong: %', r;
  END IF;

  -- One branch, then one doctor.
  r := public.doctor_session_report(day, day, 'masr_elgedida');
  IF r->'totals'->>'sessions' <> '1' OR r->'rows'->0->>'doctor_name' <> 'Dr A' THEN
    RAISE EXCEPTION 'Branch filter wrong: %', r;
  END IF;
  r := public.doctor_session_report(day, day, NULL, dr_b);
  IF r->'totals'->>'credits' <> '2' OR jsonb_array_length(r->'rows') <> 1
    OR r->'sessions'->1->'shared_with' IS DISTINCT FROM '["Dr A"]'::jsonb THEN
    RAISE EXCEPTION 'Doctor filter wrong: %', r;
  END IF;

  -- Super admins can read it too; an empty day is empty, not an error.
  PERFORM set_config('request.jwt.claim.sub', admin, true);
  r := public.doctor_session_report(day - 30, day - 30);
  IF r->'rows' <> '[]'::jsonb OR r->'totals'->>'sessions' <> '0' THEN
    RAISE EXCEPTION 'Empty period wrong: %', r;
  END IF;
END;
$$;
ROLLBACK;
