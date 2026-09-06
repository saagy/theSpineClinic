BEGIN;
DO $$
DECLARE u uuid:=gen_random_uuid(); admin uuid:=gen_random_uuid(); d uuid:=gen_random_uuid();
  p uuid:=gen_random_uuid(); a uuid; pay uuid; n integer; b integer; name text;
BEGIN
  INSERT INTO auth.users(id,email) VALUES(u,u::text||'@example.test');
  INSERT INTO public.staff(id,user_id,full_name,email,role) VALUES(admin,u,'Review admin',u::text||'@example.test','super_admin');
  INSERT INTO public.staff(id,full_name,email,role) VALUES(d,'Review doctor',d::text||'@example.test','doctor');
  INSERT INTO public.patients(id,full_name,phone_number,clinic,session_balance)
    VALUES(p,'Original','000','tagamoa',2);
  INSERT INTO public.patient_doctors VALUES(p,d,now());
  PERFORM set_config('request.jwt.claim.sub',u::text,true);
  PERFORM public.book_recurring_appointments(p,'normal_pt_session',ARRAY[now()+interval '1 day'],false,admin,ARRAY[d]);
  SELECT count(*) INTO n FROM public.appointments WHERE patient_id=p AND use_package;
  IF n<>0 THEN RAISE EXCEPTION 'Cash booking incorrectly uses package'; END IF;
  PERFORM public.book_recurring_appointments(p,'normal_pt_session',ARRAY[now()+interval '2 days',now()+interval '3 days'],true,admin,ARRAY[d]);
  SELECT count(*) INTO n FROM public.appointments WHERE patient_id=p AND use_package;
  IF n<>2 THEN RAISE EXCEPTION 'Cash booking wrongly reserved a credit'; END IF;
  BEGIN
    PERFORM public.book_recurring_appointments(p,'normal_pt_session',ARRAY[now()+interval '4 days'],true,admin,ARRAY[d]);
    RAISE EXCEPTION 'Overbooked package accepted';
  EXCEPTION WHEN data_exception THEN NULL;
  END;
  SELECT count(*) INTO n FROM public.appointments WHERE patient_id=p;
  IF n<>3 THEN RAISE EXCEPTION 'Failed booking left partial appointments'; END IF;
  BEGIN
    PERFORM public.book_recurring_appointments(p,'initial_assessment',ARRAY[now()+interval '4 days'],true,admin,ARRAY[d],current_date-1);
    RAISE EXCEPTION 'Stale due booking accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM='Stale due booking accepted' THEN RAISE; END IF;
  END;
  PERFORM public.update_patient_details(p,'Changed','001',NULL,'tagamoa',NULL);
  SELECT session_balance INTO b FROM public.patients WHERE id=p;
  IF b<>2 THEN RAISE EXCEPTION 'Demographic edit changed credits'; END IF;
  BEGIN
    PERFORM public.update_patient_details(p,'Partial write','002',NULL,'tagamoa',ARRAY[admin]);
    RAISE EXCEPTION 'Invalid doctor accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='Invalid doctor accepted' THEN RAISE; END IF;
  END;
  SELECT full_name INTO name FROM public.patients WHERE id=p;
  IF name<>'Changed' THEN RAISE EXCEPTION 'Patient update did not roll back'; END IF;
  SELECT id INTO a FROM public.appointments WHERE patient_id=p ORDER BY scheduled_at LIMIT 1;
  BEGIN
    PERFORM public.update_appointment_details(a,now()+interval '99 days','reassessment',false,ARRAY[admin]);
    RAISE EXCEPTION 'Invalid appointment doctor accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='Invalid appointment doctor accepted' THEN RAISE; END IF;
  END;
  IF EXISTS(SELECT 1 FROM public.appointments WHERE id=a AND type='reassessment') THEN
    RAISE EXCEPTION 'Appointment update did not roll back';
  END IF;
  INSERT INTO public.payment_records(patient_id,amount,total_price,reason)
    VALUES(p,50,100,'Review due') RETURNING id INTO pay;
  PERFORM public.collect_payment_due(pay,50);
  BEGIN
    PERFORM public.collect_payment_due(pay,1);
    RAISE EXCEPTION 'Overcollection accepted';
  EXCEPTION WHEN data_exception THEN NULL;
  END;
  -- Ordinary assigned doctor may edit schedule while preserving the care team.
  INSERT INTO auth.users(id,email) VALUES(gen_random_uuid(),d::text||'-login@example.test') RETURNING id INTO u;
  UPDATE public.staff SET user_id=u WHERE id=d;
  PERFORM set_config('request.jwt.claim.sub',u::text,true);
  PERFORM public.update_appointment_details(a,now()+interval '5 days','initial_assessment',false,ARRAY[d]);
END;
$$;
ROLLBACK;
