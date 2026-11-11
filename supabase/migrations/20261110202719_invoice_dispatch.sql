-- The only client write path for invoices. Every command is idempotent per
-- request ID through mutation_receipts, checks the caller's capability and,
-- for an existing invoice, its version.

CREATE FUNCTION public.invoice_command_capability(p_kind text) RETURNS text
LANGUAGE sql IMMUTABLE SET search_path = '' AS $$
  SELECT CASE
    WHEN p_kind IN ('invoice_create', 'receipt_create') THEN 'issue'
    WHEN p_kind IN ('service_save', 'invoice_void', 'invoice_correct', 'receipt_void',
      'receipt_correct', 'refund_create', 'refund_void') THEN 'manage'
  END;
$$;
REVOKE ALL ON FUNCTION public.invoice_command_capability(text) FROM PUBLIC, anon, authenticated;

CREATE FUNCTION public.execute_invoice_command(p_request_id uuid, p_kind text, p_payload jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  actor uuid := (SELECT id FROM public.staff WHERE user_id = auth.uid() AND is_active);
  capability text := public.invoice_command_capability(p_kind);
  previous public.mutation_receipts;
  invoice public.invoices;
  invoice_id uuid := (p_payload->>'id')::uuid;
  document_id uuid;
  kind_key text := 'invoice:' || p_kind;
  request_hash text := encode(sha256(convert_to(p_payload::text, 'UTF8')), 'hex');
  reason text := nullif(btrim(p_payload->>'reason'), '');
  payment jsonb;
  outcome jsonb;
  error_key text;
BEGIN
  IF p_request_id IS NULL OR p_payload IS NULL OR capability IS NULL THEN
    RAISE EXCEPTION 'Invalid invoice request' USING ERRCODE = '22023';
  END IF;
  IF actor IS NULL OR NOT public.invoice_can(capability) THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE = '42501';
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
    IF p_kind NOT IN ('service_save', 'invoice_create') THEN
      SELECT * INTO invoice FROM public.invoices WHERE id = invoice_id FOR UPDATE;
      IF NOT FOUND OR invoice.version IS DISTINCT FROM (p_payload->>'version')::integer THEN
        RAISE EXCEPTION 'stale' USING ERRCODE = 'P0001';
      END IF;
    END IF;
    IF p_kind IN ('invoice_void', 'invoice_correct', 'receipt_void', 'receipt_correct',
      'refund_create', 'refund_void') AND (reason IS NULL OR length(reason) > 500) THEN
      RAISE EXCEPTION 'reason_required' USING ERRCODE = 'P0001';
    END IF;
    CASE p_kind
      WHEN 'service_save' THEN document_id := public.invoice_save_service(p_payload, actor);
      WHEN 'invoice_create' THEN
        IF jsonb_array_length(coalesce(p_payload->'payments', '[]')) > 2 OR EXISTS (
          SELECT 1 FROM jsonb_array_elements(coalesce(p_payload->'payments', '[]')) p
          GROUP BY p->>'method' HAVING count(*) > 1) THEN
          RAISE EXCEPTION 'invalid_request' USING ERRCODE = 'P0001';
        END IF;
        invoice_id := public.invoice_create(p_payload, actor, public.invoice_can('manage'), NULL);
        FOR payment IN SELECT value FROM jsonb_array_elements(coalesce(p_payload->'payments', '[]')) LOOP
          SELECT * INTO invoice FROM public.invoices WHERE id = invoice_id;
          PERFORM public.invoice_record_receipt(invoice, (payment->>'amount_minor')::bigint,
            payment->>'method', invoice.branch, NULL, NULL, actor);
        END LOOP;
      WHEN 'receipt_create' THEN
        document_id := public.invoice_record_receipt(invoice, (p_payload->>'amount_minor')::bigint,
          p_payload->>'method', (p_payload->>'branch')::public.clinic_location, NULL, NULL, actor);
      WHEN 'receipt_correct' THEN document_id := public.invoice_correct_receipt(invoice, p_payload, actor);
      WHEN 'receipt_void' THEN
        PERFORM public.invoice_void_receipt(invoice, (p_payload->>'receipt_id')::uuid, reason, actor);
      WHEN 'refund_create' THEN document_id := public.invoice_record_refund(invoice, p_payload, actor);
      WHEN 'refund_void' THEN
        PERFORM public.invoice_void_refund(invoice, (p_payload->>'refund_id')::uuid, reason, actor);
      WHEN 'invoice_void' THEN PERFORM public.invoice_void(invoice, reason, actor);
      WHEN 'invoice_correct' THEN
        document_id := public.invoice_correct(invoice, p_payload, actor);
        invoice_id := document_id;
    END CASE;
    IF p_kind IN ('receipt_create', 'receipt_correct', 'receipt_void', 'refund_create', 'refund_void') THEN
      UPDATE public.invoices SET version = version + 1 WHERE id = invoice.id;
    END IF;
    outcome := jsonb_build_object('ok', true, 'invoice_id', invoice_id, 'document_id', document_id);
  EXCEPTION
    WHEN raise_exception THEN
      GET STACKED DIAGNOSTICS error_key = MESSAGE_TEXT;
      outcome := jsonb_build_object('ok', false, 'error', error_key);
    WHEN unique_violation THEN
      outcome := '{"ok":false,"error":"duplicate"}';
    WHEN data_exception OR integrity_constraint_violation OR no_data_found OR invalid_text_representation THEN
      outcome := '{"ok":false,"error":"invalid_request"}';
  END;
  INSERT INTO public.mutation_receipts(request_id, actor_id, kind, payload_hash, outcome)
    VALUES (p_request_id, actor, kind_key, request_hash, outcome);
  RETURN outcome;
END;
$$;

-- Tombstones an unresolved request under the same lock, so a late original
-- request can no longer commit once the screen allows a replacement.
CREATE FUNCTION public.resolve_invoice_command(p_request_id uuid, p_kind text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  actor uuid := (SELECT id FROM public.staff WHERE user_id = auth.uid() AND is_active);
  capability text := public.invoice_command_capability(p_kind);
  previous public.mutation_receipts;
  kind_key text := 'invoice:' || p_kind;
  cancelled constant jsonb := '{"ok":false,"error":"cancelled"}';
BEGIN
  IF p_request_id IS NULL OR capability IS NULL THEN
    RAISE EXCEPTION 'Invalid invoice request' USING ERRCODE = '22023';
  END IF;
  IF actor IS NULL OR NOT public.invoice_can(capability) THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE = '42501';
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

REVOKE ALL ON FUNCTION public.execute_invoice_command(uuid, text, jsonb),
  public.resolve_invoice_command(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.execute_invoice_command(uuid, text, jsonb),
  public.resolve_invoice_command(uuid, text) TO authenticated;
