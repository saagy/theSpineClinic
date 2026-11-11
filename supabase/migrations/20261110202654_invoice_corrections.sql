-- Corrections void a document and create a linked replacement in one
-- transaction. Money keeps its original received_at so daily cash totals stay
-- on the day the money was taken.

CREATE FUNCTION public.invoice_correct_receipt(p_invoice public.invoices, p_data jsonb, p_actor uuid)
RETURNS uuid LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE original public.invoice_receipts;
BEGIN
  original := public.invoice_void_receipt(p_invoice, (p_data->>'receipt_id')::uuid,
    p_data->>'reason', p_actor);
  RETURN public.invoice_record_receipt(p_invoice, (p_data->>'amount_minor')::bigint,
    p_data->>'method', (p_data->>'branch')::public.clinic_location, original.received_at,
    original.id, p_actor);
END;
$$;

-- Payload: reason and invoice (a complete invoice_create payload). Active
-- receipts move to the replacement; the new total must cover them. Invoices
-- with active refunds must have those refunds voided first.
CREATE FUNCTION public.invoice_correct(p_invoice public.invoices, p_data jsonb, p_actor uuid)
RETURNS uuid LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE
  replacement_id uuid; replacement public.invoices; moved public.invoice_receipts; paid bigint;
BEGIN
  IF p_invoice.voided_at IS NOT NULL THEN RAISE EXCEPTION 'already_voided' USING ERRCODE = 'P0001'; END IF;
  IF EXISTS (SELECT 1 FROM public.invoice_refunds WHERE invoice_id = p_invoice.id AND voided_at IS NULL) THEN
    RAISE EXCEPTION 'has_refunds' USING ERRCODE = 'P0001';
  END IF;
  -- Grant the replacement's sessions before removing the original's, so a
  -- price or doctor fix never fails because some sessions are already used.
  replacement_id := public.invoice_create(p_data->'invoice', p_actor, true, p_invoice.id);
  SELECT * INTO STRICT replacement FROM public.invoices WHERE id = replacement_id;
  SELECT coalesce(sum(amount_minor), 0) INTO paid FROM public.invoice_receipts
    WHERE invoice_id = p_invoice.id AND voided_at IS NULL;
  IF paid > replacement.total_minor THEN
    RAISE EXCEPTION 'correction_below_paid' USING ERRCODE = 'P0001';
  END IF;
  FOR moved IN SELECT * FROM public.invoice_receipts WHERE invoice_id = p_invoice.id
    AND voided_at IS NULL ORDER BY recorded_at, id FOR UPDATE LOOP
    PERFORM public.invoice_void_receipt(p_invoice, moved.id, p_data->>'reason', p_actor);
    PERFORM public.invoice_record_receipt(replacement, moved.amount_minor, moved.method, moved.branch,
      moved.received_at, moved.id, p_actor);
  END LOOP;
  PERFORM public.invoice_void(p_invoice, p_data->>'reason', p_actor);
  RETURN replacement_id;
END;
$$;

REVOKE ALL ON FUNCTION public.invoice_correct_receipt(public.invoices, jsonb, uuid),
  public.invoice_correct(public.invoices, jsonb, uuid) FROM PUBLIC, anon, authenticated;
