-- Disposable database only. Prove line-level rounding, split collection, and repeated returns.
BEGIN;
INSERT INTO auth.users(id,email) VALUES
  ('95100000-0000-0000-0000-000000000001','billing-rounding-admin@example.test'),
  ('95100000-0000-0000-0000-000000000002','billing-rounding-doctor@example.test');
INSERT INTO public.staff(id,user_id,full_name,email,role) VALUES
  ('96100000-0000-0000-0000-000000000001','95100000-0000-0000-0000-000000000001',
    'Test admin','billing-rounding-admin@example.test','super_admin'),
  ('96100000-0000-0000-0000-000000000002','95100000-0000-0000-0000-000000000002',
    'Test doctor','billing-rounding-doctor@example.test','doctor');
INSERT INTO public.patients(id,full_name,phone_number,clinic)
VALUES ('97100000-0000-0000-0000-000000000001','Test patient','000','masr_elgedida');

SET LOCAL ROLE authenticated;
DO $$
DECLARE
  p constant uuid := '97100000-0000-0000-0000-000000000001';
  a uuid; b uuid; invoice uuid; line uuid; receipt uuid;
  result jsonb; expected bigint; latest bigint;
BEGIN
  PERFORM set_config('request.jwt.claim.sub','95100000-0000-0000-0000-000000000001',true);
  a := (public.execute_billing_mutation(gen_random_uuid(), 'item',
    '{"name":"Service A","price_minor":101,"active":true}')->>'document_id')::uuid;
  b := (public.execute_billing_mutation(gen_random_uuid(), 'item',
    '{"name":"Service B","price_minor":97,"active":true}')->>'document_id')::uuid;
  result := public.execute_billing_mutation(gen_random_uuid(), 'draft', jsonb_build_object(
    'patient_id',p,'doctor_id','96100000-0000-0000-0000-000000000002',
    'branch','masr_elgedida','service_date','2026-11-10','discount_bps',1250,
    'lines',jsonb_build_array(
      jsonb_build_object('item_id',a,'item_name','Service A','quantity',3,'price_minor',101),
      jsonb_build_object('item_id',b,'item_name','Service B','quantity',2,'price_minor',97))));
  invoice := (result->>'invoice_id')::uuid;
  IF (SELECT total_minor FROM public.billing_register WHERE id=invoice) IS DISTINCT FROM 435
      OR (SELECT sum(net_minor) FROM public.billing_invoice_lines WHERE invoice_id=invoice) IS DISTINCT FROM 435 THEN
    RAISE EXCEPTION 'Invoice or line-level discount rounding was incorrect: %', result;
  END IF;
  IF NOT public.billing_patient_has_invoices(p) THEN RAISE EXCEPTION 'Deletion preflight missed invoice'; END IF;
  BEGIN
    PERFORM public.delete_empty_patient(p);
    RAISE EXCEPTION 'Billed patient was deleted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  PERFORM public.execute_billing_mutation(gen_random_uuid(), 'issue', jsonb_build_object('id',invoice,'version',1));
  FOR version IN 2..3 LOOP
    result := public.execute_billing_mutation(gen_random_uuid(), 'receipt', jsonb_build_object(
      'id',invoice,'version',version,'amount_minor',125,'method',CASE version WHEN 2 THEN 'cash' ELSE 'visa' END));
    receipt := (result->>'document_id')::uuid;
    IF (SELECT sum(amount_minor) FROM public.billing_allocations WHERE movement_id=receipt) IS DISTINCT FROM 125 THEN
      RAISE EXCEPTION 'Installment did not allocate exactly: %', result;
    END IF;
  END LOOP;
  SELECT id, net_minor INTO line, expected FROM public.billing_invoice_lines WHERE invoice_id=invoice AND item_id=a;
  FOR version IN 4..6 LOOP
    result := public.execute_billing_mutation(gen_random_uuid(), 'return', jsonb_build_object(
      'id',invoice,'version',version,'reason','Test return','lines',
      jsonb_build_array(jsonb_build_object('line_id',line,'quantity',1))));
    IF result->>'ok' <> 'true' THEN RAISE EXCEPTION 'Partial return failed: %', result; END IF;
  END LOOP;
  SELECT credited_minor INTO latest FROM public.billing_register WHERE id=invoice;
  IF latest IS DISTINCT FROM expected THEN RAISE EXCEPTION 'Returned amounts lost a minor unit'; END IF;
  result := public.execute_billing_mutation(gen_random_uuid(), 'return', jsonb_build_object(
    'id',invoice,'version',7,'reason','Test return','lines',
    jsonb_build_array(jsonb_build_object('line_id',line,'quantity',1))));
  IF result->>'error' <> 'return_limit' THEN RAISE EXCEPTION 'Return exceeded sold quantity'; END IF;
END;
$$;
ROLLBACK;

