-- Visit outcomes, their history, and corrected session balances
-- (docs/billing-explained.md, section 9).
--
-- 1. Every booking, status change and deletion of a visit is recorded with
--    who did it and when (appointment_events). The rows are never edited.
-- 2. An outcome (checked in, cancelled, no-show) is free to change on the day
--    it was recorded. Once that day and the visit's day have both passed,
--    only payment staff may change it, and they must give a reason.
-- 3. A visit that was ever checked in cannot be deleted.
-- 4. PT and traction visits always use the package balance. Booking no
--    longer refuses a short balance (the app warns); check-in still does.
-- 5. A scheduled package visit holds its session for the whole of its day,
--    not only until its start time.
-- 6. Payment staff correct balances through adjust_patient_balance, which
--    records before, after, who and why. Any other direct balance write by a
--    signed-in user is refused.
-- 7. Services leaves out fully refunded lines; Balances due adds age buckets.

-- 1. Visit history ---------------------------------------------------------

ALTER TABLE public.appointments ADD COLUMN status_changed_at timestamptz;

CREATE TABLE public.appointment_events (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  -- No foreign keys: the history outlives a deleted visit.
  appointment_id uuid NOT NULL,
  patient_id uuid NOT NULL,
  kind text NOT NULL CHECK (kind IN ('booked', 'status', 'deleted')),
  from_status public.appointment_status,
  to_status public.appointment_status,
  type public.appointment_type NOT NULL,
  scheduled_at timestamptz NOT NULL,
  reason text CHECK (reason IS NULL OR char_length(reason) <= 500),
  actor_id uuid,
  actor_name text,
  at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX appointment_events_appointment_idx ON public.appointment_events (appointment_id, at);
CREATE INDEX appointment_events_patient_idx ON public.appointment_events (patient_id, at);
ALTER TABLE public.appointment_events ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON public.appointment_events TO authenticated;
CREATE POLICY appointment_events_read ON public.appointment_events FOR SELECT TO authenticated
  USING (public.can_current_staff_access_patient(patient_id));
-- No write policies: only record_appointment_event writes.

-- The reason given to set_appointment_status, or NULL.
CREATE FUNCTION public.visit_change_reason() RETURNS text
LANGUAGE sql STABLE SET search_path = '' AS $$
  SELECT nullif(btrim(coalesce(current_setting('app.visit_reason', true), '')), '');
$$;

CREATE FUNCTION public.record_appointment_event() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE actor_id uuid; actor_name text;
BEGIN
  SELECT s.id, s.full_name INTO actor_id, actor_name FROM public.staff s WHERE s.user_id = auth.uid();
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.appointment_events (appointment_id, patient_id, kind, to_status, type,
      scheduled_at, actor_id, actor_name)
    VALUES (NEW.id, NEW.patient_id, 'booked', NEW.status, NEW.type, NEW.scheduled_at,
      actor_id, actor_name);
  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.status IS DISTINCT FROM OLD.status THEN
      INSERT INTO public.appointment_events (appointment_id, patient_id, kind, from_status,
        to_status, type, scheduled_at, reason, actor_id, actor_name)
      VALUES (NEW.id, NEW.patient_id, 'status', OLD.status, NEW.status, NEW.type,
        NEW.scheduled_at, public.visit_change_reason(), actor_id, actor_name);
    END IF;
  ELSE
    INSERT INTO public.appointment_events (appointment_id, patient_id, kind, from_status, type,
      scheduled_at, reason, actor_id, actor_name)
    VALUES (OLD.id, OLD.patient_id, 'deleted', OLD.status, OLD.type, OLD.scheduled_at,
      public.visit_change_reason(), actor_id, actor_name);
  END IF;
  RETURN NULL;
END;
$$;
REVOKE ALL ON FUNCTION public.record_appointment_event() FROM PUBLIC, anon, authenticated;
CREATE TRIGGER tr_record_appointment_event AFTER INSERT OR UPDATE OF status OR DELETE
  ON public.appointments FOR EACH ROW EXECUTE FUNCTION public.record_appointment_event();

-- 2. Earlier days' outcomes ------------------------------------------------

CREATE FUNCTION public.guard_appointment_status() RETURNS trigger
LANGUAGE plpgsql SET search_path = public, pg_temp AS $$
DECLARE
  today date := (now() AT TIME ZONE public.clinic_timezone())::date;
  recorded date := (coalesce(OLD.status_changed_at, OLD.scheduled_at)
    AT TIME ZONE public.clinic_timezone())::date;
  visit_day date := (OLD.scheduled_at AT TIME ZONE public.clinic_timezone())::date;
BEGIN
  IF NEW.status IS NOT DISTINCT FROM OLD.status THEN RETURN NEW; END IF;
  NEW.status_changed_at := now();
  IF auth.uid() IS NOT NULL AND OLD.status <> 'scheduled'
      AND greatest(recorded, visit_day) < today
      AND (NOT public.invoice_can('manage') OR public.visit_change_reason() IS NULL) THEN
    RAISE EXCEPTION 'visit_outcome_locked' USING ERRCODE = '42501';
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER tr_guard_appointment_status BEFORE UPDATE OF status ON public.appointments
  FOR EACH ROW EXECUTE FUNCTION public.guard_appointment_status();

-- The app's only way to change a visit's status. Runs with the caller's
-- rights, so the appointment policies still decide who may change what.
CREATE FUNCTION public.set_appointment_status(p_appointment_id uuid,
  p_status public.appointment_status, p_reason text DEFAULT NULL)
RETURNS void LANGUAGE plpgsql SET search_path = public, pg_temp AS $$
BEGIN
  IF p_status IS NULL OR char_length(coalesce(p_reason, '')) > 500 THEN
    RAISE EXCEPTION 'Invalid status change' USING ERRCODE = '22023';
  END IF;
  PERFORM set_config('app.visit_reason', coalesce(btrim(p_reason), ''), true);
  UPDATE public.appointments SET status = p_status WHERE id = p_appointment_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'visit_not_found' USING ERRCODE = 'P0001'; END IF;
  PERFORM set_config('app.visit_reason', '', true);
END;
$$;
REVOKE ALL ON FUNCTION public.set_appointment_status(uuid, public.appointment_status, text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_appointment_status(uuid, public.appointment_status, text)
  TO authenticated;

-- 3. Attended visits are never deleted --------------------------------------

CREATE OR REPLACE FUNCTION public.guard_appointment_edit()
RETURNS trigger LANGUAGE plpgsql SET search_path=public,pg_temp AS $$
BEGIN
  IF auth.uid() IS NULL THEN RETURN coalesce(NEW,OLD); END IF;
  IF TG_OP='UPDATE' AND (NEW.patient_id IS DISTINCT FROM OLD.patient_id
      OR NEW.created_by IS DISTINCT FROM OLD.created_by OR NEW.id IS DISTINCT FROM OLD.id) THEN
    RAISE EXCEPTION 'Appointment identity cannot be changed' USING ERRCODE='42501';
  END IF;
  IF TG_OP='DELETE' AND (OLD.status='checked_in' OR EXISTS (SELECT 1
      FROM public.appointment_events e WHERE e.appointment_id=OLD.id AND e.to_status='checked_in')) THEN
    RAISE EXCEPTION 'visit_was_attended' USING ERRCODE='42501';
  END IF;
  IF TG_OP='DELETE' OR NEW.scheduled_at IS DISTINCT FROM OLD.scheduled_at
      OR NEW.type IS DISTINCT FROM OLD.type OR NEW.use_package IS DISTINCT FROM OLD.use_package THEN
    IF NOT public.can_current_staff_edit_appointment(OLD.id) THEN
      RAISE EXCEPTION 'Permission denied: cannot edit appointment' USING ERRCODE='42501';
    END IF;
  END IF;
  RETURN coalesce(NEW,OLD);
END;
$$;

-- 4. PT and traction always use the package ---------------------------------

-- Runs after guard_appointment_edit (triggers fire by name), so the guard
-- judges what the caller sent. Visits already checked in, cancelled or
-- missed keep the flag they were recorded with.
CREATE FUNCTION public.apply_appointment_package_rule() RETURNS trigger
LANGUAGE plpgsql SET search_path = public, pg_temp AS $$
BEGIN
  IF auth.uid() IS NULL THEN RETURN NEW; END IF;
  IF TG_OP = 'INSERT' OR NEW.type IS DISTINCT FROM OLD.type OR NEW.status = 'scheduled' THEN
    NEW.use_package := NEW.type IN ('normal_pt_session', 'spinal_traction_session');
  ELSE
    NEW.use_package := OLD.use_package;
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER tr_appointment_package_rule BEFORE INSERT OR UPDATE ON public.appointments
  FOR EACH ROW EXECUTE FUNCTION public.apply_appointment_package_rule();

-- Visits that have not happened yet move to the package now.
UPDATE public.appointments SET use_package = true
  WHERE status = 'scheduled' AND NOT use_package
    AND type IN ('normal_pt_session', 'spinal_traction_session');

-- Booking always uses the package and never refuses a short balance.
CREATE OR REPLACE FUNCTION public.book_recurring_appointments(
  p_patient_id uuid, p_type public.appointment_type, p_slots timestamptz[],
  p_use_package boolean, p_creator_id uuid, p_doctor_ids uuid[],
  p_expected_next_visit_date date DEFAULT NULL,
  p_branch public.clinic_location DEFAULT NULL
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE patient public.patients; slot timestamptz; appt uuid; doctor uuid;
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
  -- Serialize due-queue claims for this patient.
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
  FOREACH slot IN ARRAY p_slots LOOP
    INSERT INTO public.appointments(patient_id,type,scheduled_at,status,use_package,created_by,branch)
      VALUES(p_patient_id,p_type,slot,'scheduled',
        p_type IN ('normal_pt_session','spinal_traction_session'),p_creator_id,
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

-- 5 and 6. Sessions held all day; only marked writes change balances -------

-- Removing sessions must leave enough for every package visit still
-- scheduled from the start of today.
CREATE OR REPLACE FUNCTION public.invoice_adjust_sessions(p_patient_id uuid, p_pt integer, p_traction integer)
RETURNS void LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE person public.patients; booked_pt integer; booked_tr integer;
  day_start timestamptz := ((now() AT TIME ZONE public.clinic_timezone())::date::timestamp
    AT TIME ZONE public.clinic_timezone());
BEGIN
  IF coalesce(p_pt, 0) = 0 AND coalesce(p_traction, 0) = 0 THEN RETURN; END IF;
  SELECT * INTO STRICT person FROM public.patients WHERE id = p_patient_id FOR UPDATE;
  SELECT count(*) FILTER (WHERE type = 'normal_pt_session'),
    count(*) FILTER (WHERE type = 'spinal_traction_session')
  INTO booked_pt, booked_tr FROM public.appointments
  WHERE patient_id = p_patient_id AND use_package AND status = 'scheduled' AND scheduled_at >= day_start;
  -- Additions always succeed; only removals are checked.
  IF (p_pt < 0 AND person.session_balance + p_pt < greatest(booked_pt, 0))
    OR (p_traction < 0 AND person.traction_balance + p_traction < greatest(booked_tr, 0)) THEN
    RAISE EXCEPTION 'sessions_in_use' USING ERRCODE = 'P0001';
  END IF;
  PERFORM set_config('app.balance_write', 'on', true);
  UPDATE public.patients SET session_balance = session_balance + p_pt,
    traction_balance = traction_balance + p_traction WHERE id = p_patient_id;
  PERFORM set_config('app.balance_write', '', true);
END;
$$;

-- Balances change through invoices, check-ins (nested triggers) and
-- adjust_patient_balance only. Seeds and maintenance (no signed-in user)
-- are unaffected.
CREATE OR REPLACE FUNCTION public.guard_patient_balance_write()
RETURNS trigger LANGUAGE plpgsql SET search_path = public, pg_temp AS $$
DECLARE changed boolean;
BEGIN
  IF auth.uid() IS NULL OR pg_trigger_depth() > 1
      OR coalesce(current_setting('app.balance_write', true), '') = 'on' THEN
    RETURN NEW;
  END IF;
  IF TG_OP = 'INSERT' THEN
    changed := NEW.session_balance <> 0 OR NEW.traction_balance <> 0;
  ELSE
    changed := NEW.session_balance IS DISTINCT FROM OLD.session_balance
      OR NEW.traction_balance IS DISTINCT FROM OLD.traction_balance;
  END IF;
  IF changed THEN
    RAISE EXCEPTION 'Permission denied: cannot manually change package balances'
      USING ERRCODE='42501';
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER guard_patient_balance_write ON public.patients;
CREATE TRIGGER guard_patient_balance_write BEFORE INSERT OR UPDATE ON public.patients
  FOR EACH ROW EXECUTE FUNCTION public.guard_patient_balance_write();

CREATE TABLE public.patient_balance_adjustments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id uuid NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
  pt_before integer NOT NULL,
  pt_after integer NOT NULL CHECK (pt_after >= 0),
  traction_before integer NOT NULL,
  traction_after integer NOT NULL CHECK (traction_after >= 0),
  reason text NOT NULL CHECK (char_length(reason) BETWEEN 1 AND 500 AND reason = btrim(reason)),
  adjusted_by uuid REFERENCES public.staff(id) ON DELETE SET NULL,
  adjusted_by_name text NOT NULL,
  adjusted_at timestamptz NOT NULL DEFAULT now(),
  CHECK (pt_before <> pt_after OR traction_before <> traction_after)
);
CREATE INDEX patient_balance_adjustments_patient_idx
  ON public.patient_balance_adjustments (patient_id, adjusted_at DESC);
ALTER TABLE public.patient_balance_adjustments ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON public.patient_balance_adjustments TO authenticated;
CREATE POLICY patient_balance_adjustments_read ON public.patient_balance_adjustments
  FOR SELECT TO authenticated USING (public.can_current_staff_access_patient(patient_id));
-- No write policies: only adjust_patient_balance writes.

-- Sets both balances to new values. The caller sends the balances it showed,
-- so a balance changed meanwhile (a check-in, an invoice) is not overwritten.
CREATE FUNCTION public.adjust_patient_balance(p_patient_id uuid, p_expected_pt integer,
  p_expected_traction integer, p_pt integer, p_traction integer, p_reason text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE person public.patients; actor public.staff; why text := btrim(coalesce(p_reason, ''));
BEGIN
  SELECT * INTO actor FROM public.staff WHERE user_id = auth.uid() AND is_active;
  IF actor.id IS NULL OR NOT public.invoice_can('manage')
      OR NOT public.can_current_staff_access_patient(p_patient_id) THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE = '42501';
  END IF;
  IF p_pt IS NULL OR p_traction IS NULL OR p_pt < 0 OR p_traction < 0
      OR p_pt > 1000 OR p_traction > 1000 OR why = '' OR char_length(why) > 500 THEN
    RAISE EXCEPTION 'invalid_adjustment' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO person FROM public.patients WHERE id = p_patient_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Permission denied' USING ERRCODE = '42501'; END IF;
  IF person.session_balance IS DISTINCT FROM p_expected_pt
      OR person.traction_balance IS DISTINCT FROM p_expected_traction THEN
    RAISE EXCEPTION 'balance_changed' USING ERRCODE = 'P0001';
  END IF;
  IF p_pt = person.session_balance AND p_traction = person.traction_balance THEN
    RAISE EXCEPTION 'invalid_adjustment' USING ERRCODE = '22023';
  END IF;
  PERFORM set_config('app.balance_write', 'on', true);
  UPDATE public.patients SET session_balance = p_pt, traction_balance = p_traction
    WHERE id = p_patient_id;
  PERFORM set_config('app.balance_write', '', true);
  INSERT INTO public.patient_balance_adjustments (patient_id, pt_before, pt_after,
    traction_before, traction_after, reason, adjusted_by, adjusted_by_name)
  VALUES (p_patient_id, person.session_balance, p_pt, person.traction_balance, p_traction,
    why, actor.id, actor.full_name);
END;
$$;
REVOKE ALL ON FUNCTION public.adjust_patient_balance(uuid, integer, integer, integer, integer, text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.adjust_patient_balance(uuid, integer, integer, integer, integer, text)
  TO authenticated;

-- 7. Reports ---------------------------------------------------------------

-- Balances due by how long each invoice has been open, counted from its date.
CREATE OR REPLACE FUNCTION public.invoice_report_outstanding(p_branch public.clinic_location)
RETURNS jsonb LANGUAGE sql STABLE SET search_path = '' AS $$
  WITH open AS (
    SELECT i.patient_id, i.invoice_date, f.due_minor,
      (now() AT TIME ZONE public.clinic_timezone())::date - i.invoice_date AS age
    FROM public.invoices i CROSS JOIN LATERAL public.invoice_figures(i.id) f
    WHERE i.voided_at IS NULL AND f.due_minor > 0 AND (p_branch IS NULL OR i.branch = p_branch)
  ), grouped AS (
    SELECT o.patient_id, p.full_name AS patient_name, p.file_number,
      count(*) AS open_invoices, sum(o.due_minor) AS due_minor, min(o.invoice_date) AS oldest_date,
      coalesce(sum(o.due_minor) FILTER (WHERE o.age <= 30), 0) AS due_0_30_minor,
      coalesce(sum(o.due_minor) FILTER (WHERE o.age BETWEEN 31 AND 60), 0) AS due_31_60_minor,
      coalesce(sum(o.due_minor) FILTER (WHERE o.age BETWEEN 61 AND 90), 0) AS due_61_90_minor,
      coalesce(sum(o.due_minor) FILTER (WHERE o.age > 90), 0) AS due_over_90_minor
    FROM open o JOIN public.patients p ON p.id = o.patient_id
    GROUP BY o.patient_id, p.full_name, p.file_number
  )
  SELECT jsonb_build_object(
    'totals', (SELECT jsonb_build_object('due_minor', coalesce(sum(due_minor), 0),
      'open_invoices', coalesce(sum(open_invoices), 0), 'row_count', count(*),
      'due_0_30_minor', coalesce(sum(due_0_30_minor), 0),
      'due_31_60_minor', coalesce(sum(due_31_60_minor), 0),
      'due_61_90_minor', coalesce(sum(due_61_90_minor), 0),
      'due_over_90_minor', coalesce(sum(due_over_90_minor), 0)) FROM grouped),
    'rows', coalesce((SELECT jsonb_agg(to_jsonb(r) ORDER BY r.due_minor DESC, r.patient_name) FROM (
      SELECT * FROM grouped ORDER BY due_minor DESC, patient_name LIMIT 5000) r), '[]'::jsonb));
$$;
REVOKE ALL ON FUNCTION public.invoice_report_outstanding(public.clinic_location)
  FROM PUBLIC, anon, authenticated;

-- A line refunded in full (no value and no sessions left) was not sold.
-- Lines that were free from the start, or brought to zero by a discount,
-- still count.
CREATE OR REPLACE FUNCTION public.invoice_report_services(p_from date, p_to date, p_branch public.clinic_location)
RETURNS jsonb LANGUAGE sql STABLE SET search_path = '' AS $$
  WITH sold AS (
    SELECT l.id AS line_id, l.service_id, l.service_type, l.quantity, f.value_minor AS billed_minor,
      f.collected_minor, i.id AS invoice_id, i.number AS invoice_number, i.branch AS invoice_branch,
      i.invoice_date, i.created_at, i.patient_id, i.patient_name, i.file_number
    FROM public.invoices i
    CROSS JOIN LATERAL public.invoice_line_figures(i.id) f
    JOIN public.invoice_lines l ON l.id = f.line_id
    WHERE i.voided_at IS NULL AND i.invoice_date BETWEEN p_from AND p_to
      AND (p_branch IS NULL OR i.branch = p_branch)
      AND NOT (f.value_minor = 0 AND f.sessions_left = 0 AND EXISTS (
        SELECT 1 FROM public.invoice_refund_lines rl
        JOIN public.invoice_refunds rf ON rf.id = rl.refund_id
        WHERE rl.line_id = l.id AND rf.voided_at IS NULL AND rf.kind = 'refund'))
  ), grouped AS (
    SELECT s.service_id, c.name AS service_name, c.service_type, sum(s.quantity) AS units,
      count(DISTINCT s.invoice_id) AS invoice_count, sum(s.billed_minor) AS billed_minor,
      sum(s.collected_minor) AS collected_minor
    FROM sold s JOIN public.service_catalog c ON c.id = s.service_id
    GROUP BY s.service_id, c.name, c.service_type
  )
  SELECT jsonb_build_object(
    'totals', (SELECT jsonb_build_object('units', coalesce(sum(quantity), 0),
      'billed_minor', coalesce(sum(billed_minor), 0),
      'collected_minor', coalesce(sum(collected_minor), 0), 'row_count', count(*)) FROM sold),
    'rows', coalesce((SELECT jsonb_agg(to_jsonb(g) ORDER BY g.billed_minor DESC, g.service_name)
      FROM grouped g), '[]'::jsonb),
    'lines', coalesce((SELECT jsonb_agg(to_jsonb(r) ORDER BY r.invoice_date, r.created_at, r.line_id) FROM (
      SELECT * FROM sold ORDER BY invoice_date, created_at, line_id LIMIT 5000) r), '[]'::jsonb));
$$;
REVOKE ALL ON FUNCTION public.invoice_report_services(date, date, public.clinic_location)
  FROM PUBLIC, anon, authenticated;
