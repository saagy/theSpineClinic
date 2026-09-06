BEGIN;
DO $$
DECLARE
  p uuid := gen_random_uuid(); d uuid := gen_random_uuid();
  a uuid; payment uuid; b integer;
BEGIN
  INSERT INTO public.staff(id, full_name, email, role) VALUES(d, 'Review doctor', d::text || '@example.test', 'doctor');
  INSERT INTO public.patients(id, full_name, phone_number, clinic, session_balance, traction_balance)
    VALUES(p, 'Review patient', '000', 'tagamoa', 10, 5);
  INSERT INTO public.patient_doctors VALUES(p,d,now());
  INSERT INTO public.appointments(patient_id, type, use_package) VALUES(p,'normal_pt_session',true) RETURNING id INTO a;
  UPDATE public.appointments SET status='checked_in' WHERE id=a;
  UPDATE public.appointments SET type='spinal_traction_session' WHERE id=a;
  SELECT session_balance INTO b FROM public.patients WHERE id=p;
  IF b <> 10 THEN RAISE EXCEPTION 'Changing checked-in session type fails to refund old bucket: %', b; END IF;
  SELECT traction_balance INTO b FROM public.patients WHERE id=p;
  IF b <> 4 THEN RAISE EXCEPTION 'Changing checked-in session type fails to charge new bucket'; END IF;
  DELETE FROM public.appointments WHERE id=a;
  SELECT traction_balance INTO b FROM public.patients WHERE id=p;
  IF b <> 5 THEN RAISE EXCEPTION 'Deleting checked-in appointment fails to refund'; END IF;
  INSERT INTO public.appointments(patient_id,type,status,use_package)
    VALUES(p,'normal_pt_session','checked_in',true) RETURNING id INTO a;
  SELECT session_balance INTO b FROM public.patients WHERE id=p;
  IF b <> 9 THEN RAISE EXCEPTION 'Inserting checked-in appointment fails to charge'; END IF;
  UPDATE public.appointments SET use_package=false WHERE id=a;
  SELECT session_balance INTO b FROM public.patients WHERE id=p;
  IF b <> 10 THEN RAISE EXCEPTION 'Turning package off fails to refund'; END IF;
  UPDATE public.appointments SET status='cancelled' WHERE id=a;
  UPDATE public.appointments SET status='checked_in', use_package=true WHERE id=a;
  SELECT session_balance INTO b FROM public.patients WHERE id=p;
  IF b <> 9 THEN RAISE EXCEPTION 'Cancelled to checked-in fails to charge'; END IF;
  INSERT INTO public.payment_records(patient_id,amount,reason,session_balance_added)
    VALUES(p,100,'Review',2) RETURNING id INTO payment;
  UPDATE public.payment_records SET session_balance_added=4 WHERE id=payment;
  SELECT session_balance INTO b FROM public.patients WHERE id=p;
  IF b <> 13 THEN RAISE EXCEPTION 'Editing payment credits fails to apply delta: %',b; END IF;
  BEGIN
    INSERT INTO public.payment_records(patient_id,amount,reason) VALUES(p,-100,'Invalid');
    RAISE EXCEPTION 'Negative payment accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO public.payment_records(patient_id,amount,reason) VALUES(p,'NaN','Invalid');
    RAISE EXCEPTION 'NaN payment accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO public.payment_records(patient_id,amount,total_price,reason) VALUES(p,200,100,'Invalid');
    RAISE EXCEPTION 'Overpaid partial payment accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
END;
$$;
ROLLBACK;
