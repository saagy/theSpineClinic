CREATE FUNCTION public.billing_record_movement(p_invoice public.billing_invoices, p_kind text, p_data jsonb, p_actor uuid)
RETURNS uuid LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE
  paid bigint; credited bigint; refunded bigint; debt bigint;
  amount bigint := (p_data->>'amount_minor')::bigint;
  method text := p_data->>'method';
  reason text := nullif(btrim(p_data->>'reason'), '');
  doc_id uuid;
  expected_lines integer;
  valid_lines integer;
  portions jsonb;
BEGIN
  IF p_invoice.number IS NULL THEN RAISE EXCEPTION 'invalid_invoice' USING ERRCODE = '22023'; END IF;
  SELECT coalesce(sum(amount_minor) FILTER (WHERE kind = 'receipt'), 0),
    coalesce(sum(amount_minor) FILTER (WHERE kind = 'return'), 0),
    coalesce(sum(amount_minor) FILTER (WHERE kind = 'refund'), 0)
  INTO paid, credited, refunded FROM public.billing_movements WHERE invoice_id = p_invoice.id;
  debt := greatest(p_invoice.total_minor - credited - paid + refunded, 0);
  IF p_kind = 'receipt' AND (amount IS NULL OR amount <= 0 OR amount > debt) THEN
    RAISE EXCEPTION 'receipt_limit' USING ERRCODE = 'P0001';
  ELSIF p_kind = 'refund' AND (amount IS NULL OR amount <= 0
    OR amount > paid - refunded - (p_invoice.total_minor - credited)) THEN
    RAISE EXCEPTION 'refund_limit' USING ERRCODE = 'P0001';
  ELSIF p_kind = 'return' THEN
    method := NULL;
    expected_lines := jsonb_array_length(p_data->'lines');
    WITH requested AS (
      SELECT line_id, sum(quantity)::integer AS quantity
      FROM jsonb_to_recordset(p_data->'lines') AS input(line_id uuid, quantity integer)
      GROUP BY line_id
    ), returned AS (
      SELECT a.line_id, sum(a.quantity)::integer AS quantity
      FROM public.billing_allocations a JOIN public.billing_movements m ON m.id = a.movement_id
      WHERE m.invoice_id = p_invoice.id AND m.kind = 'return' GROUP BY a.line_id
    ), eligible AS (
      SELECT line.id, input.quantity,
        div(line.net_minor::numeric * (coalesce(r.quantity, 0) + input.quantity), line.quantity)
        - div(line.net_minor::numeric * coalesce(r.quantity, 0), line.quantity) AS portion
      FROM requested input JOIN public.billing_invoice_lines line ON line.id = input.line_id
      LEFT JOIN returned r ON r.line_id = line.id
      WHERE line.invoice_id = p_invoice.id AND input.quantity > 0
        AND coalesce(r.quantity, 0) + input.quantity <= line.quantity
    )
    SELECT count(*), coalesce(sum(portion), 0),
      jsonb_agg(jsonb_build_object('line_id', id, 'quantity', quantity, 'amount_minor', portion))
    INTO valid_lines, amount, portions FROM eligible;
    IF expected_lines IS NULL OR expected_lines = 0 OR valid_lines <> expected_lines THEN
      RAISE EXCEPTION 'return_limit' USING ERRCODE = 'P0001';
    END IF;
  END IF;
  INSERT INTO public.billing_movements(invoice_id, branch, kind, number, amount_minor, method,
    reason, recorded_by, actor_name, debt_reduced_minor)
  VALUES (p_invoice.id, p_invoice.branch, p_kind, public.billing_next_number(p_invoice.branch, p_kind),
    amount, method, reason, p_actor, (SELECT full_name FROM public.staff WHERE id = p_actor),
    CASE WHEN p_kind = 'return' THEN least(debt, amount) ELSE 0 END)
  RETURNING id INTO doc_id;
  IF p_kind = 'return' THEN
    INSERT INTO public.billing_allocations(movement_id, line_id, amount_minor, quantity)
    SELECT doc_id, line_id, amount_minor, quantity
    FROM jsonb_to_recordset(portions) AS part(line_id uuid, amount_minor bigint, quantity integer);
  ELSIF p_kind = 'receipt' THEN
    WITH capacity AS (
      SELECT line.id, line.position, greatest(line.net_minor - coalesce(sum(a.amount_minor), 0), 0) AS open
      FROM public.billing_invoice_lines line
      LEFT JOIN public.billing_allocations a ON a.line_id = line.id
      WHERE line.invoice_id = p_invoice.id GROUP BY line.id
    ), weight AS (
      SELECT *, sum(open) OVER (ORDER BY position) AS cumulative, sum(open) OVER () AS total
      FROM capacity WHERE open > 0
    )
    INSERT INTO public.billing_allocations(movement_id, line_id, amount_minor)
    SELECT doc_id, id, div(amount::numeric * cumulative, total)
      - div(amount::numeric * (cumulative - open), total) FROM weight;
  END IF;
  UPDATE public.billing_invoices SET version = version + 1 WHERE id = p_invoice.id;
  RETURN doc_id;
END;
$$;

REVOKE ALL ON FUNCTION public.billing_record_movement(public.billing_invoices,text,jsonb,uuid)
  FROM PUBLIC, anon, authenticated;

