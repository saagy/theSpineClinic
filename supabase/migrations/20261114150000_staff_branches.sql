-- Staff branches, per-branch schedules and appointment branches
-- (docs/superpowers/specs/2026-11-14-staff-branches-design.md).
--
-- * staff_branches: which branches a person belongs to. Pickers list a
--   branch's staff first; nothing is ever hidden or blocked by it.
-- * staff_shifts: the weekly schedule, one row per shift at one branch. It
--   drives booking warnings only. It replaces staff_details.working_days and
--   work_starts_at/work_ends_at, which had no branch.
-- * appointments.branch: where the visit happens. Before this the branch was
--   borrowed from the patient, so a transfer moved past visits.
-- * Head receptionists (receptionists who manage payments) can read the
--   employment details of staff who share a branch with them.

-- ---- Assignments and shifts ----

CREATE TABLE public.staff_branches (
  staff_id uuid NOT NULL REFERENCES public.staff(id) ON DELETE CASCADE,
  branch public.clinic_location NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid REFERENCES public.staff(id) ON DELETE SET NULL,
  PRIMARY KEY (staff_id, branch)
);
CREATE INDEX staff_branches_branch_idx ON public.staff_branches (branch);

CREATE TABLE public.staff_shifts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id uuid NOT NULL,
  branch public.clinic_location NOT NULL,
  -- ISO weekday: 1 = Monday ... 7 = Sunday.
  weekday smallint NOT NULL CHECK (weekday BETWEEN 1 AND 7),
  starts_at time NOT NULL,
  ends_at time NOT NULL,
  CHECK (ends_at > starts_at),
  FOREIGN KEY (staff_id, branch) REFERENCES public.staff_branches(staff_id, branch)
    ON DELETE CASCADE
);
CREATE INDEX staff_shifts_staff_idx ON public.staff_shifts (staff_id, weekday);

ALTER TABLE public.staff_branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_shifts ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.staff_branches, public.staff_shifts TO authenticated;
-- Every active staff member reads them (pickers and booking warnings). There
-- are no client write policies: the staff account functions write them.
CREATE POLICY staff_branches_staff_read ON public.staff_branches FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active));
CREATE POLICY staff_shifts_staff_read ON public.staff_shifts FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.get_auth_staff_profile() WHERE staff_active));

-- Everyone with a branch today is assigned to it. Only receptionists keep
-- staff.branch, which now means "the branch I am working at right now".
INSERT INTO public.staff_branches (staff_id, branch)
  SELECT id, branch FROM public.staff WHERE branch IS NOT NULL;
-- A schedule without a branch cannot be placed; carry it over only for
-- people with exactly one branch. On 2026-11-14 that loses one test entry.
INSERT INTO public.staff_shifts (staff_id, branch, weekday, starts_at, ends_at)
  SELECT d.staff_id, b.branch, day, d.work_starts_at, d.work_ends_at
  FROM public.staff_details d
  JOIN public.staff_branches b ON b.staff_id = d.staff_id
  CROSS JOIN LATERAL unnest(d.working_days) day
  WHERE d.work_starts_at IS NOT NULL
    AND (SELECT count(*) FROM public.staff_branches x WHERE x.staff_id = d.staff_id) = 1;
UPDATE public.staff SET branch = NULL WHERE role <> 'receptionist' AND branch IS NOT NULL;
ALTER TABLE public.staff_details DROP COLUMN working_days,
  DROP COLUMN work_starts_at, DROP COLUMN work_ends_at;

-- A receptionist's working branch must be one of their branches when they
-- have any. Covers their own profile saves and every other write path.
CREATE FUNCTION public.guard_staff_working_branch() RETURNS trigger
LANGUAGE plpgsql SET search_path = public, pg_temp AS $$
BEGIN
  IF NEW.role = 'receptionist' AND NEW.branch IS NOT NULL
      AND EXISTS (SELECT 1 FROM public.staff_branches WHERE staff_id = NEW.id)
      AND NOT EXISTS (SELECT 1 FROM public.staff_branches
        WHERE staff_id = NEW.id AND branch = NEW.branch) THEN
    RAISE EXCEPTION 'branch_not_assigned' USING ERRCODE = '42501';
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER tr_guard_staff_working_branch BEFORE UPDATE OF branch, role ON public.staff
  FOR EACH ROW EXECUTE FUNCTION public.guard_staff_working_branch();

-- Replaces a person's branches and shifts from JSON:
--   branches: ["tagamoa", ...]
--   shifts:   [{"branch": "tagamoa", "weekday": 6, "starts_at": "10:00", "ends_at": "18:00"}, ...]
-- Not callable by clients.
CREATE FUNCTION public.staff_save_branches(p_staff_id uuid, p_branches jsonb,
  p_shifts jsonb, p_actor uuid)
RETURNS void LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE
  wanted public.clinic_location[];
BEGIN
  IF jsonb_typeof(coalesce(p_branches, '[]')) <> 'array'
      OR jsonb_typeof(coalesce(p_shifts, '[]')) <> 'array' THEN
    RAISE EXCEPTION 'staff_schedule_invalid' USING ERRCODE = '22023';
  END IF;
  SELECT coalesce(array_agg(DISTINCT value::public.clinic_location), '{}')
    INTO wanted FROM jsonb_array_elements_text(coalesce(p_branches, '[]'));
  DELETE FROM public.staff_branches WHERE staff_id = p_staff_id AND NOT branch = ANY(wanted);
  INSERT INTO public.staff_branches (staff_id, branch, created_by)
    SELECT p_staff_id, b, p_actor FROM unnest(wanted) b
    ON CONFLICT (staff_id, branch) DO NOTHING;

  DELETE FROM public.staff_shifts WHERE staff_id = p_staff_id;
  INSERT INTO public.staff_shifts (staff_id, branch, weekday, starts_at, ends_at)
    SELECT p_staff_id, (s->>'branch')::public.clinic_location, (s->>'weekday')::smallint,
      (s->>'starts_at')::time, (s->>'ends_at')::time
    FROM jsonb_array_elements(coalesce(p_shifts, '[]')) s;
  -- Two shifts on one day may touch (14:00 end, 14:00 start) but not overlap.
  IF EXISTS (SELECT 1 FROM public.staff_shifts a JOIN public.staff_shifts b
      ON a.staff_id = b.staff_id AND a.weekday = b.weekday AND a.id < b.id
      WHERE a.staff_id = p_staff_id
        AND a.starts_at < b.ends_at AND b.starts_at < a.ends_at) THEN
    RAISE EXCEPTION 'staff_shifts_overlap' USING ERRCODE = '22023';
  END IF;
EXCEPTION
  WHEN check_violation OR foreign_key_violation OR not_null_violation
    OR invalid_datetime_format OR datetime_field_overflow
    OR invalid_text_representation OR numeric_value_out_of_range THEN
    RAISE EXCEPTION 'staff_schedule_invalid' USING ERRCODE = '22023';
END;
$$;
REVOKE ALL ON FUNCTION public.staff_save_branches(uuid, jsonb, jsonb, uuid)
  FROM PUBLIC, anon, authenticated;

-- The working branch a receptionist ends up with: the requested one when it
-- is still assigned, otherwise their first branch. Others have none.
CREATE FUNCTION public.staff_working_branch(p_staff_id uuid, p_role public.user_role,
  p_requested public.clinic_location)
RETURNS public.clinic_location LANGUAGE sql STABLE SET search_path = '' AS $$
  SELECT CASE
    WHEN p_role <> 'receptionist' THEN NULL
    WHEN NOT EXISTS (SELECT 1 FROM public.staff_branches WHERE staff_id = p_staff_id)
      THEN p_requested
    WHEN EXISTS (SELECT 1 FROM public.staff_branches
      WHERE staff_id = p_staff_id AND branch = p_requested) THEN p_requested
    ELSE (SELECT branch FROM public.staff_branches WHERE staff_id = p_staff_id
      ORDER BY branch LIMIT 1)
  END;
$$;
REVOKE ALL ON FUNCTION public.staff_working_branch(uuid, public.user_role, public.clinic_location)
  FROM PUBLIC, anon, authenticated;

-- Details lose their schedule fields; everything else is unchanged.
CREATE OR REPLACE FUNCTION public.staff_save_details(p_staff_id uuid, p_details jsonb, p_actor uuid)
RETURNS void LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE
  today date := (now() AT TIME ZONE public.clinic_timezone())::date;
  national text; born date; hired date;
BEGIN
  IF jsonb_typeof(p_details) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'staff_details_invalid' USING ERRCODE = '22023';
  END IF;
  national := nullif(btrim(p_details->>'national_id'), '');
  born := nullif(p_details->>'birth_date', '')::date;
  hired := nullif(p_details->>'hire_date', '')::date;
  IF born > today OR hired > today + 366 THEN
    RAISE EXCEPTION 'staff_details_invalid' USING ERRCODE = '22023';
  END IF;
  IF national IS NOT NULL AND EXISTS (SELECT 1 FROM public.staff_details
      WHERE national_id = national AND staff_id <> p_staff_id) THEN
    RAISE EXCEPTION 'staff_national_id_taken' USING ERRCODE = '23505';
  END IF;
  INSERT INTO public.staff_details AS d (staff_id, national_id, birth_date, hire_date,
    updated_at, updated_by)
  VALUES (p_staff_id, national, born, hired, now(), p_actor)
  ON CONFLICT (staff_id) DO UPDATE SET national_id = excluded.national_id,
    birth_date = excluded.birth_date, hire_date = excluded.hire_date,
    updated_at = excluded.updated_at, updated_by = excluded.updated_by;
EXCEPTION
  WHEN check_violation OR invalid_datetime_format OR datetime_field_overflow
    OR invalid_text_representation OR numeric_value_out_of_range THEN
    RAISE EXCEPTION 'staff_details_invalid' USING ERRCODE = '22023';
END;
$$;
REVOKE ALL ON FUNCTION public.staff_save_details(uuid, jsonb, uuid) FROM PUBLIC, anon, authenticated;

-- Creation reads "branches" and "shifts" from new_details.
CREATE OR REPLACE FUNCTION public.create_staff_account(
  new_email text, new_password text, new_full_name text,
  new_role public.user_role, new_phone text DEFAULT NULL,
  new_can_manage_payments boolean DEFAULT false,
  new_branch public.clinic_location DEFAULT NULL,
  new_is_senior boolean DEFAULT false,
  new_details jsonb DEFAULT NULL
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  created_user_id uuid;
  created_staff uuid;
  actor uuid := (SELECT id FROM public.staff WHERE user_id = auth.uid()
    AND role = 'super_admin' AND is_active);
BEGIN
  IF actor IS NULL THEN
    RAISE EXCEPTION 'Only active super admins can create staff users.';
  END IF;
  IF new_is_senior AND new_role <> 'doctor' THEN
    RAISE EXCEPTION 'Senior status requires the doctor role.';
  END IF;
  created_user_id := public.create_staff_user(new_email, new_password,
    new_full_name, new_role, new_phone, new_can_manage_payments, new_branch);
  SELECT id INTO created_staff FROM public.staff WHERE user_id = created_user_id;
  UPDATE public.staff SET is_senior = COALESCE(new_is_senior, false) WHERE id = created_staff;
  IF new_details IS NOT NULL THEN
    PERFORM public.staff_save_details(created_staff, new_details - 'branches' - 'shifts', actor);
    IF new_details ? 'branches' THEN
      PERFORM public.staff_save_branches(created_staff, new_details->'branches',
        new_details->'shifts', actor);
    END IF;
  END IF;
  UPDATE public.staff SET branch = public.staff_working_branch(id, role, branch)
    WHERE id = created_staff;
  RETURN created_user_id;
END;
$$;

-- A profile with a "branches" key replaces branches and shifts ("shifts"
-- defaults to none). Without it both are left as they are.
CREATE OR REPLACE FUNCTION public.update_staff_account(
  target_staff_id uuid, profile jsonb, new_password text DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, extensions, pg_temp
AS $$
DECLARE
  target_user_id uuid;
  selected_role public.user_role := (profile->>'role')::public.user_role;
  selected_senior boolean := COALESCE((profile->>'is_senior')::boolean, false);
  actor uuid := (SELECT id FROM public.staff WHERE user_id = auth.uid()
    AND role = 'super_admin' AND is_active);
BEGIN
  IF actor IS NULL THEN
    RAISE EXCEPTION 'Only active super admins can manage staff users.';
  END IF;
  SELECT user_id INTO target_user_id FROM public.staff
    WHERE id = target_staff_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Staff account not found.'; END IF;
  IF selected_senior AND selected_role <> 'doctor' THEN
    RAISE EXCEPTION 'Senior status requires the doctor role.';
  END IF;
  IF target_user_id = auth.uid() AND
      (selected_role <> 'super_admin' OR (profile->>'is_active')::boolean IS NOT TRUE) THEN
    RAISE EXCEPTION 'You cannot change your own role or active status.';
  END IF;
  IF NULLIF(new_password, '') IS NOT NULL THEN
    IF target_user_id IS NULL THEN RAISE EXCEPTION 'Staff account has no user.'; END IF;
    PERFORM public.update_user_password(target_user_id, new_password);
  END IF;
  -- Branches first, so the working branch below is checked against them.
  IF profile ? 'branches' THEN
    PERFORM public.staff_save_branches(target_staff_id, profile->'branches',
      profile->'shifts', actor);
  END IF;
  UPDATE public.staff SET
    full_name = profile->>'full_name', email = profile->>'email',
    phone = profile->>'phone', role = selected_role,
    is_active = (profile->>'is_active')::boolean,
    is_senior = selected_senior,
    can_manage_payments = selected_role = 'receptionist'
      AND COALESCE((profile->>'can_manage_payments')::boolean, false),
    branch = public.staff_working_branch(target_staff_id, selected_role,
      (profile->>'branch')::public.clinic_location),
    deactivated_at = CASE WHEN (profile->>'is_active')::boolean THEN NULL
      ELSE COALESCE((profile->>'deactivated_at')::timestamptz, now()) END
  WHERE id = target_staff_id;
  IF profile ? 'details' THEN
    PERFORM public.staff_save_details(target_staff_id, profile->'details', actor);
  END IF;
END;
$$;

-- Whether the caller is a head receptionist sharing a branch with p_staff.
CREATE FUNCTION public.current_staff_manages(p_staff uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.staff me
    JOIN public.staff_branches mine ON mine.staff_id = me.id
    JOIN public.staff_branches theirs ON theirs.branch = mine.branch
    WHERE me.user_id = auth.uid() AND me.is_active AND me.role = 'receptionist'
      AND me.can_manage_payments AND theirs.staff_id = p_staff);
$$;
REVOKE ALL ON FUNCTION public.current_staff_manages(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.current_staff_manages(uuid) TO authenticated;
CREATE POLICY staff_details_branch_manager_read ON public.staff_details FOR SELECT
  TO authenticated USING (public.current_staff_manages(staff_id));

-- Upcoming scheduled visits a doctor has at a branch, so the editor can warn
-- before their branch is removed.
CREATE FUNCTION public.staff_upcoming_at_branch(p_staff uuid, p_branch public.clinic_location)
RETURNS integer LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.get_auth_staff_profile()
      WHERE staff_role = 'super_admin' AND staff_active) THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE = '42501';
  END IF;
  RETURN (SELECT count(*) FROM public.appointments a
    JOIN public.appointment_doctors ad ON ad.appointment_id = a.id AND ad.is_active
    WHERE ad.doctor_id = p_staff AND a.branch = p_branch
      AND a.status = 'scheduled' AND a.scheduled_at >= now());
END;
$$;
REVOKE ALL ON FUNCTION public.staff_upcoming_at_branch(uuid, public.clinic_location)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.staff_upcoming_at_branch(uuid, public.clinic_location)
  TO authenticated;

-- ---- Appointment branch ----

ALTER TABLE public.appointments ADD COLUMN branch public.clinic_location;
-- Existing visits take the patient's branch: that is all the data there is.
-- Appointment triggers (balances, edit guards) are off while only the new
-- column is filled in.
ALTER TABLE public.appointments DISABLE TRIGGER USER;
UPDATE public.appointments a SET branch = p.clinic FROM public.patients p
  WHERE p.id = a.patient_id;
ALTER TABLE public.appointments ENABLE TRIGGER USER;
ALTER TABLE public.appointments ALTER COLUMN branch SET NOT NULL;
CREATE INDEX idx_appointments_branch_scheduled ON public.appointments (branch, scheduled_at);

-- Callers that send no branch (older cached clients) get the patient's.
CREATE FUNCTION public.default_appointment_branch() RETURNS trigger
LANGUAGE plpgsql SET search_path = public, pg_temp AS $$
BEGIN
  IF NEW.branch IS NULL THEN
    SELECT clinic INTO NEW.branch FROM public.patients WHERE id = NEW.patient_id;
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER tr_default_appointment_branch BEFORE INSERT ON public.appointments
  FOR EACH ROW EXECUTE FUNCTION public.default_appointment_branch();

CREATE TABLE public.appointment_branch_changes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id uuid NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
  from_branch public.clinic_location NOT NULL,
  to_branch public.clinic_location NOT NULL,
  changed_by uuid REFERENCES public.staff(id) ON DELETE SET NULL,
  changed_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX appointment_branch_changes_appointment_idx
  ON public.appointment_branch_changes (appointment_id);
ALTER TABLE public.appointment_branch_changes ENABLE ROW LEVEL SECURITY;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.appointment_branch_changes TO authenticated;
CREATE POLICY appointment_branch_changes_management_read ON public.appointment_branch_changes
  FOR SELECT TO authenticated USING (public.current_staff_has_management_access());

-- A scheduled visit can move branch with the usual edit permission. Once it
-- is checked in, cancelled or missed only a super admin can correct it.
-- Every change is logged.
CREATE FUNCTION public.guard_appointment_branch() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE editor uuid; editor_role public.user_role;
BEGIN
  IF NEW.branch IS NOT DISTINCT FROM OLD.branch THEN RETURN NEW; END IF;
  SELECT staff_id, staff_role INTO editor, editor_role FROM public.get_auth_staff_profile()
    WHERE staff_active;
  IF auth.uid() IS NOT NULL AND editor_role IS DISTINCT FROM 'super_admin' AND (
      OLD.status <> 'scheduled' OR NOT public.can_current_staff_edit_appointment(OLD.id)) THEN
    RAISE EXCEPTION 'appointment_branch_locked' USING ERRCODE = '42501';
  END IF;
  INSERT INTO public.appointment_branch_changes (appointment_id, from_branch, to_branch, changed_by)
    VALUES (OLD.id, OLD.branch, NEW.branch, editor);
  RETURN NEW;
END;
$$;
CREATE TRIGGER tr_guard_appointment_branch BEFORE UPDATE OF branch ON public.appointments
  FOR EACH ROW EXECUTE FUNCTION public.guard_appointment_branch();

-- Booking takes the branch the visit happens at. The previous signature is
-- replaced; p_branch defaults to the patient's branch.
DROP FUNCTION public.book_recurring_appointments(uuid, public.appointment_type,
  timestamptz[], boolean, uuid, uuid[], date);
CREATE FUNCTION public.book_recurring_appointments(
  p_patient_id uuid, p_type public.appointment_type, p_slots timestamptz[],
  p_use_package boolean, p_creator_id uuid, p_doctor_ids uuid[],
  p_expected_next_visit_date date DEFAULT NULL,
  p_branch public.clinic_location DEFAULT NULL
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE patient public.patients; slot timestamptz; appt uuid; doctor uuid;
  available integer; commitments integer; use_credit boolean;
  doctors uuid[] := coalesce(p_doctor_ids,'{}'::uuid[]);
BEGIN
  IF NOT public.current_staff_has_management_access()
      OR p_creator_id IS DISTINCT FROM (SELECT staff_id FROM public.get_auth_staff_profile()) THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE='42501';
  END IF;
  IF coalesce(cardinality(p_slots),0)=0 OR array_position(p_slots,NULL) IS NOT NULL THEN
    RAISE EXCEPTION 'At least one valid slot is required' USING ERRCODE='22000';
  END IF;
  IF p_type='spinal_traction_session' AND cardinality(doctors)>0 THEN
    RAISE EXCEPTION 'Spinal traction is booked without a doctor' USING ERRCODE='22000';
  END IF;
  IF p_type<>'spinal_traction_session' AND cardinality(doctors)=0 THEN
    RAISE EXCEPTION 'At least one doctor must be assigned' USING ERRCODE='22000';
  END IF;
  IF (SELECT count(DISTINCT value) FROM unnest(p_slots) value)<>cardinality(p_slots) THEN
    RAISE EXCEPTION 'Duplicate booking slots' USING ERRCODE='22000';
  END IF;
  IF (SELECT count(*) FROM public.staff WHERE id=ANY(doctors) AND role='doctor' AND is_active)
      <>cardinality(doctors) THEN
    RAISE EXCEPTION 'Every assigned doctor must be active' USING ERRCODE='22000';
  END IF;
  -- Serialize package checks and due-queue claims for this patient.
  SELECT * INTO patient FROM public.patients WHERE id=p_patient_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Patient not found' USING ERRCODE='P0002'; END IF;
  IF p_expected_next_visit_date IS NOT NULL AND (
      patient.next_visit_date IS DISTINCT FROM p_expected_next_visit_date
      OR EXISTS(SELECT 1 FROM public.appointments WHERE patient_id=p_patient_id
        AND status='scheduled' AND (scheduled_at AT TIME ZONE public.clinic_timezone())::date>=patient.next_visit_date)
      OR EXISTS(SELECT 1 FROM unnest(p_slots) s
        WHERE (s AT TIME ZONE public.clinic_timezone())::date<patient.next_visit_date)) THEN
    RAISE EXCEPTION 'Patient is no longer due for booking.' USING ERRCODE='P0001';
  END IF;
  use_credit := coalesce(p_use_package,false) AND p_type IN ('normal_pt_session','spinal_traction_session');
  IF use_credit THEN
    SELECT count(*) INTO commitments FROM public.appointments WHERE patient_id=p_patient_id
      AND type=p_type AND use_package AND status='scheduled' AND scheduled_at>now();
    available := CASE WHEN p_type='normal_pt_session' THEN patient.session_balance ELSE patient.traction_balance END - commitments;
    IF cardinality(p_slots)>available THEN
      RAISE EXCEPTION 'Insufficient package balance' USING ERRCODE='22000';
    END IF;
  END IF;
  FOREACH slot IN ARRAY p_slots LOOP
    INSERT INTO public.appointments(patient_id,type,scheduled_at,status,use_package,created_by,branch)
      VALUES(p_patient_id,p_type,slot,'scheduled',use_credit,p_creator_id,
        coalesce(p_branch,patient.clinic)) RETURNING id INTO appt;
    FOREACH doctor IN ARRAY doctors LOOP
      INSERT INTO public.appointment_doctors(appointment_id,doctor_id,is_active,added_by)
        VALUES(appt,doctor,true,p_creator_id);
    END LOOP;
  END LOOP;
  IF p_expected_next_visit_date IS NULL THEN
    UPDATE public.patients SET next_visit_date=(SELECT (scheduled_at AT TIME ZONE public.clinic_timezone())::date
      FROM public.appointments WHERE patient_id=p_patient_id AND status='scheduled' AND scheduled_at>=now()
      ORDER BY scheduled_at LIMIT 1) WHERE id=p_patient_id;
  END IF;
END;
$$;
REVOKE ALL ON FUNCTION public.book_recurring_appointments(uuid, public.appointment_type,
  timestamptz[], boolean, uuid, uuid[], date, public.clinic_location) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.book_recurring_appointments(uuid, public.appointment_type,
  timestamptz[], boolean, uuid, uuid[], date, public.clinic_location) TO authenticated;

CREATE OR REPLACE FUNCTION public.execute_clinic_mutation(p_request_id uuid, p_kind text, p_payload jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE previous public.mutation_receipts; outcome jsonb;
  actor uuid := (SELECT staff_id FROM public.get_auth_staff_profile());
  error_code text; error_message text;
  request_hash text := encode(sha256(convert_to(p_payload::text,'UTF8')),'hex');
BEGIN
  IF actor IS NULL OR NOT EXISTS(SELECT 1 FROM public.staff WHERE id=actor AND is_active) THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE='42501';
  END IF;
  IF p_request_id IS NULL OR p_payload IS NULL OR p_kind IS DISTINCT FROM 'booking' THEN
    RAISE EXCEPTION 'Invalid request' USING ERRCODE='22000';
  END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended(p_request_id::text,0));
  SELECT * INTO previous FROM public.mutation_receipts WHERE request_id=p_request_id;
  IF FOUND THEN
    IF previous.actor_id<>actor OR previous.kind<>p_kind OR previous.payload_hash<>request_hash THEN
      RAISE EXCEPTION 'Request identity mismatch' USING ERRCODE='22000';
    END IF;
    RETURN previous.outcome;
  END IF;
  -- Roll back every business write on failure, then retain its definitive result.
  BEGIN
    PERFORM public.book_recurring_appointments(
      (p_payload->>'p_patient_id')::uuid,(p_payload->>'p_type')::public.appointment_type,
      ARRAY(SELECT value::timestamptz FROM jsonb_array_elements_text(p_payload->'p_slots')),
      (p_payload->>'p_use_package')::boolean,actor,
      ARRAY(SELECT value::uuid FROM jsonb_array_elements_text(p_payload->'p_doctor_ids')),
      (p_payload->>'p_expected_next_visit_date')::date,
      (p_payload->>'p_branch')::public.clinic_location);
    IF p_payload->'companion' IS NOT NULL THEN
      PERFORM public.book_recurring_appointments(
        (p_payload->>'p_patient_id')::uuid,(p_payload->'companion'->>'type')::public.appointment_type,
        ARRAY(SELECT value::timestamptz FROM jsonb_array_elements_text(p_payload->'companion'->'slots')),
        false,actor,
        ARRAY(SELECT value::uuid FROM jsonb_array_elements_text(p_payload->'companion'->'doctor_ids')),NULL,
        (p_payload->>'p_branch')::public.clinic_location);
    END IF;
    outcome := jsonb_build_object('ok',true);
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS error_code=RETURNED_SQLSTATE, error_message=MESSAGE_TEXT;
    outcome := jsonb_build_object('ok',false,'code',error_code,'message',error_message);
  END;
  INSERT INTO public.mutation_receipts(request_id,actor_id,kind,payload_hash,outcome)
    VALUES(p_request_id,actor,p_kind,request_hash,outcome);
  RETURN outcome;
END;
$$;

-- Editing takes an optional branch; the trigger above decides whether the
-- change is allowed and logs it.
DROP FUNCTION public.update_appointment_details(uuid, timestamptz, public.appointment_type,
  boolean, uuid[]);
CREATE FUNCTION public.update_appointment_details(
  p_appointment_id uuid, p_scheduled_at timestamptz, p_type public.appointment_type,
  p_use_package boolean, p_doctor_ids uuid[] DEFAULT NULL,
  p_branch public.clinic_location DEFAULT NULL
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE existing_ids uuid[]; editor uuid;
BEGIN
  PERFORM 1 FROM public.appointments WHERE id=p_appointment_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Appointment not found' USING ERRCODE='P0002'; END IF;
  IF NOT public.can_current_staff_edit_appointment(p_appointment_id) THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE='42501';
  END IF;
  -- The branch moves first, while the visit still has its saved status.
  IF p_branch IS NOT NULL THEN
    UPDATE public.appointments SET branch=p_branch
      WHERE id=p_appointment_id AND branch IS DISTINCT FROM p_branch;
  END IF;
  UPDATE public.appointments SET scheduled_at=p_scheduled_at,type=p_type,
    use_package=p_use_package AND p_type IN ('normal_pt_session','spinal_traction_session')
    WHERE id=p_appointment_id;
  IF p_type='spinal_traction_session' THEN
    UPDATE public.appointment_doctors SET is_active=false
      WHERE appointment_id=p_appointment_id AND is_active;
    RETURN;
  END IF;
  IF p_doctor_ids IS NOT NULL THEN
    SELECT array_agg(doctor_id ORDER BY doctor_id) INTO existing_ids
      FROM public.appointment_doctors WHERE appointment_id=p_appointment_id AND is_active;
    IF coalesce(existing_ids,'{}'::uuid[]) IS DISTINCT FROM
        (SELECT coalesce(array_agg(id ORDER BY id),'{}'::uuid[]) FROM unnest(p_doctor_ids) id) THEN
      SELECT staff_id INTO editor FROM public.get_auth_staff_profile();
      PERFORM public.update_appointment_doctors(p_appointment_id,p_doctor_ids,editor);
    END IF;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.appointment_doctors
      WHERE appointment_id=p_appointment_id AND is_active) THEN
    RAISE EXCEPTION 'At least one doctor must be assigned' USING ERRCODE='22000';
  END IF;
END;
$$;
REVOKE ALL ON FUNCTION public.update_appointment_details(uuid, timestamptz,
  public.appointment_type, boolean, uuid[], public.clinic_location) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.update_appointment_details(uuid, timestamptz,
  public.appointment_type, boolean, uuid[], public.clinic_location) TO authenticated;

-- ---- Doctor sessions report ----
-- Sessions belong to the branch where they happened, not the patient's.
CREATE OR REPLACE FUNCTION public.doctor_session_report(p_from date, p_to date,
  p_branch public.clinic_location DEFAULT NULL, p_doctor uuid DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  lo timestamptz;
  hi timestamptz;
  result jsonb;
BEGIN
  IF NOT public.invoice_can('manage') THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE = '42501';
  END IF;
  IF p_from IS NULL OR p_to IS NULL OR p_to < p_from OR p_to - p_from > 366 THEN
    RAISE EXCEPTION 'Invalid report request' USING ERRCODE = '22023';
  END IF;
  lo := p_from::timestamp AT TIME ZONE public.clinic_timezone();
  hi := (p_to + 1)::timestamp AT TIME ZONE public.clinic_timezone();

  WITH visits AS (
    SELECT a.id, a.type, a.status, a.scheduled_at,
      p.id AS patient_id, p.full_name AS patient_name, p.file_number
    FROM public.appointments a
    JOIN public.patients p ON p.id = a.patient_id
    WHERE a.scheduled_at >= lo AND a.scheduled_at < hi
      AND a.type <> 'spinal_traction_session'
      AND (a.status = 'checked_in' OR (a.status = 'scheduled' AND a.scheduled_at < now()))
      AND (p_branch IS NULL OR a.branch = p_branch)
  ),
  team AS (
    SELECT ad.appointment_id, ad.doctor_id, s.full_name
    FROM public.appointment_doctors ad
    JOIN public.staff s ON s.id = ad.doctor_id
    WHERE ad.is_active AND ad.appointment_id IN (SELECT id FROM visits)
  ),
  credits AS (
    SELECT v.*, t.doctor_id, t.full_name AS doctor_name,
      (SELECT coalesce(jsonb_agg(o.full_name ORDER BY o.full_name), '[]'::jsonb)
        FROM team o WHERE o.appointment_id = v.id AND o.doctor_id <> t.doctor_id) AS shared_with
    FROM visits v
    JOIN team t ON t.appointment_id = v.id
    WHERE p_doctor IS NULL OR t.doctor_id = p_doctor
  ),
  done AS (SELECT * FROM credits WHERE status = 'checked_in'),
  waiting AS (
    SELECT id, type, scheduled_at, patient_id, patient_name, file_number,
      jsonb_agg(doctor_name ORDER BY doctor_name) AS doctors
    FROM credits WHERE status = 'scheduled'
    GROUP BY id, type, scheduled_at, patient_id, patient_name, file_number
  ),
  per_doctor AS (
    SELECT doctor_id, doctor_name,
      count(*) FILTER (WHERE status = 'checked_in' AND type = 'normal_pt_session') AS pt_sessions,
      count(*) FILTER (WHERE status = 'checked_in' AND type = 'initial_assessment') AS assessments,
      count(*) FILTER (WHERE status = 'checked_in' AND type = 'reassessment') AS reassessments,
      count(*) FILTER (WHERE status = 'checked_in') AS total,
      count(*) FILTER (WHERE status = 'checked_in' AND jsonb_array_length(shared_with) > 0) AS shared,
      count(*) FILTER (WHERE status = 'scheduled') AS pending
    FROM credits
    GROUP BY doctor_id, doctor_name
  )
  SELECT jsonb_build_object(
    'totals', jsonb_build_object(
      'sessions', (SELECT count(DISTINCT id) FROM done),
      'pt_sessions', (SELECT count(DISTINCT id) FROM done WHERE type = 'normal_pt_session'),
      'assessments', (SELECT count(DISTINCT id) FROM done WHERE type = 'initial_assessment'),
      'reassessments', (SELECT count(DISTINCT id) FROM done WHERE type = 'reassessment'),
      'shared', (SELECT count(DISTINCT id) FROM done WHERE jsonb_array_length(shared_with) > 0),
      'credits', (SELECT count(*) FROM done),
      'pending', (SELECT count(*) FROM waiting),
      'doctors', (SELECT count(*) FROM per_doctor WHERE total > 0)),
    'rows', coalesce((SELECT jsonb_agg(to_jsonb(d) ORDER BY d.doctor_name, d.doctor_id)
      FROM per_doctor d), '[]'::jsonb),
    'sessions', coalesce((SELECT jsonb_agg(jsonb_build_object(
        'appointment_id', s.id, 'doctor_id', s.doctor_id, 'type', s.type,
        'scheduled_at', s.scheduled_at, 'patient_id', s.patient_id,
        'patient_name', s.patient_name, 'file_number', s.file_number,
        'shared_with', s.shared_with) ORDER BY s.doctor_name, s.doctor_id, s.scheduled_at, s.id)
      FROM (SELECT * FROM done ORDER BY doctor_name, doctor_id, scheduled_at, id LIMIT 5000) s),
      '[]'::jsonb),
    'pending', coalesce((SELECT jsonb_agg(jsonb_build_object(
        'appointment_id', w.id, 'type', w.type, 'scheduled_at', w.scheduled_at,
        'patient_id', w.patient_id, 'patient_name', w.patient_name,
        'file_number', w.file_number, 'doctors', w.doctors) ORDER BY w.scheduled_at, w.id)
      FROM (SELECT * FROM waiting ORDER BY scheduled_at, id LIMIT 5000) w), '[]'::jsonb))
  INTO result;
  RETURN result;
END;
$$;
