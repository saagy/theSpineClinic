-- Service catalog and invoice commands. Called only by execute_invoice_command.

CREATE FUNCTION public.invoice_save_service(p_data jsonb, p_actor uuid)
RETURNS uuid LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE service_id uuid := (p_data->>'id')::uuid; saved uuid;
BEGIN
  IF service_id IS NULL THEN
    INSERT INTO public.service_catalog(name, service_type, sessions_per_unit, price_minor,
      attributes_doctors, active, updated_by)
    VALUES (btrim(p_data->>'name'), p_data->>'service_type', (p_data->>'sessions_per_unit')::integer,
      (p_data->>'price_minor')::bigint, (p_data->>'attributes_doctors')::boolean,
      (p_data->>'active')::boolean, p_actor)
    RETURNING id INTO saved;
  ELSE
    UPDATE public.service_catalog SET name = btrim(p_data->>'name'),
      service_type = p_data->>'service_type', sessions_per_unit = (p_data->>'sessions_per_unit')::integer,
      price_minor = (p_data->>'price_minor')::bigint,
      attributes_doctors = (p_data->>'attributes_doctors')::boolean,
      active = (p_data->>'active')::boolean, version = version + 1,
      updated_at = clock_timestamp(), updated_by = p_actor
    WHERE id = service_id AND version = (p_data->>'version')::integer
    RETURNING id INTO saved;
    IF NOT FOUND THEN RAISE EXCEPTION 'stale' USING ERRCODE = 'P0001'; END IF;
  END IF;
  RETURN saved;
END;
$$;

-- Creates an invoice, its lines and doctors, and grants its sessions.
-- p_manage allows discounts. p_replaces links a correction to its original.
CREATE FUNCTION public.invoice_create(p_data jsonb, p_actor uuid, p_manage boolean, p_replaces uuid)
RETURNS uuid LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE
  person public.patients;
  branch public.clinic_location := (p_data->>'branch')::public.clinic_location;
  bill_date date := (p_data->>'invoice_date')::date;
  lines jsonb := p_data->'lines';
  kind text := coalesce(p_data#>>'{discount,kind}', 'none');
  amount bigint := coalesce((p_data#>>'{discount,value}')::bigint, 0);
  matched integer; subtotal bigint; discount bigint; inv_id uuid; grant_pt integer; grant_tr integer;
BEGIN
  SELECT * INTO STRICT person FROM public.patients WHERE id = (p_data->>'patient_id')::uuid;
  IF branch IS NULL OR bill_date IS NULL OR bill_date > (now() AT TIME ZONE public.clinic_timezone())::date
    OR jsonb_typeof(lines) <> 'array' OR jsonb_array_length(lines) NOT BETWEEN 1 AND 50 THEN
    RAISE EXCEPTION 'invalid_invoice' USING ERRCODE = 'P0001';
  END IF;
  IF kind <> 'none' AND NOT p_manage THEN
    RAISE EXCEPTION 'discount_not_allowed' USING ERRCODE = 'P0001';
  END IF;
  -- Hold catalog rows while the quoted prices are compared and snapshotted.
  PERFORM s.id FROM public.service_catalog s
    WHERE s.id IN (SELECT (l->>'service_id')::uuid FROM jsonb_array_elements(lines) l)
    ORDER BY s.id FOR SHARE;
  SELECT count(*), sum(s.price_minor * (l->>'quantity')::integer) INTO matched, subtotal
  FROM jsonb_array_elements(lines) l JOIN public.service_catalog s ON s.id = (l->>'service_id')::uuid
  WHERE s.active AND s.price_minor = (l->>'unit_price_minor')::bigint
    AND (l->>'quantity')::integer BETWEEN 1 AND 100;
  IF matched <> jsonb_array_length(lines) THEN
    RAISE EXCEPTION 'catalog_changed' USING ERRCODE = 'P0001';
  END IF;
  -- Doctors: distinct per line, active doctors, only on services that attribute doctors.
  IF EXISTS (
    SELECT 1 FROM jsonb_array_elements(lines) WITH ORDINALITY AS l(value, pos)
    CROSS JOIN LATERAL jsonb_array_elements_text(coalesce(l.value->'doctor_ids', '[]')) AS d(doctor_id)
    LEFT JOIN public.service_catalog s ON s.id = (l.value->>'service_id')::uuid
    LEFT JOIN public.staff st ON st.id = d.doctor_id::uuid AND st.role = 'doctor' AND st.is_active
    GROUP BY l.pos, d.doctor_id
    HAVING count(*) > 1 OR bool_or(st.id IS NULL) OR bool_or(NOT s.attributes_doctors)
  ) THEN RAISE EXCEPTION 'invalid_doctors' USING ERRCODE = 'P0001'; END IF;
  discount := CASE kind
    WHEN 'none' THEN 0
    WHEN 'percent' THEN round(subtotal::numeric * amount / 10000)::bigint
    WHEN 'amount' THEN amount END;
  IF discount IS NULL OR (kind = 'percent' AND amount NOT BETWEEN 1 AND 10000)
    OR (kind = 'amount' AND amount NOT BETWEEN 1 AND subtotal) OR (kind = 'none' AND amount <> 0) THEN
    RAISE EXCEPTION 'invalid_discount' USING ERRCODE = 'P0001';
  END IF;
  INSERT INTO public.invoices(branch, number, patient_id, patient_name, file_number, invoice_date,
    subtotal_minor, discount_kind, discount_value, discount_minor, total_minor, note,
    replaces_invoice_id, created_by, created_by_name)
  VALUES (branch, public.invoice_next_number(branch, 'invoice'), person.id, person.full_name,
    person.file_number, bill_date, subtotal, kind, amount, discount, subtotal - discount,
    nullif(btrim(p_data->>'note'), ''), p_replaces, p_actor, public.invoice_actor_name(p_actor))
  RETURNING id INTO inv_id;
  WITH input AS (
    SELECT l.value, l.pos::integer AS pos, s.*, (l.value->>'quantity')::integer AS qty
    FROM jsonb_array_elements(lines) WITH ORDINALITY AS l(value, pos)
    JOIN public.service_catalog s ON s.id = (l.value->>'service_id')::uuid
  ), weighted AS (
    SELECT *, price_minor * qty AS gross, sum(price_minor * qty) OVER (ORDER BY pos) AS cumulative
    FROM input
  ), inserted AS (
    INSERT INTO public.invoice_lines(invoice_id, position, service_id, service_name, service_type,
      sessions_per_unit, quantity, unit_price_minor, gross_minor, discount_minor, net_minor,
      sessions_granted)
    SELECT inv_id, pos, id, name, service_type, sessions_per_unit, qty, price_minor, gross, part,
      gross - part, CASE WHEN service_type IN ('pt_session', 'traction_session')
        THEN qty * sessions_per_unit ELSE 0 END
    FROM (SELECT *, CASE WHEN subtotal = 0 THEN 0 ELSE div(discount::numeric * cumulative, subtotal)
      - div(discount::numeric * (cumulative - gross), subtotal) END AS part FROM weighted) parts
    RETURNING id, position
  )
  INSERT INTO public.invoice_line_doctors(line_id, doctor_id, doctor_name)
  SELECT ins.id, st.id, st.full_name FROM inserted ins
  JOIN input ON input.pos = ins.position
  CROSS JOIN LATERAL jsonb_array_elements_text(coalesce(input.value->'doctor_ids', '[]')) AS d(doctor_id)
  JOIN public.staff st ON st.id = d.doctor_id::uuid;
  SELECT pt, traction INTO grant_pt, grant_tr FROM public.invoice_remaining_sessions(inv_id);
  PERFORM public.invoice_adjust_sessions(person.id, grant_pt, grant_tr);
  RETURN inv_id;
END;
$$;

-- An invoice can be voided only without active money documents, and only
-- while its remaining sessions are still unused and unbooked.
CREATE FUNCTION public.invoice_void(p_invoice public.invoices, p_reason text, p_actor uuid)
RETURNS void LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE left_pt integer; left_tr integer;
BEGIN
  IF p_invoice.voided_at IS NOT NULL THEN RAISE EXCEPTION 'already_voided' USING ERRCODE = 'P0001'; END IF;
  IF EXISTS (SELECT 1 FROM public.invoice_receipts WHERE invoice_id = p_invoice.id AND voided_at IS NULL)
    OR EXISTS (SELECT 1 FROM public.invoice_refunds WHERE invoice_id = p_invoice.id AND voided_at IS NULL) THEN
    RAISE EXCEPTION 'has_payments' USING ERRCODE = 'P0001';
  END IF;
  SELECT pt, traction INTO left_pt, left_tr FROM public.invoice_remaining_sessions(p_invoice.id);
  PERFORM public.invoice_adjust_sessions(p_invoice.patient_id, -left_pt, -left_tr);
  UPDATE public.invoices SET voided_at = clock_timestamp(), voided_by = p_actor,
    voided_by_name = public.invoice_actor_name(p_actor), void_reason = btrim(p_reason),
    version = version + 1
  WHERE id = p_invoice.id;
END;
$$;

REVOKE ALL ON FUNCTION public.invoice_save_service(jsonb, uuid),
  public.invoice_create(jsonb, uuid, boolean, uuid),
  public.invoice_void(public.invoices, text, uuid) FROM PUBLIC, anon, authenticated;
