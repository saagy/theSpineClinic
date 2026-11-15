-- Past days stay as they were reported. Money is always dated by the server
-- when it is taken, and cancelling or correcting it already needs payment
-- staff and a reason. The one remaining way to put something on a past day
-- was an invoice date, which any receptionist could set. From now on only
-- payment staff (head receptionists and super admins) may date an invoice
-- before today; corrections, which keep the original date, already need
-- them. Seeds and maintenance scripts (no signed-in user) are unaffected.
CREATE FUNCTION public.guard_invoice_backdate() RETURNS trigger
LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
  IF auth.uid() IS NOT NULL
      AND NEW.invoice_date < (now() AT TIME ZONE public.clinic_timezone())::date
      AND NOT public.invoice_can('manage') THEN
    RAISE EXCEPTION 'backdate_not_allowed' USING ERRCODE = 'P0001';
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER tr_guard_invoice_backdate BEFORE INSERT ON public.invoices
  FOR EACH ROW EXECUTE FUNCTION public.guard_invoice_backdate();
