-- Run against an isolated database containing the full clinic schema.
BEGIN;
INSERT INTO auth.users(id,email) VALUES
 ('95000000-0000-0000-0000-000000000001','billing-admin@example.test'),
 ('95000000-0000-0000-0000-000000000002','billing-doctor@example.test'),
 ('95000000-0000-0000-0000-000000000003','billing-cashier@example.test'),
 ('95000000-0000-0000-0000-000000000004','billing-frontdesk@example.test'),
 ('95000000-0000-0000-0000-000000000005','billing-senior@example.test');
INSERT INTO public.staff(id,user_id,full_name,email,role,can_manage_payments) VALUES
 ('96000000-0000-0000-0000-000000000001','95000000-0000-0000-0000-000000000001','Test admin','billing-admin@example.test','super_admin',false),
 ('96000000-0000-0000-0000-000000000002','95000000-0000-0000-0000-000000000002','Test doctor','billing-doctor@example.test','doctor',false),
 ('96000000-0000-0000-0000-000000000003','95000000-0000-0000-0000-000000000003','Test cashier','billing-cashier@example.test','receptionist',true),
 ('96000000-0000-0000-0000-000000000004','95000000-0000-0000-0000-000000000004','Test front desk','billing-frontdesk@example.test','receptionist',false);
INSERT INTO public.staff(id,user_id,full_name,email,role,is_senior) VALUES
 ('96000000-0000-0000-0000-000000000005','95000000-0000-0000-0000-000000000005','Test senior','billing-senior@example.test','doctor',true);
INSERT INTO public.patients(id,full_name,phone_number,clinic)
VALUES ('97000000-0000-0000-0000-000000000001','Alexander Montgomery','01000000000','tagamoa');

SET LOCAL ROLE authenticated;
DO $$
DECLARE
  p constant uuid := '97000000-0000-0000-0000-000000000001';
  d constant uuid := '96000000-0000-0000-0000-000000000002';
  senior constant uuid := '96000000-0000-0000-0000-000000000005';
  admin constant text := '95000000-0000-0000-0000-000000000001';
  cashier constant text := '95000000-0000-0000-0000-000000000003';
  desk constant text := '95000000-0000-0000-0000-000000000004';
  auth_key constant text := 'request.jwt.claim.sub';
  service uuid; invoice uuid; line uuid; req uuid; doc uuid;
  payload jsonb; result jsonb; detail jsonb; draft jsonb;
  profile public.patients;
BEGIN
  PERFORM set_config(auth_key, admin, true);
  result := public.execute_billing_mutation(gen_random_uuid(), 'item',
    '{"name":"Clinic service","price_minor":50000,"active":true}');
  service := (result->>'document_id')::uuid;
  IF service IS NULL THEN RAISE EXCEPTION 'Service not saved: %', result; END IF;
  PERFORM set_config(auth_key, cashier, true);
  profile := public.create_patient_profile('New test patient','01000000002','tagamoa',
    '96000000-0000-0000-0000-000000000003',ARRAY[d],
    '{"nationality":"Egyptian","gender":"female","date_of_birth":"2000-01-02","insurance_member_number":"0004"}');
  IF profile.file_number IS NULL OR profile.personal_details->>'insurance_member_number' IS DISTINCT FROM '0004'
    OR NOT EXISTS (SELECT 1 FROM public.patient_doctors WHERE patient_id = profile.id AND doctor_id = d) THEN
    RAISE EXCEPTION 'Profile and doctor assignment were not saved';
  END IF;
  PERFORM public.update_patient_profile(profile.id,'New test patient','01000000002','tagamoa',
    NULL,'{"secondary_phone":"010-234-56789","nationality":null}');
  IF NOT EXISTS (SELECT 1 FROM public.patients WHERE id = profile.id
    AND personal_details = '{"secondary_phone":"010-234-56789"}') THEN
    RAISE EXCEPTION 'Nullable details were not updated';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.billing_lookup_page('patient','ID ' || profile.file_number,0,26)
      WHERE id = profile.id)
    OR NOT EXISTS (SELECT 1 FROM public.billing_lookup_page('patient','23456789',0,26) WHERE id = profile.id)
    OR (SELECT count(*) FROM public.billing_lookup_page('doctor','Test',1,1)) <> 1
    OR (SELECT id FROM public.billing_lookup_page('senior','Test',0,26)) IS DISTINCT FROM senior THEN
    RAISE EXCEPTION 'Directory search or pagination failed';
  END IF;
  BEGIN
    PERFORM public.execute_billing_mutation(gen_random_uuid(), 'item',
      '{"name":"Denied","price_minor":1,"active":true}');
    RAISE EXCEPTION 'Cashier changed catalog';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  draft := jsonb_build_object('patient_id',p,'doctor_id',d,'branch','tagamoa',
    'service_date','2026-11-10','discount_bps',0,'lines',jsonb_build_array(
      jsonb_build_object('item_id',service,'item_name','Clinic service','quantity',2,'price_minor',50000)));
  IF public.execute_billing_mutation(gen_random_uuid(), 'draft',
    draft || jsonb_build_object('consultant_id',d))->>'error' IS DISTINCT FROM 'inactive_senior' THEN
    RAISE EXCEPTION 'Non-senior selected as examining doctor';
  END IF;
  draft := draft || jsonb_build_object('consultant_id',senior);
  result := public.execute_billing_mutation(gen_random_uuid(), 'draft', draft);
  invoice := (result->>'invoice_id')::uuid;
  IF invoice IS NULL THEN RAISE EXCEPTION 'Draft not saved: %', result; END IF;
  IF public.execute_billing_mutation(gen_random_uuid(), 'draft', draft ||
    jsonb_build_object('id',invoice,'version',0))->>'error' <> 'stale' THEN
    RAISE EXCEPTION 'Conflicting edit accepted';
  END IF;
  UPDATE public.billing_invoices SET total_minor = 1 WHERE id = invoice;
  IF FOUND THEN RAISE EXCEPTION 'Direct write allowed'; END IF;
  PERFORM set_config(auth_key, desk, true);
  IF EXISTS (SELECT 1 FROM public.billing_lookup_page('patient','',0,26)) THEN
    RAISE EXCEPTION 'Nonpayment receptionist read the billing directory';
  END IF;
  IF EXISTS (SELECT 1 FROM public.billing_register WHERE id = invoice) THEN
    RAISE EXCEPTION 'Nonpayment receptionist read invoices';
  END IF;
  BEGIN
    PERFORM public.execute_billing_mutation(gen_random_uuid(), 'issue', jsonb_build_object('id',invoice,'version',1));
    RAISE EXCEPTION 'Nonpayment receptionist issued invoice';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  PERFORM set_config(auth_key, cashier, true);
  result := public.execute_billing_mutation(gen_random_uuid(), 'issue', jsonb_build_object('id',invoice,'version',1));
  IF result->>'ok' <> 'true' THEN RAISE EXCEPTION 'Invoice did not issue: %', result; END IF;
  IF public.execute_billing_mutation(gen_random_uuid(), 'draft', draft ||
    jsonb_build_object('id',invoice,'version',2))->>'error' <> 'stale' THEN
    RAISE EXCEPTION 'Issued invoice changed';
  END IF;
  req := gen_random_uuid();
  payload := jsonb_build_object('id',invoice,'version',2,'amount_minor',60000,'method','cash');
  result := public.execute_billing_mutation(req, 'receipt', payload);
  doc := (result->>'document_id')::uuid;
  IF doc IS NULL OR result <> public.execute_billing_mutation(req, 'receipt', payload)
      OR result <> public.resolve_billing_mutation(req, 'receipt') THEN
    RAISE EXCEPTION 'Receipt retry did not recover same document: %', result;
  END IF;
  IF (SELECT count(*) FROM public.billing_movements WHERE invoice_id=invoice) <> 1
      OR (SELECT sum(amount_minor) FROM public.billing_allocations WHERE movement_id=doc) <> 60000 THEN
    RAISE EXCEPTION 'Receipt duplicated or allocation does not reconcile';
  END IF;
  IF public.execute_billing_mutation(gen_random_uuid(), 'receipt', payload)->>'error' <> 'stale' THEN
    RAISE EXCEPTION 'Second cashier accepted stale balance';
  END IF;
  IF public.execute_billing_mutation(gen_random_uuid(), 'receipt', payload ||
    '{"version":3,"amount_minor":40001}')->>'error' <> 'receipt_limit' THEN
    RAISE EXCEPTION 'Overpayment accepted';
  END IF;
  SELECT id INTO line FROM public.billing_invoice_lines WHERE invoice_id=invoice;
  result := public.execute_billing_mutation(gen_random_uuid(), 'return', jsonb_build_object(
    'id',invoice,'version',3,'reason','Return fixture','lines',
    jsonb_build_array(jsonb_build_object('line_id',line,'quantity',1))));
  IF result->>'ok' <> 'true' THEN RAISE EXCEPTION 'Return failed: %', result; END IF;
  detail := public.billing_invoice_detail(invoice);
  IF detail->>'outstanding_minor' <> '0' OR detail->>'refundable_minor' <> '10000'
      OR detail->'movements'->1->>'debt_reduced_minor' <> '40000' THEN
    RAISE EXCEPTION 'Debt-first return did not reconcile';
  END IF;
  payload := jsonb_build_object('id',invoice,'version',4,'amount_minor',10001,'method','cash','reason','Refund fixture');
  IF public.execute_billing_mutation(gen_random_uuid(), 'refund', payload)->>'error' <> 'refund_limit' THEN
    RAISE EXCEPTION 'Excess refund accepted';
  END IF;
  result := public.execute_billing_mutation(gen_random_uuid(), 'refund', payload || '{"amount_minor":10000}');
  IF result->>'ok' <> 'true' THEN RAISE EXCEPTION 'Refund failed: %', result; END IF;
  req := gen_random_uuid();
  PERFORM public.resolve_billing_mutation(req, 'refund');
  BEGIN
    PERFORM public.execute_billing_mutation(req, 'refund', payload);
    RAISE EXCEPTION 'Cancelled request accepted';
  EXCEPTION WHEN invalid_parameter_value THEN NULL;
  END;
  PERFORM set_config(auth_key, admin, true);
  PERFORM public.execute_billing_mutation(gen_random_uuid(), 'item',
    jsonb_build_object('id',service,'version',1,'name','New price','price_minor',100000,'active',true));
  UPDATE public.patients SET full_name='Renamed fixture', clinic='masr_elgedida' WHERE id=p;
  UPDATE public.staff SET full_name='Renamed doctor' WHERE id=d;
  detail := public.billing_invoice_detail(invoice);
  IF detail->>'patient_name' <> 'Alexander Montgomery' OR detail->>'doctor_name' <> 'Test doctor'
    OR detail->>'branch' <> 'tagamoa' OR detail->'lines'->0->>'price_minor' <> '50000' THEN
    RAISE EXCEPTION 'Historical snapshot changed';
  END IF;
  IF jsonb_array_length(public.billing_export('Alexander','tagamoa',NULL,NULL,NULL,true)) <> 2 THEN
    RAISE EXCEPTION 'Collection register does not reconcile';
  END IF;
END;
$$;
ROLLBACK;

