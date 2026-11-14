-- Doctor sessions report: how many sessions each doctor did in a period, by
-- appointment type, for the monthly doctor pay. It reads appointments only,
-- never invoices.
--
-- * A session counts when its appointment is checked in. Cancelled
--   appointments never count.
-- * Appointments still scheduled at a time already past are returned as
--   `pending`, so reception can check them in or cancel them before pay is
--   worked out. They are not in the counts.
-- * Every active doctor on an appointment is credited with the session, so a
--   shared session counts once for each of its doctors. `sessions` counts
--   each appointment once.
-- * Spinal traction is done without a doctor and is never counted, including
--   older traction appointments that still have a doctor attached.
-- * The branch is the patient's branch, as on every schedule screen. Days are
--   clinic days.
--
-- Same access and limits as invoice_report: payment receptionists and super
-- admins, at most 366 days, detail rows capped at 5000, complete totals.

CREATE FUNCTION public.doctor_session_report(p_from date, p_to date,
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
      AND (p_branch IS NULL OR p.clinic = p_branch)
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

REVOKE ALL ON FUNCTION public.doctor_session_report(date, date, public.clinic_location, uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.doctor_session_report(date, date, public.clinic_location, uuid)
  TO authenticated;
