-- Receipt and refund commands. Called only by execute_invoice_command.
-- A later active refund is a barrier: earlier money documents cannot be
-- voided until that refund is voided, so allocations always stay consistent.

CREATE FUNCTION public.invoice_record_receipt(p_invoice public.invoices, p_amount bigint, p_method text,
  p_branch public.clinic_location, p_received_at timestamptz, p_replaces uuid, p_actor uuid)
RETURNS uuid LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE due bigint; receipt_id uuid;
BEGIN
  IF p_invoice.voided_at IS NOT NULL THEN RAISE EXCEPTION 'invoice_voided' USING ERRCODE = 'P0001'; END IF;
  SELECT due_minor INTO due FROM public.invoice_figures(p_invoice.id);
  IF p_amount IS NULL OR p_amount <= 0 OR p_amount > due THEN
    RAISE EXCEPTION 'receipt_limit' USING ERRCODE = 'P0001';
  END IF;
  INSERT INTO public.invoice_receipts(invoice_id, branch, number, amount_minor, method, received_at,
    recorded_by, recorded_by_name, replaces_receipt_id)
  VALUES (p_invoice.id, p_branch, public.invoice_next_number(p_branch, 'receipt'), p_amount, p_method,
    coalesce(p_received_at, clock_timestamp()), p_actor, public.invoice_actor_name(p_actor), p_replaces)
  RETURNING id INTO receipt_id;
  PERFORM public.invoice_allocate_receipt(p_invoice.id, receipt_id, p_amount);
  RETURN receipt_id;
END;
$$;

CREATE FUNCTION public.invoice_void_receipt(p_invoice public.invoices, p_receipt_id uuid,
  p_reason text, p_actor uuid)
RETURNS public.invoice_receipts LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE receipt public.invoice_receipts;
BEGIN
  SELECT * INTO receipt FROM public.invoice_receipts
    WHERE id = p_receipt_id AND invoice_id = p_invoice.id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_request' USING ERRCODE = 'P0001'; END IF;
  IF receipt.voided_at IS NOT NULL THEN RAISE EXCEPTION 'already_voided' USING ERRCODE = 'P0001'; END IF;
  IF EXISTS (SELECT 1 FROM public.invoice_refunds WHERE invoice_id = p_invoice.id
    AND voided_at IS NULL AND recorded_at > receipt.recorded_at) THEN
    RAISE EXCEPTION 'refund_after' USING ERRCODE = 'P0001';
  END IF;
  UPDATE public.invoice_receipts SET voided_at = clock_timestamp(), voided_by = p_actor,
    voided_by_name = public.invoice_actor_name(p_actor), void_reason = btrim(p_reason)
  WHERE id = receipt.id RETURNING * INTO receipt;
  RETURN receipt;
END;
$$;

-- Payload: lines [{line_id, sessions, value_minor}], payback_minor (the amount
-- the screen showed), payback_method, branch, reason. The value is agreed
-- manually; the payback is derived so an invoice is never overpaid.
CREATE FUNCTION public.invoice_record_refund(p_invoice public.invoices, p_data jsonb, p_actor uuid)
RETURNS uuid LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE
  lines jsonb := p_data->'lines';
  figures record; valid integer; refund_value bigint; payback bigint; refund_id uuid;
  cancel_pt integer; cancel_tr integer;
  method text := nullif(p_data->>'payback_method', '');
  branch public.clinic_location := (p_data->>'branch')::public.clinic_location;
BEGIN
  IF p_invoice.voided_at IS NOT NULL THEN RAISE EXCEPTION 'invoice_voided' USING ERRCODE = 'P0001'; END IF;
  IF jsonb_typeof(lines) <> 'array' OR jsonb_array_length(lines) NOT BETWEEN 1 AND 50 OR branch IS NULL THEN
    RAISE EXCEPTION 'invalid_request' USING ERRCODE = 'P0001';
  END IF;
  SELECT count(DISTINCT f.line_id),
    coalesce(sum((l->>'value_minor')::bigint), 0),
    coalesce(sum((l->>'sessions')::integer) FILTER (WHERE f.service_type = 'pt_session'), 0),
    coalesce(sum((l->>'sessions')::integer) FILTER (WHERE f.service_type = 'traction_session'), 0)
  INTO valid, refund_value, cancel_pt, cancel_tr
  FROM jsonb_array_elements(lines) l
  JOIN public.invoice_line_figures(p_invoice.id) f ON f.line_id = (l->>'line_id')::uuid
  WHERE (l->>'value_minor')::bigint BETWEEN 0 AND f.value_minor
    AND (l->>'sessions')::integer BETWEEN 0 AND f.sessions_left
    AND ((l->>'value_minor')::bigint > 0 OR (l->>'sessions')::integer > 0);
  IF valid <> jsonb_array_length(lines) THEN RAISE EXCEPTION 'refund_limit' USING ERRCODE = 'P0001'; END IF;
  SELECT * INTO figures FROM public.invoice_figures(p_invoice.id);
  payback := greatest(figures.net_collected_minor - (figures.value_minor - refund_value), 0);
  IF payback IS DISTINCT FROM (p_data->>'payback_minor')::bigint THEN
    RAISE EXCEPTION 'stale' USING ERRCODE = 'P0001';
  END IF;
  IF (payback > 0) <> (method IS NOT NULL) THEN
    RAISE EXCEPTION 'invalid_request' USING ERRCODE = 'P0001';
  END IF;
  INSERT INTO public.invoice_refunds(invoice_id, branch, number, value_minor, payback_minor,
    payback_method, reason, recorded_by, recorded_by_name)
  VALUES (p_invoice.id, branch, public.invoice_next_number(branch, 'refund'), refund_value, payback,
    method, btrim(p_data->>'reason'), p_actor, public.invoice_actor_name(p_actor))
  RETURNING id INTO refund_id;
  INSERT INTO public.invoice_refund_lines(refund_id, line_id, sessions_cancelled, value_minor)
  SELECT refund_id, (l->>'line_id')::uuid, (l->>'sessions')::integer, (l->>'value_minor')::bigint
  FROM jsonb_array_elements(lines) l;
  PERFORM public.invoice_reallocate_refund(p_invoice.id, refund_id, payback);
  PERFORM public.invoice_adjust_sessions(p_invoice.patient_id, -cancel_pt, -cancel_tr);
  RETURN refund_id;
END;
$$;

-- Voiding a refund restores its value, its paid-back money and its sessions.
CREATE FUNCTION public.invoice_void_refund(p_invoice public.invoices, p_refund_id uuid,
  p_reason text, p_actor uuid)
RETURNS void LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE refund public.invoice_refunds; restore_pt integer; restore_tr integer;
BEGIN
  SELECT * INTO refund FROM public.invoice_refunds
    WHERE id = p_refund_id AND invoice_id = p_invoice.id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'invalid_request' USING ERRCODE = 'P0001'; END IF;
  IF refund.voided_at IS NOT NULL THEN RAISE EXCEPTION 'already_voided' USING ERRCODE = 'P0001'; END IF;
  IF EXISTS (SELECT 1 FROM public.invoice_refunds WHERE invoice_id = p_invoice.id
    AND voided_at IS NULL AND recorded_at > refund.recorded_at) THEN
    RAISE EXCEPTION 'refund_after' USING ERRCODE = 'P0001';
  END IF;
  SELECT coalesce(sum(rl.sessions_cancelled) FILTER (WHERE l.service_type = 'pt_session'), 0),
    coalesce(sum(rl.sessions_cancelled) FILTER (WHERE l.service_type = 'traction_session'), 0)
  INTO restore_pt, restore_tr
  FROM public.invoice_refund_lines rl JOIN public.invoice_lines l ON l.id = rl.line_id
  WHERE rl.refund_id = refund.id;
  UPDATE public.invoice_refunds SET voided_at = clock_timestamp(), voided_by = p_actor,
    voided_by_name = public.invoice_actor_name(p_actor), void_reason = btrim(p_reason)
  WHERE id = refund.id;
  PERFORM public.invoice_adjust_sessions(p_invoice.patient_id, restore_pt, restore_tr);
END;
$$;

REVOKE ALL ON FUNCTION
  public.invoice_record_receipt(public.invoices, bigint, text, public.clinic_location, timestamptz, uuid, uuid),
  public.invoice_void_receipt(public.invoices, uuid, text, uuid),
  public.invoice_record_refund(public.invoices, jsonb, uuid),
  public.invoice_void_refund(public.invoices, uuid, text, uuid) FROM PUBLIC, anon, authenticated;
