-- Synchronize balances from old/new charged state, including edits and deletion.
CREATE OR REPLACE FUNCTION public.handle_package_deduction()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE old_pt integer:=0; old_tr integer:=0; new_pt integer:=0; new_tr integer:=0;
BEGIN
  IF TG_OP<>'INSERT' AND OLD.status='checked_in' AND OLD.use_package THEN
    old_pt := (OLD.type='normal_pt_session')::integer;
    old_tr := (OLD.type='spinal_traction_session')::integer;
  END IF;
  IF TG_OP<>'DELETE' AND NEW.status='checked_in' AND NEW.use_package THEN
    new_pt := (NEW.type='normal_pt_session')::integer;
    new_tr := (NEW.type='spinal_traction_session')::integer;
  END IF;
  IF TG_OP='UPDATE' AND OLD.patient_id=NEW.patient_id AND old_pt=new_pt AND old_tr=new_tr THEN
    RETURN NEW;
  END IF;
  IF old_pt+old_tr>0 THEN
    UPDATE public.patients SET session_balance=session_balance+old_pt,
      traction_balance=traction_balance+old_tr WHERE id=OLD.patient_id;
  END IF;
  IF new_pt+new_tr>0 THEN
    UPDATE public.patients SET session_balance=session_balance-new_pt,
      traction_balance=traction_balance-new_tr WHERE id=NEW.patient_id
      AND session_balance>=new_pt AND traction_balance>=new_tr;
    IF NOT FOUND THEN RAISE EXCEPTION 'Insufficient package balance' USING ERRCODE='22000'; END IF;
  END IF;
  RETURN coalesce(NEW,OLD);
END;
$$;
DROP TRIGGER IF EXISTS trigger_appointment_package_deduction ON public.appointments;
CREATE TRIGGER trigger_appointment_package_deduction AFTER INSERT OR UPDATE OR DELETE ON public.appointments
  FOR EACH ROW EXECUTE FUNCTION public.handle_package_deduction();

CREATE OR REPLACE FUNCTION public.handle_payment_package_sync()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
BEGIN
  IF TG_OP='UPDATE' AND OLD.patient_id=NEW.patient_id
      AND OLD.session_balance_added=NEW.session_balance_added
      AND OLD.traction_balance_added=NEW.traction_balance_added THEN RETURN NULL; END IF;
  IF TG_OP<>'INSERT' THEN
    UPDATE public.patients SET session_balance=session_balance-OLD.session_balance_added,
      traction_balance=traction_balance-OLD.traction_balance_added WHERE id=OLD.patient_id;
  END IF;
  IF TG_OP<>'DELETE' THEN
    UPDATE public.patients SET session_balance=session_balance+NEW.session_balance_added,
      traction_balance=traction_balance+NEW.traction_balance_added WHERE id=NEW.patient_id;
  END IF;
  RETURN NULL;
END;
$$;
CREATE TRIGGER trigger_payment_update_package_sync AFTER UPDATE ON public.payment_records
  FOR EACH ROW EXECUTE FUNCTION public.handle_payment_package_sync();

-- NOT VALID preserves historical rows for an explicit audit; new writes are checked.
ALTER TABLE public.payment_records ADD CONSTRAINT payment_amount_valid
  CHECK(amount>0 AND amount::text NOT IN ('NaN','Infinity','-Infinity')) NOT VALID;
ALTER TABLE public.payment_records ADD CONSTRAINT payment_total_valid
  CHECK(total_price IS NULL OR (total_price>=amount AND total_price::text NOT IN ('NaN','Infinity','-Infinity'))) NOT VALID;
ALTER TABLE public.payment_records ADD CONSTRAINT payment_credits_valid
  CHECK(session_balance_added>=0 AND traction_balance_added>=0) NOT VALID;

CREATE OR REPLACE FUNCTION public.collect_payment_due(p_payment_id uuid,p_additional_amount numeric)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,pg_temp AS $$
DECLARE payment public.payment_records;
BEGIN
  IF NOT public.current_staff_can_manage_payments() THEN
    RAISE EXCEPTION 'Permission denied: cannot manage payments' USING ERRCODE='42501';
  END IF;
  IF p_additional_amount IS NULL OR p_additional_amount<=0
      OR p_additional_amount::text IN ('NaN','Infinity','-Infinity') THEN
    RAISE EXCEPTION 'Additional amount must be positive and finite' USING ERRCODE='22000';
  END IF;
  SELECT * INTO payment FROM public.payment_records WHERE id=p_payment_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Payment not found' USING ERRCODE='P0002'; END IF;
  IF payment.total_price IS NULL OR payment.amount+p_additional_amount>payment.total_price THEN
    RAISE EXCEPTION 'Collection exceeds outstanding due' USING ERRCODE='22000';
  END IF;
  UPDATE public.payment_records SET amount=amount+p_additional_amount WHERE id=p_payment_id;
END;
$$;
