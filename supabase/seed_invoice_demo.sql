-- ==============================================================================
-- Invoice demo data (DESTRUCTIVE). Run as the database owner on a project whose
-- financial data is disposable. It:
--   1. deletes every pilot billing record, legacy payment record and invoice,
--      and resets all patient session balances to zero;
--   2. seeds the service catalog;
--   3. replays about 60 days of invoices and payments through
--      execute_invoice_command, so every document obeys the real rules, then
--      backdates timestamps. seed_invoice_demo_events.sql adds refunds,
--      voids and corrections afterwards.
-- Requires one active super admin or payment receptionist, active doctors and
-- existing patients. Deterministic: setseed() fixes the random choices.
-- ==============================================================================
BEGIN;
DELETE FROM public.invoice_allocations; DELETE FROM public.invoice_refund_lines;
DELETE FROM public.invoice_refunds; DELETE FROM public.invoice_receipts;
DELETE FROM public.invoice_line_doctors; DELETE FROM public.invoice_lines;
UPDATE public.invoices SET replaces_invoice_id = NULL; DELETE FROM public.invoices;
DELETE FROM public.invoice_number_series; DELETE FROM public.service_catalog;
DELETE FROM public.mutation_receipts WHERE kind LIKE 'invoice:%' OR kind LIKE 'billing:%'
  OR kind IN ('payment', 'collect_due', 'payment_edit');
UPDATE public.patients SET session_balance = 0, traction_balance = 0;

CREATE OR REPLACE FUNCTION pg_temp.cmd(p_user uuid, p_kind text, p_payload jsonb) RETURNS jsonb
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM set_config('request.jwt.claim.sub', p_user::text, true);
  RETURN public.execute_invoice_command(gen_random_uuid(), p_kind, p_payload);
END;
$$;
-- Moves a document's timestamps to the simulated moment it happened.
CREATE OR REPLACE FUNCTION pg_temp.at(p_invoice uuid, p_at timestamptz) RETURNS void LANGUAGE sql AS $$
  UPDATE public.invoices SET created_at = p_at WHERE id = p_invoice AND created_at > now() - interval '1 minute';
  UPDATE public.invoice_receipts SET recorded_at = p_at,
    received_at = CASE WHEN replaces_receipt_id IS NULL THEN p_at ELSE received_at END
    WHERE invoice_id = p_invoice AND recorded_at > now() - interval '1 minute';
  UPDATE public.invoice_receipts SET voided_at = p_at
    WHERE invoice_id = p_invoice AND voided_at > now() - interval '1 minute';
  UPDATE public.invoice_refunds SET recorded_at = p_at
    WHERE invoice_id = p_invoice AND recorded_at > now() - interval '1 minute';
  UPDATE public.invoices SET voided_at = p_at WHERE id = p_invoice AND voided_at > now() - interval '1 minute';
$$;
CREATE OR REPLACE FUNCTION pg_temp.payload(p_patient public.patients, p_day date, p_lines jsonb, p_discount jsonb,
  p_payments jsonb) RETURNS jsonb LANGUAGE sql AS $$
  SELECT jsonb_build_object('patient_id', p_patient.id, 'branch', p_patient.clinic, 'invoice_date', p_day,
    'lines', p_lines, 'discount', p_discount, 'payments', p_payments);
$$;

DO $$
DECLARE
  manager uuid := (SELECT user_id FROM public.staff WHERE is_active AND user_id IS NOT NULL AND (role = 'super_admin'
    OR (role = 'receptionist' AND can_manage_payments)) ORDER BY role DESC, created_at LIMIT 1);
  desk uuid := coalesce((SELECT user_id FROM public.staff WHERE is_active AND user_id IS NOT NULL
    AND role = 'receptionist' AND NOT can_manage_payments ORDER BY created_at LIMIT 1), manager);
  doctors uuid[] := ARRAY(SELECT id FROM public.staff WHERE role = 'doctor' AND is_active ORDER BY full_name);
  patient_ids uuid[] := ARRAY(SELECT id FROM public.patients ORDER BY file_number LIMIT 80);
  person public.patients; svc public.service_catalog; inv public.invoice_register;
  day date; moment timestamptz; lines jsonb; discount jsonb; payments jsonb; result jsonb;
  total bigint; roll float; actor uuid; created integer := 0;
BEGIN
  IF manager IS NULL OR cardinality(doctors) = 0 OR cardinality(patient_ids) = 0 THEN
    RAISE EXCEPTION 'Seed needs an active manager, active doctors and patients';
  END IF;
  PERFORM setseed(0.42);
  FOR svc IN SELECT * FROM jsonb_populate_recordset(NULL::public.service_catalog, '[
    {"name":"PT session","service_type":"pt_session","sessions_per_unit":1,"price_minor":45000,"attributes_doctors":true},
    {"name":"6 PT sessions","service_type":"pt_session","sessions_per_unit":6,"price_minor":240000,"attributes_doctors":true},
    {"name":"12 PT sessions","service_type":"pt_session","sessions_per_unit":12,"price_minor":450000,"attributes_doctors":true},
    {"name":"Spinal traction session","service_type":"traction_session","sessions_per_unit":1,"price_minor":25000,"attributes_doctors":false},
    {"name":"6 spinal traction sessions","service_type":"traction_session","sessions_per_unit":6,"price_minor":135000,"attributes_doctors":false},
    {"name":"12 spinal traction sessions","service_type":"traction_session","sessions_per_unit":12,"price_minor":250000,"attributes_doctors":false},
    {"name":"Initial assessment","service_type":"initial_assessment","sessions_per_unit":1,"price_minor":60000,"attributes_doctors":true},
    {"name":"Reassessment","service_type":"reassessment","sessions_per_unit":1,"price_minor":40000,"attributes_doctors":true},
    {"name":"Kinesio taping","service_type":"other","sessions_per_unit":1,"price_minor":15000,"attributes_doctors":true},
    {"name":"Shockwave therapy session","service_type":"other","sessions_per_unit":1,"price_minor":70000,"attributes_doctors":true}]')
  LOOP
    PERFORM pg_temp.cmd(manager, 'service_save', to_jsonb(svc) || '{"active":true}');
  END LOOP;

  -- Daily invoices: assessments, single sessions and packages, varied payment.
  FOR day IN SELECT d::date FROM generate_series(current_date - 59, current_date, interval '1 day') d LOOP
    CONTINUE WHEN extract(isodow FROM day) = 5; -- the clinic is closed on Fridays
    FOR k IN 1..(3 + floor(random() * 5))::integer LOOP
      SELECT * INTO person FROM public.patients WHERE id = patient_ids[1 + floor(random() * cardinality(patient_ids))::integer];
      SELECT * INTO svc FROM public.service_catalog ORDER BY random() LIMIT 1;
      lines := jsonb_build_array(jsonb_build_object('service_id', svc.id, 'quantity', 1,
        'unit_price_minor', svc.price_minor, 'doctor_ids', CASE WHEN NOT svc.attributes_doctors THEN '[]'::jsonb
          WHEN random() < 0.15 THEN '[]'::jsonb WHEN random() < 0.2 THEN to_jsonb(doctors[1:2])
          ELSE jsonb_build_array(doctors[1 + floor(random() * cardinality(doctors))::integer]) END));
      total := svc.price_minor;
      IF random() < 0.3 THEN
        SELECT * INTO svc FROM public.service_catalog WHERE sessions_per_unit = 1 ORDER BY random() LIMIT 1;
        lines := lines || jsonb_build_array(jsonb_build_object('service_id', svc.id, 'quantity', 1,
          'unit_price_minor', svc.price_minor, 'doctor_ids', '[]'::jsonb));
        total := total + svc.price_minor;
      END IF;
      roll := random();
      discount := CASE WHEN roll < 0.03 THEN '{"kind":"percent","value":10000}'
        WHEN roll < 0.12 THEN '{"kind":"percent","value":1000}'
        WHEN roll < 0.18 THEN '{"kind":"amount","value":5000}' ELSE '{"kind":"none","value":0}' END;
      total := CASE WHEN roll < 0.03 THEN 0 WHEN roll < 0.12 THEN total - round(total * 0.1)
        WHEN roll < 0.18 THEN total - 5000 ELSE total END;
      roll := random();
      payments := CASE WHEN total = 0 OR roll >= 0.85 THEN '[]'::jsonb
        WHEN roll < 0.35 THEN jsonb_build_array(jsonb_build_object('method', 'cash', 'amount_minor', total))
        WHEN roll < 0.55 THEN jsonb_build_array(jsonb_build_object('method', 'visa', 'amount_minor', total))
        WHEN roll < 0.62 THEN jsonb_build_array(jsonb_build_object('method', 'cash', 'amount_minor', total / 2),
          jsonb_build_object('method', 'visa', 'amount_minor', total - total / 2))
        ELSE jsonb_build_array(jsonb_build_object('method', 'cash', 'amount_minor', (total / 200000 + 1) * 50000))
        END;
      IF jsonb_array_length(payments) = 1 AND (payments->0->>'amount_minor')::bigint > total THEN
        payments := jsonb_build_array(jsonb_build_object('method', 'cash', 'amount_minor', total));
      END IF;
      actor := CASE WHEN discount->>'kind' = 'none' THEN desk ELSE manager END;
      result := pg_temp.cmd(actor, 'invoice_create', pg_temp.payload(person, day, lines, discount, payments));
      IF (result->>'ok')::boolean THEN
        created := created + 1;
        PERFORM pg_temp.at((result->>'invoice_id')::uuid,
          least((day + time '09:30' + random() * interval '10 hours') AT TIME ZONE public.clinic_timezone(),
            now() - interval '5 minutes'));
      END IF;
    END LOOP;
  END LOOP;

  -- Follow-up payments on older open invoices, a few days after the visit.
  FOR inv IN SELECT * FROM public.invoice_register WHERE due_minor > 0 AND invoice_date < current_date - 7
    ORDER BY invoice_date, number LOOP
    CONTINUE WHEN random() < 0.35;
    moment := least(inv.created_at + (2 + floor(random() * 6)) * interval '1 day', now() - interval '1 hour');
    result := pg_temp.cmd(desk, 'receipt_create', jsonb_build_object('id', inv.id, 'version', inv.version,
      'amount_minor', inv.due_minor, 'method', CASE WHEN random() < 0.6 THEN 'cash' ELSE 'visa' END,
      'branch', inv.branch));
    IF (result->>'ok')::boolean THEN PERFORM pg_temp.at(inv.id, moment); END IF;
  END LOOP;
  RAISE NOTICE 'Seeded % invoices', created;
END;
$$;
COMMIT;
-- Next: run supabase/seed_invoice_demo_events.sql for refunds, voids and corrections.
