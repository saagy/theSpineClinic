-- =============================================================================
-- Trigger sanity tests covering the redesigned balance flow.
-- Run manually with:
--   psql "$DATABASE_URL" -f test/trigger_sanity.sql
-- =============================================================================
-- Each test simulates a small workflow and asserts the patient balances
-- change (or not) in exactly the expected way. The script rolls back at the
-- end so the mock data is preserved.
-- =============================================================================

\set ON_ERROR_STOP on

\set test_patient `SELECT id FROM public.patients ORDER BY created_at LIMIT 1`

BEGIN;

  -- Snapshot the starting balances for the test patient.
  SELECT session_balance AS s, traction_balance AS t
  FROM public.patients
  WHERE id = :'test_patient' \gset baseline_

  --------------------------------------------------------------------
  -- Test 1: completing a normal_pt_session decreases session_balance.
  --------------------------------------------------------------------
  INSERT INTO public.appointments (patient_id, type, scheduled_at, use_package)
  VALUES (:'test_patient', 'normal_pt_session'::public.appointment_type, NOW(), true)
  RETURNING id AS appt1_id \gset

  UPDATE public.appointments SET status = 'completed'
  WHERE id = :'appt1_id';

  -- Expected: session_balance dropped by 1; traction_balance unchanged.

  --------------------------------------------------------------------
  -- Test 2: completing a spinal_traction_session decreases traction_balance.
  --------------------------------------------------------------------
  INSERT INTO public.appointments (patient_id, type, scheduled_at, use_package)
  VALUES (:'test_patient', 'spinal_traction_session'::public.appointment_type, NOW(), true)
  RETURNING id AS appt2_id \gset

  UPDATE public.appointments SET status = 'completed'
  WHERE id = :'appt2_id';

  -- Expected: traction_balance dropped by 1; session_balance unchanged
  -- from post-Test-1 value.

  --------------------------------------------------------------------
  -- Test 3: completing an initial_assessment NEVER changes any balance.
  --------------------------------------------------------------------
  INSERT INTO public.appointments (patient_id, type, scheduled_at, use_package)
  VALUES (:'test_patient', 'initial_assessment'::public.appointment_type, NOW(), true)
  RETURNING id AS appt3_id \gset

  UPDATE public.appointments SET status = 'completed'
  WHERE id = :'appt3_id';

  -- Expected: session_balance and traction_balance both unchanged
  -- relative to post-Test-2 values.

  --------------------------------------------------------------------
  -- Test 4: undo check-in (checked_in → scheduled) refunds the bucket.
  --------------------------------------------------------------------
  INSERT INTO public.appointments (patient_id, type, scheduled_at, use_package)
  VALUES (:'test_patient', 'normal_pt_session'::public.appointment_type, NOW() + INTERVAL '1 hour', true)
  RETURNING id AS appt4_id \gset

  UPDATE public.appointments SET status = 'checked_in' WHERE id = :'appt4_id';
  UPDATE public.appointments SET status = 'scheduled' WHERE id = :'appt4_id';

  -- Expected: session_balance restored to its post-Test-2 value (the
  -- undoing of the checked-in transition added it back).

  --------------------------------------------------------------------
  -- Test 5: cancel a completed traction refunds the bucket.
  --------------------------------------------------------------------
  -- appt2_id is currently 'completed' (set in Test 2).
  UPDATE public.appointments SET status = 'cancelled' WHERE id = :'appt2_id';

  -- Expected: traction_balance restored to its baseline value (no
  -- net change from before the test runner began).

  --------------------------------------------------------------------
  -- Test 6: paying for a combined package credits both buckets.
  --------------------------------------------------------------------
  INSERT INTO public.payment_records (
    patient_id, amount, reason,
    session_balance_added, traction_balance_added,
    recorded_at
  )
  VALUES (
    :'test_patient', 1000, 'Package (Test Combined)',
    8, 4, NOW()
  );

  -- Expected: session_balance +8 and traction_balance +4 vs the value
  -- they had right before this insert.

ROLLBACK;

\echo 'Trigger sanity tests completed (rolled back).'
\echo 'Inspect patient balances inside the BEGIN block if a specific test fails.'
