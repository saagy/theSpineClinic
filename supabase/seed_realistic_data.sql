-- ==============================================================================
-- Spine Clinic Realistic Seeding & On-Demand Schedule Generator
-- ==============================================================================
-- 1. `public.seed_clinic_day_schedule(target_date, branch, clear_existing)`:
--    Generates ~50 appointments across 5 active doctors:
--      - 1 Senior Doctor (s@clinic.com): Initial Assessments and Reassessments.
--      - 4 Treating Doctors (z@clinic.com, doctor.khaled@clinic.com, etc.): Normal PT
--        and Spinal Traction sessions.
-- 2. `public.seed_clinic_schedule_range(start_date, end_date, branch, clear_existing)`
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.seed_clinic_day_schedule(
  p_date date DEFAULT CURRENT_DATE,
  p_branch public.clinic_location DEFAULT 'tagamoa',
  p_clear_existing boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_main_senior uuid;
  v_doctors uuid[];
  v_patients uuid[];
  v_patient_count int;
  v_doc uuid;
  v_pat uuid;
  v_app_id uuid;
  v_type public.appointment_type;
  v_status public.appointment_status;
  v_use_pkg boolean;
  v_sess_bal int;
  v_trac_bal int;
  v_hour int;
  v_minute int;
  v_sched_time timestamptz;
  v_created_count int := 0;
  v_now timestamptz := now();
  i int;
  d int;
BEGIN
  -- 1. Identify main senior doctor
  SELECT id INTO v_main_senior 
  FROM public.staff 
  WHERE email = 's@clinic.com' AND role = 'doctor' AND is_active = true;

  IF v_main_senior IS NULL THEN
    SELECT id INTO v_main_senior FROM public.staff WHERE role = 'doctor' AND is_active = true LIMIT 1;
  END IF;

  -- 2. Gather 5 active doctors (senior doctor first, then 4 treating doctors)
  SELECT array_agg(id) INTO v_doctors
  FROM (
    SELECT id FROM public.staff 
    WHERE role = 'doctor' AND is_active = true 
    ORDER BY 
      CASE email 
        WHEN 's@clinic.com' THEN 1 
        WHEN 'z@clinic.com' THEN 2 
        WHEN 'doctor.khaled@clinic.com' THEN 3
        WHEN 'sagytamergypt@gmail.com' THEN 4
        WHEN 'doctor.mona@clinic.com' THEN 5
        ELSE 6 
      END,
      full_name
    LIMIT 5
  ) s;

  IF v_doctors IS NULL OR array_length(v_doctors, 1) < 1 THEN
    RAISE EXCEPTION 'No active doctors found in staff table.';
  END IF;

  -- 3. Gather patients in this branch
  SELECT array_agg(id) INTO v_patients
  FROM (
    SELECT id FROM public.patients 
    WHERE clinic = p_branch
    ORDER BY created_at DESC
    LIMIT 60
  ) p;

  v_patient_count := coalesce(array_length(v_patients, 1), 0);
  IF v_patient_count < 10 THEN
    RAISE EXCEPTION 'Not enough patients in branch % to seed schedule (found %)', p_branch, v_patient_count;
  END IF;

  -- 4. Optionally clear existing appointments on this date
  IF p_clear_existing THEN
    DELETE FROM public.appointments 
    WHERE scheduled_at >= ((p_date::text || ' 00:00:00')::timestamp AT TIME ZONE 'Africa/Cairo')
      AND scheduled_at < (((p_date + 1)::text || ' 00:00:00')::timestamp AT TIME ZONE 'Africa/Cairo')
      AND patient_id IN (SELECT id FROM public.patients WHERE clinic = p_branch);
  END IF;

  -- 5. Seed 50 appointments
  FOR d IN 1..array_length(v_doctors, 1) LOOP
    v_doc := v_doctors[d];

    FOR i IN 1..10 LOOP
      v_hour := 10 + (i - 1); -- 10:00 to 19:00
      v_minute := CASE WHEN (i % 2 = 0) THEN 30 ELSE 0 END;
      v_sched_time := ((p_date::text || ' ' || lpad(v_hour::text, 2, '0') || ':' || lpad(v_minute::text, 2, '0') || ':00')::timestamp AT TIME ZONE 'Africa/Cairo');

      -- If doctor already has an appointment at this minute, offset by 15 mins
      IF EXISTS (
        SELECT 1 FROM public.appointments a
        JOIN public.appointment_doctors ad ON a.id = ad.appointment_id
        WHERE ad.doctor_id = v_doc AND ad.is_active = true AND a.scheduled_at = v_sched_time
      ) THEN
        v_sched_time := v_sched_time + interval '15 minutes';
      END IF;

      -- Select patient round-robin
      v_pat := v_patients[1 + ((d * 10 + i) % v_patient_count)];

      -- Determine type
      IF v_doc = v_main_senior THEN
        v_type := CASE WHEN (i % 2 = 1) THEN 'initial_assessment'::public.appointment_type ELSE 'reassessment'::public.appointment_type END;
      ELSE
        v_type := CASE WHEN (i % 4 = 0) THEN 'spinal_traction_session'::public.appointment_type ELSE 'normal_pt_session'::public.appointment_type END;
      END IF;

      -- Determine status based on time
      IF v_sched_time < (v_now - interval '30 minutes') THEN
        v_status := CASE WHEN (i = 9 AND d = 2) OR (i = 4 AND d = 4) THEN 'cancelled'::public.appointment_status ELSE 'checked_in'::public.appointment_status END;
      ELSE
        v_status := 'scheduled'::public.appointment_status;
      END IF;

      -- Determine use_package safely against patient balance
      SELECT session_balance, traction_balance INTO v_sess_bal, v_trac_bal FROM public.patients WHERE id = v_pat;
      IF v_type IN ('initial_assessment', 'reassessment') OR v_status = 'cancelled' THEN
        v_use_pkg := false;
      ELSIF v_type = 'normal_pt_session' THEN
        v_use_pkg := (coalesce(v_sess_bal, 0) >= 1);
      ELSIF v_type = 'spinal_traction_session' THEN
        v_use_pkg := (coalesce(v_trac_bal, 0) >= 1);
      ELSE
        v_use_pkg := false;
      END IF;

      -- Insert appointment
      INSERT INTO public.appointments (
        patient_id, type, status, use_package, scheduled_at, created_by
      ) VALUES (
        v_pat, v_type, v_status, v_use_pkg, v_sched_time, v_doc
      ) RETURNING id INTO v_app_id;

      -- Assign doctor
      INSERT INTO public.appointment_doctors (appointment_id, doctor_id, is_active, added_by)
      VALUES (v_app_id, v_doc, true, v_doc);

      v_created_count := v_created_count + 1;
    END LOOP;
  END LOOP;

  RETURN jsonb_build_object(
    'date', p_date,
    'branch', p_branch,
    'doctors_count', array_length(v_doctors, 1),
    'appointments_created', v_created_count
  );
END;
$$;

-- Multi-Day Range Generator
CREATE OR REPLACE FUNCTION public.seed_clinic_schedule_range(
  p_start_date date DEFAULT CURRENT_DATE,
  p_end_date date DEFAULT (CURRENT_DATE + 3),
  p_branch public.clinic_location DEFAULT 'tagamoa',
  p_clear_existing boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_curr date := p_start_date;
  v_day_res jsonb;
  v_total_created int := 0;
  v_days_count int := 0;
BEGIN
  WHILE v_curr <= p_end_date LOOP
    v_day_res := public.seed_clinic_day_schedule(v_curr, p_branch, p_clear_existing);
    v_total_created := v_total_created + (v_day_res->>'appointments_created')::int;
    v_days_count := v_days_count + 1;
    v_curr := v_curr + 1;
  END LOOP;

  RETURN jsonb_build_object(
    'start_date', p_start_date,
    'end_date', p_end_date,
    'branch', p_branch,
    'days_seeded', v_days_count,
    'total_appointments_created', v_total_created
  );
END;
$$;
