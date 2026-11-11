-- Shared fixture for invoice SQL tests. It opens a transaction; run it
-- immediately before each invoice_*.sql test, which ends with ROLLBACK:
--   node test/review_database.mjs <pglite> test/invoice_fixture.sql test/invoice_workflow.sql
BEGIN;
INSERT INTO auth.users(id,email) VALUES
 ('a5000000-0000-0000-0000-000000000001','inv-admin@example.test'),
 ('a5000000-0000-0000-0000-000000000002','inv-cashier@example.test'),
 ('a5000000-0000-0000-0000-000000000003','inv-desk@example.test'),
 ('a5000000-0000-0000-0000-000000000004','inv-doctor-a@example.test'),
 ('a5000000-0000-0000-0000-000000000005','inv-doctor-b@example.test');
INSERT INTO public.staff(id,user_id,full_name,email,role,can_manage_payments) VALUES
 ('a6000000-0000-0000-0000-000000000001','a5000000-0000-0000-0000-000000000001','Admin','inv-admin@example.test','super_admin',false),
 ('a6000000-0000-0000-0000-000000000002','a5000000-0000-0000-0000-000000000002','Cashier','inv-cashier@example.test','receptionist',true),
 ('a6000000-0000-0000-0000-000000000003','a5000000-0000-0000-0000-000000000003','Desk','inv-desk@example.test','receptionist',false),
 ('a6000000-0000-0000-0000-000000000004','a5000000-0000-0000-0000-000000000004','Dr A','inv-doctor-a@example.test','doctor',false),
 ('a6000000-0000-0000-0000-000000000005','a5000000-0000-0000-0000-000000000005','Dr B','inv-doctor-b@example.test','doctor',false);
INSERT INTO public.patients(id,full_name,phone_number,clinic) VALUES
 ('a7000000-0000-0000-0000-000000000001','Invoice Patient','01000000101','tagamoa');

-- Runs a command as the given auth user with a fresh request ID.
CREATE FUNCTION pg_temp.run(p_user text, p_kind text, p_payload jsonb) RETURNS jsonb
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM set_config('request.jwt.claim.sub', p_user, true);
  RETURN public.execute_invoice_command(gen_random_uuid(), p_kind, p_payload);
END;
$$;

-- Runs a command and returns the created invoice or document ID, failing loudly.
CREATE FUNCTION pg_temp.ok(p_user text, p_kind text, p_payload jsonb, p_field text DEFAULT 'invoice_id')
RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE result jsonb := pg_temp.run(p_user, p_kind, p_payload);
BEGIN
  IF NOT (result->>'ok')::boolean THEN RAISE EXCEPTION '% failed: %', p_kind, result; END IF;
  RETURN (result->>p_field)::uuid;
END;
$$;

-- Asserts a command returns the expected error key.
CREATE FUNCTION pg_temp.fails(p_user text, p_kind text, p_payload jsonb, p_error text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE result jsonb := pg_temp.run(p_user, p_kind, p_payload);
BEGIN
  IF result->>'error' IS DISTINCT FROM p_error THEN
    RAISE EXCEPTION '% expected %, got %', p_kind, p_error, result;
  END IF;
END;
$$;

-- Asserts a command is refused before any receipt is written. The refused
-- call leaves the caller's auth claim unchanged.
CREATE FUNCTION pg_temp.denied(p_user text, p_kind text, p_payload jsonb) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_temp.run(p_user, p_kind, p_payload);
  RAISE EXCEPTION '% was not denied for %', p_kind, p_user;
EXCEPTION WHEN insufficient_privilege THEN NULL;
END;
$$;

CREATE FUNCTION pg_temp.version(p_invoice uuid) RETURNS integer LANGUAGE sql AS $$
  SELECT version FROM public.invoices WHERE id = p_invoice;
$$;

-- Asserts register figures: value, net collected, due and status.
CREATE FUNCTION pg_temp.expect(p_invoice uuid, p_value bigint, p_collected bigint, p_due bigint, p_status text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE r record;
BEGIN
  SELECT value_minor, net_collected_minor, due_minor, status INTO r
    FROM public.invoice_register WHERE id = p_invoice;
  IF r.value_minor IS DISTINCT FROM p_value OR r.net_collected_minor IS DISTINCT FROM p_collected OR r.due_minor IS DISTINCT FROM p_due
    OR r.status IS DISTINCT FROM p_status THEN
    RAISE EXCEPTION 'Invoice % expected %/%/%/% got %', p_invoice, p_value, p_collected, p_due, p_status, r;
  END IF;
  IF (SELECT coalesce(sum(collected_minor), 0) FROM public.invoice_line_figures(p_invoice)) IS DISTINCT FROM r.net_collected_minor
    OR EXISTS (SELECT 1 FROM public.invoice_line_figures(p_invoice)
      WHERE collected_minor < 0 OR collected_minor > value_minor OR value_minor < 0 OR sessions_left < 0) THEN
    RAISE EXCEPTION 'Line allocations do not reconcile for %', p_invoice;
  END IF;
END;
$$;

CREATE FUNCTION pg_temp.balance(OUT pt integer, OUT traction integer) LANGUAGE sql AS $$
  SELECT session_balance, traction_balance FROM public.patients
  WHERE id = 'a7000000-0000-0000-0000-000000000001';
$$;

-- Builds an invoice payload for the fixture patient.
CREATE FUNCTION pg_temp.bill(p_lines jsonb, p_payments jsonb DEFAULT '[]',
  p_discount jsonb DEFAULT '{"kind":"none","value":0}') RETURNS jsonb LANGUAGE sql AS $$
  SELECT jsonb_build_object('patient_id', 'a7000000-0000-0000-0000-000000000001', 'branch', 'tagamoa',
    'invoice_date', (now() AT TIME ZONE public.clinic_timezone())::date, 'lines', p_lines,
    'payments', p_payments, 'discount', p_discount);
$$;

CREATE FUNCTION pg_temp.line(p_service uuid, p_quantity integer, p_doctors text[] DEFAULT '{}')
RETURNS jsonb LANGUAGE sql AS $$
  SELECT jsonb_build_object('service_id', id, 'quantity', p_quantity, 'unit_price_minor', price_minor,
    'doctor_ids', to_jsonb(p_doctors)) FROM public.service_catalog WHERE id = p_service;
$$;
