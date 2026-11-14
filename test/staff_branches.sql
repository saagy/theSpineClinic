-- Staff branches, shifts and appointment branches. Disposable PostgreSQL only.
BEGIN;
INSERT INTO auth.users(id,email) VALUES
 ('10000000-0000-0000-0000-000000000081','branch-admin@example.test'),
 ('10000000-0000-0000-0000-000000000082','branch-head@example.test'),
 ('10000000-0000-0000-0000-000000000083','branch-desk@example.test'),
 ('10000000-0000-0000-0000-000000000084','branch-doctor@example.test'),
 ('10000000-0000-0000-0000-000000000085','branch-far@example.test');
INSERT INTO public.staff(id,user_id,full_name,email,role,branch,can_manage_payments) VALUES
 ('b0000000-0000-0000-0000-000000000081','10000000-0000-0000-0000-000000000081','Admin','branch-admin@example.test','super_admin',NULL,false),
 ('b0000000-0000-0000-0000-000000000082','10000000-0000-0000-0000-000000000082','Head','branch-head@example.test','receptionist','tagamoa',true),
 ('b0000000-0000-0000-0000-000000000083','10000000-0000-0000-0000-000000000083','Desk','branch-desk@example.test','receptionist','tagamoa',false),
 ('b0000000-0000-0000-0000-000000000084','10000000-0000-0000-0000-000000000084','Dr Split','branch-doctor@example.test','doctor',NULL,false),
 ('b0000000-0000-0000-0000-000000000085','10000000-0000-0000-0000-000000000085','Dr Far','branch-far@example.test','doctor',NULL,false);
INSERT INTO public.staff_branches(staff_id,branch) VALUES
 ('b0000000-0000-0000-0000-000000000082','tagamoa'),
 ('b0000000-0000-0000-0000-000000000083','tagamoa'),
 ('b0000000-0000-0000-0000-000000000085','madinaty');
INSERT INTO public.staff_details(staff_id,national_id) VALUES
 ('b0000000-0000-0000-0000-000000000084','29001011234501'),
 ('b0000000-0000-0000-0000-000000000085','29001011234502');
INSERT INTO public.patients(id,full_name,phone_number,clinic) VALUES
 ('b7000000-0000-0000-0000-000000000001','Branch Patient','01000000881','tagamoa');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000081',true);
DO $$
DECLARE
  head constant uuid := 'b0000000-0000-0000-0000-000000000082';
  desk constant uuid := 'b0000000-0000-0000-0000-000000000083';
  split constant uuid := 'b0000000-0000-0000-0000-000000000084';
  pat constant uuid := 'b7000000-0000-0000-0000-000000000001';
  s public.staff; n integer; appt public.appointments; outcome jsonb;
BEGIN
  -- Branches and a split week save together; shifts may touch but not overlap.
  SELECT * INTO s FROM public.staff WHERE id = split;
  PERFORM public.update_staff_account(split, to_jsonb(s) || '{
    "branches": ["tagamoa", "madinaty"],
    "shifts": [
      {"branch": "tagamoa", "weekday": 6, "starts_at": "10:00", "ends_at": "14:00"},
      {"branch": "madinaty", "weekday": 6, "starts_at": "14:00", "ends_at": "20:00"},
      {"branch": "madinaty", "weekday": 1, "starts_at": "10:00", "ends_at": "18:00"}]}'::jsonb);
  IF (SELECT count(*) FROM public.staff_branches WHERE staff_id = split) <> 2
      OR (SELECT count(*) FROM public.staff_shifts WHERE staff_id = split) <> 3 THEN
    RAISE EXCEPTION 'Split week not saved'; END IF;
  -- A profile without "branches" leaves them alone.
  PERFORM public.update_staff_account(split, to_jsonb(s) || '{"full_name":"Dr Split Renamed"}');
  IF (SELECT count(*) FROM public.staff_shifts WHERE staff_id = split) <> 3 THEN
    RAISE EXCEPTION 'Shifts lost without a branches key'; END IF;
  BEGIN
    PERFORM public.update_staff_account(split, to_jsonb(s) || '{"branches":["tagamoa"],
      "shifts":[{"branch":"tagamoa","weekday":6,"starts_at":"10:00","ends_at":"14:00"},
                {"branch":"tagamoa","weekday":6,"starts_at":"13:00","ends_at":"15:00"}]}'::jsonb);
    RAISE EXCEPTION 'TEST: overlapping shifts accepted';
  EXCEPTION WHEN invalid_parameter_value THEN
    IF SQLERRM <> 'staff_shifts_overlap' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.update_staff_account(split, to_jsonb(s) || '{"branches":["tagamoa"],
      "shifts":[{"branch":"madinaty","weekday":6,"starts_at":"10:00","ends_at":"14:00"}]}'::jsonb);
    RAISE EXCEPTION 'TEST: shift at an unassigned branch accepted';
  EXCEPTION WHEN invalid_parameter_value THEN
    IF SQLERRM <> 'staff_schedule_invalid' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.update_staff_account(split, to_jsonb(s) || '{"branches":["tagamoa"],
      "shifts":[{"branch":"tagamoa","weekday":6,"starts_at":"14:00","ends_at":"10:00"}]}'::jsonb);
    RAISE EXCEPTION 'TEST: reversed shift accepted';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  IF (SELECT count(*) FROM public.staff_shifts WHERE staff_id = split) <> 3 THEN
    RAISE EXCEPTION 'Failed save changed shifts'; END IF;

  -- Removing a receptionist's working branch moves it to a remaining one.
  SELECT * INTO s FROM public.staff WHERE id = desk;
  PERFORM public.update_staff_account(desk, to_jsonb(s) || '{"branches":["madinaty"]}'::jsonb);
  IF (SELECT branch FROM public.staff WHERE id = desk) IS DISTINCT FROM 'madinaty' THEN
    RAISE EXCEPTION 'Working branch not moved'; END IF;

  -- Creation reads branches and shifts from the details.
  PERFORM public.create_staff_account('branch-new@example.test', 'test-password', 'New Desk',
    'receptionist', new_branch => 'tagamoa', new_details => '{"branches":["madinaty"],
    "shifts":[{"branch":"madinaty","weekday":2,"starts_at":"09:00","ends_at":"17:00"}]}');
  SELECT * INTO s FROM public.staff WHERE email = 'branch-new@example.test';
  IF s.branch IS DISTINCT FROM 'madinaty'
      OR (SELECT count(*) FROM public.staff_shifts WHERE staff_id = s.id) <> 1 THEN
    RAISE EXCEPTION 'Creation branches wrong: %', s; END IF;

  -- Booking records the branch it is sent, or the patient's when none is sent.
  outcome := public.execute_clinic_mutation(gen_random_uuid(), 'booking', jsonb_build_object(
    'p_patient_id', pat, 'p_type', 'initial_assessment', 'p_use_package', false,
    'p_slots', jsonb_build_array(now() + interval '2 days'),
    'p_doctor_ids', jsonb_build_array(split), 'p_branch', 'madinaty'));
  IF (outcome->>'ok')::boolean IS NOT TRUE THEN RAISE EXCEPTION 'Booking failed: %', outcome; END IF;
  outcome := public.execute_clinic_mutation(gen_random_uuid(), 'booking', jsonb_build_object(
    'p_patient_id', pat, 'p_type', 'initial_assessment', 'p_use_package', false,
    'p_slots', jsonb_build_array(now() + interval '3 days'),
    'p_doctor_ids', jsonb_build_array(split)));
  IF (SELECT array_agg(branch ORDER BY scheduled_at) FROM public.appointments WHERE patient_id = pat)
      IS DISTINCT FROM ARRAY['madinaty','tagamoa']::public.clinic_location[] THEN
    RAISE EXCEPTION 'Booking branches wrong'; END IF;
  n := public.staff_upcoming_at_branch(split, 'madinaty');
  IF n <> 1 THEN RAISE EXCEPTION 'Upcoming count % at madinaty', n; END IF;

  -- A patient's transfer leaves their visits where they happened.
  UPDATE public.patients SET clinic = 'masr_elgedida' WHERE id = pat;
  IF EXISTS (SELECT 1 FROM public.appointments WHERE patient_id = pat AND branch = 'masr_elgedida') THEN
    RAISE EXCEPTION 'Transfer moved visits'; END IF;
END;
$$;

-- Receptionists: a scheduled visit can move branch and is logged; a
-- checked-in one cannot. Their own working branch stays within their branches.
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000082',true);
DO $$
DECLARE
  head constant uuid := 'b0000000-0000-0000-0000-000000000082';
  pat constant uuid := 'b7000000-0000-0000-0000-000000000001';
  appt public.appointments;
BEGIN
  SELECT * INTO appt FROM public.appointments WHERE patient_id = pat ORDER BY scheduled_at LIMIT 1;
  PERFORM public.update_appointment_details(appt.id, appt.scheduled_at, appt.type, false, NULL, 'tagamoa');
  IF (SELECT branch FROM public.appointments WHERE id = appt.id) IS DISTINCT FROM 'tagamoa'
      OR NOT EXISTS (SELECT 1 FROM public.appointment_branch_changes WHERE appointment_id = appt.id
        AND from_branch = 'madinaty' AND to_branch = 'tagamoa' AND changed_by = head) THEN
    RAISE EXCEPTION 'Scheduled branch change not saved or logged'; END IF;
  UPDATE public.appointments SET status = 'checked_in' WHERE id = appt.id;
  BEGIN
    UPDATE public.appointments SET branch = 'madinaty' WHERE id = appt.id;
    RAISE EXCEPTION 'TEST: checked-in branch changed by a receptionist';
  EXCEPTION WHEN insufficient_privilege THEN
    IF SQLERRM <> 'appointment_branch_locked' THEN RAISE; END IF;
  END;

  BEGIN
    UPDATE public.staff SET branch = 'madinaty' WHERE id = head;
    RAISE EXCEPTION 'TEST: receptionist switched to an unassigned branch';
  EXCEPTION WHEN insufficient_privilege THEN
    IF SQLERRM <> 'branch_not_assigned' THEN RAISE; END IF;
  END;

  -- The head receptionist reads details of staff sharing a branch only.
  IF NOT EXISTS (SELECT 1 FROM public.staff_details
      WHERE staff_id = 'b0000000-0000-0000-0000-000000000084') THEN
    RAISE EXCEPTION 'Head receptionist cannot read a colleague at their branch'; END IF;
  IF EXISTS (SELECT 1 FROM public.staff_details
      WHERE staff_id = 'b0000000-0000-0000-0000-000000000085') THEN
    RAISE EXCEPTION 'Head receptionist read a colleague at another branch'; END IF;
  IF (SELECT count(*) FROM public.staff_shifts) = 0 THEN
    RAISE EXCEPTION 'Staff cannot read shifts'; END IF;
END;
$$;

-- A front desk receptionist reads no details; a super admin can correct a
-- checked-in visit's branch.
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000083',true);
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.staff_details) THEN
    RAISE EXCEPTION 'Front desk read staff details'; END IF;
  BEGIN
    PERFORM public.staff_upcoming_at_branch('b0000000-0000-0000-0000-000000000084', 'tagamoa');
    RAISE EXCEPTION 'TEST: front desk counted upcoming visits';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END;
$$;
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000081',true);
DO $$
DECLARE appt uuid := (SELECT id FROM public.appointments
  WHERE patient_id = 'b7000000-0000-0000-0000-000000000001' AND status = 'checked_in');
BEGIN
  UPDATE public.appointments SET branch = 'madinaty' WHERE id = appt;
  IF (SELECT count(*) FROM public.appointment_branch_changes WHERE appointment_id = appt) <> 2 THEN
    RAISE EXCEPTION 'Admin correction not logged'; END IF;

  -- Doctor sessions follow the visit's branch. The patient is now registered
  -- at Masr El-Gedida, yet the checked-in visit counts at Madinaty only.
  IF (public.doctor_session_report(current_date - 1, current_date + 7, 'madinaty')
        #>> '{totals,sessions}')::int <> 1
      OR (public.doctor_session_report(current_date - 1, current_date + 7, 'masr_elgedida')
        #>> '{totals,sessions}')::int <> 0
      OR (public.doctor_session_report(current_date - 1, current_date + 7, 'tagamoa')
        #>> '{totals,sessions}')::int <> 0
      OR (public.doctor_session_report(current_date - 1, current_date + 7)
        #>> '{totals,sessions}')::int <> 1 THEN
    RAISE EXCEPTION 'Doctor sessions did not follow the visit branch';
  END IF;
END;
$$;
ROLLBACK;
