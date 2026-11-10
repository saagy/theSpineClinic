CREATE FUNCTION public.execute_billing_mutation(p_request_id uuid, p_kind text, p_payload jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  actor uuid := (SELECT id FROM public.staff WHERE user_id = auth.uid() AND is_active);
  previous public.mutation_receipts;
  invoice public.billing_invoices;
  invoice_id uuid := (p_payload->>'id')::uuid;
  document_id uuid;
  kind_key text := 'billing:' || p_kind;
  request_hash text := encode(sha256(convert_to(p_payload::text, 'UTF8')), 'hex');
  outcome jsonb;
  error_key text;
BEGIN
  IF actor IS NULL OR NOT public.billing_can(CASE WHEN p_kind = 'item' THEN 'catalog' ELSE 'transact' END) THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE = '42501';
  END IF;
  IF p_request_id IS NULL OR p_payload IS NULL OR p_kind IS NULL
    OR p_kind NOT IN ('item', 'draft', 'issue', 'receipt', 'return', 'refund') THEN
    RAISE EXCEPTION 'Invalid billing request' USING ERRCODE = '22023';
  END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended(p_request_id::text, 0));
  SELECT * INTO previous FROM public.mutation_receipts WHERE request_id = p_request_id;
  IF FOUND THEN
    IF previous.actor_id <> actor OR previous.kind <> kind_key OR previous.payload_hash <> request_hash THEN
      RAISE EXCEPTION 'Request identity mismatch' USING ERRCODE = '22023';
    END IF;
    RETURN previous.outcome;
  END IF;
  BEGIN
    IF p_kind <> 'item' AND (invoice_id IS NOT NULL OR p_kind <> 'draft') THEN
      SELECT * INTO invoice FROM public.billing_invoices WHERE id = invoice_id FOR UPDATE;
      IF NOT FOUND OR invoice.version IS DISTINCT FROM (p_payload->>'version')::integer THEN
        RAISE EXCEPTION 'stale' USING ERRCODE = 'P0001';
      END IF;
    END IF;
    CASE p_kind
      WHEN 'item' THEN document_id := public.billing_save_item(p_payload);
      WHEN 'draft' THEN invoice_id := public.billing_save_draft(p_payload, actor);
      WHEN 'issue' THEN PERFORM public.billing_issue(invoice, actor);
      ELSE document_id := public.billing_record_movement(invoice, p_kind, p_payload, actor);
    END CASE;
    outcome := jsonb_build_object('ok', true, 'invoice_id', invoice_id, 'document_id', document_id);
  EXCEPTION
    WHEN raise_exception THEN
      GET STACKED DIAGNOSTICS error_key = MESSAGE_TEXT;
      outcome := jsonb_build_object('ok', false, 'error', error_key);
    WHEN data_exception OR integrity_constraint_violation OR no_data_found THEN
      outcome := '{"ok":false,"error":"invalid_invoice"}';
  END;
  INSERT INTO public.mutation_receipts(request_id, actor_id, kind, payload_hash, outcome)
    VALUES (p_request_id, actor, kind_key, request_hash, outcome);
  RETURN outcome;
END;
$$;

-- Tombstone an unresolved request under the same lock. A late original
-- request can no longer commit once a replacement has been allowed.
CREATE FUNCTION public.resolve_billing_mutation(p_request_id uuid, p_kind text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  actor uuid := (SELECT id FROM public.staff WHERE user_id = auth.uid() AND is_active);
  previous public.mutation_receipts;
  kind_key text := 'billing:' || p_kind;
  cancelled constant jsonb := '{"ok":false,"error":"cancelled"}';
BEGIN
  IF actor IS NULL OR NOT public.billing_can(CASE WHEN p_kind = 'item' THEN 'catalog' ELSE 'transact' END) THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE = '42501';
  END IF;
  IF p_request_id IS NULL OR p_kind IS NULL OR p_kind NOT IN ('item','draft','issue','receipt','return','refund') THEN
    RAISE EXCEPTION 'Invalid billing request' USING ERRCODE = '22023';
  END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended(p_request_id::text, 0));
  SELECT * INTO previous FROM public.mutation_receipts WHERE request_id = p_request_id;
  IF FOUND THEN
    IF previous.actor_id <> actor OR previous.kind <> kind_key THEN
      RAISE EXCEPTION 'Permission denied' USING ERRCODE = '42501';
    END IF;
    RETURN previous.outcome;
  END IF;
  INSERT INTO public.mutation_receipts(request_id, actor_id, kind, payload_hash, outcome)
    VALUES (p_request_id, actor, kind_key, '', cancelled);
  RETURN cancelled;
END;
$$;

REVOKE ALL ON FUNCTION public.execute_billing_mutation(uuid,text,jsonb),
  public.resolve_billing_mutation(uuid,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.execute_billing_mutation(uuid,text,jsonb),
  public.resolve_billing_mutation(uuid,text) TO authenticated;

