CREATE FUNCTION public.billing_next_number(p_branch public.clinic_location, p_kind text)
RETURNS bigint LANGUAGE sql SET search_path = '' AS $$
  INSERT INTO public.billing_number_series AS series(branch, kind, last_number)
  VALUES (p_branch, p_kind, 1)
  ON CONFLICT (branch, kind) DO UPDATE SET last_number = series.last_number + 1
  RETURNING last_number;
$$;

CREATE FUNCTION public.billing_save_item(p_data jsonb)
RETURNS uuid LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE item_id uuid := (p_data->>'id')::uuid; saved_id uuid;
BEGIN
  IF NOT public.billing_can('catalog') THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE = '42501';
  END IF;
  IF item_id IS NULL THEN
    INSERT INTO public.billing_items(name, price_minor, active)
    VALUES (btrim(p_data->>'name'), (p_data->>'price_minor')::bigint, (p_data->>'active')::boolean)
    RETURNING id INTO saved_id;
  ELSE
    UPDATE public.billing_items SET name = btrim(p_data->>'name'),
      price_minor = (p_data->>'price_minor')::bigint, active = (p_data->>'active')::boolean,
      version = version + 1
    WHERE id = item_id AND kind = 'service' AND version = (p_data->>'version')::integer
    RETURNING id INTO saved_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'stale' USING ERRCODE = 'P0001'; END IF;
  END IF;
  RETURN saved_id;
END;
$$;

CREATE FUNCTION public.billing_save_draft(p_data jsonb, p_actor uuid)
RETURNS uuid LANGUAGE plpgsql SET search_path = '' AS $$
DECLARE
  inv_id uuid := (p_data->>'id')::uuid;
  person public.patients;
  doctor public.staff;
  consultant public.staff;
  consultant_id uuid := (p_data->>'consultant_id')::uuid;
  discount integer := (p_data->>'discount_bps')::integer;
  line_count integer;
  gross bigint;
  net bigint;
BEGIN
  SELECT * INTO STRICT person FROM public.patients WHERE id = (p_data->>'patient_id')::uuid;
  SELECT * INTO STRICT doctor FROM public.staff
    WHERE id = (p_data->>'doctor_id')::uuid AND role = 'doctor' AND is_active;
  IF consultant_id IS NOT NULL THEN
    SELECT * INTO STRICT consultant FROM public.staff
      WHERE id = consultant_id AND role = 'doctor' AND is_active;
  END IF;
  IF discount IS NULL OR discount NOT BETWEEN 0 AND 10000
    OR p_data->'lines' IS NULL OR jsonb_array_length(p_data->'lines') NOT BETWEEN 1 AND 100 THEN
    RAISE EXCEPTION 'invalid_invoice' USING ERRCODE = '22023';
  END IF;
  -- Prevent price changes during the quote comparison and snapshot.
  PERFORM item.id FROM public.billing_items item
    JOIN jsonb_to_recordset(p_data->'lines') AS input(item_id uuid) ON item.id = input.item_id
    ORDER BY item.id FOR SHARE OF item;
  SELECT count(*), sum(item.price_minor * input.quantity) INTO line_count, gross
  FROM jsonb_to_recordset(p_data->'lines') AS input(item_id uuid, quantity integer, price_minor bigint, item_name text)
    JOIN public.billing_items item ON item.id = input.item_id
  WHERE item.active AND item.kind = 'service' AND item.price_minor = input.price_minor AND item.name = input.item_name
    AND input.quantity BETWEEN 1 AND 1000;
  IF line_count <> jsonb_array_length(p_data->'lines') THEN
    RAISE EXCEPTION 'catalog_changed' USING ERRCODE = 'P0001';
  END IF;
  IF gross > 1000000000000 THEN RAISE EXCEPTION 'invalid_invoice' USING ERRCODE = '22023'; END IF;
  net := round(gross::numeric * (10000 - discount) / 10000);
  IF inv_id IS NULL THEN
    INSERT INTO public.billing_invoices(patient_id, file_number, patient_name, branch, doctor_id,
      doctor_name, consultant_id, consultant_name, service_date, discount_bps, total_minor, created_by)
    VALUES (person.id, person.file_number, person.full_name, (p_data->>'branch')::public.clinic_location,
      doctor.id, doctor.full_name, consultant.id, consultant.full_name,
      (p_data->>'service_date')::date, discount, net, p_actor)
    RETURNING id INTO inv_id;
  ELSE
    UPDATE public.billing_invoices SET patient_id = person.id, file_number = person.file_number,
      patient_name = person.full_name, branch = (p_data->>'branch')::public.clinic_location,
      doctor_id = doctor.id, doctor_name = doctor.full_name, consultant_id = consultant.id,
      consultant_name = consultant.full_name, service_date = (p_data->>'service_date')::date,
      discount_bps = discount, total_minor = net, version = version + 1
    WHERE id = inv_id AND number IS NULL AND version = (p_data->>'version')::integer;
    IF NOT FOUND THEN RAISE EXCEPTION 'stale' USING ERRCODE = 'P0001'; END IF;
    DELETE FROM public.billing_invoice_lines WHERE invoice_id = inv_id;
  END IF;
  WITH priced AS (
    SELECT item.id, item.name, item.price_minor, (input.value->>'quantity')::integer AS qty, input.ordinality AS pos
    FROM jsonb_array_elements(p_data->'lines') WITH ORDINALITY AS input
    JOIN public.billing_items item ON item.id = (input.value->>'item_id')::uuid
  ), allocated AS (
    SELECT *, sum(qty * price_minor) OVER (ORDER BY pos) AS cumulative FROM priced
  )
  INSERT INTO public.billing_invoice_lines(invoice_id, item_id, item_name, position, quantity, price_minor, net_minor)
  SELECT inv_id, id, name, pos, qty, price_minor,
    div(net::numeric * cumulative, gross) - div(net::numeric * (cumulative - qty * price_minor), gross)
  FROM allocated;
  RETURN inv_id;
END;
$$;

CREATE FUNCTION public.billing_issue(p_invoice public.billing_invoices, p_actor uuid)
RETURNS void LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
  IF p_invoice.number IS NOT NULL THEN RAISE EXCEPTION 'stale' USING ERRCODE = 'P0001'; END IF;
  PERFORM item.id FROM public.billing_items item JOIN public.billing_invoice_lines line ON line.item_id = item.id
    WHERE line.invoice_id = p_invoice.id ORDER BY item.id FOR SHARE OF item;
  IF EXISTS (
    SELECT 1 FROM public.billing_invoice_lines line JOIN public.billing_items item ON item.id = line.item_id
    WHERE line.invoice_id = p_invoice.id AND (NOT item.active OR item.price_minor <> line.price_minor
      OR item.name <> line.item_name OR item.kind <> 'service')
  ) THEN RAISE EXCEPTION 'catalog_changed' USING ERRCODE = 'P0001'; END IF;
  UPDATE public.billing_invoices SET
    number = public.billing_next_number(p_invoice.branch, 'invoice'),
    issued_at = clock_timestamp(), issued_by = p_actor, version = version + 1,
    patient_name = (SELECT full_name FROM public.patients WHERE id = p_invoice.patient_id),
    doctor_name = (SELECT full_name FROM public.staff WHERE id = p_invoice.doctor_id),
    consultant_name = (SELECT full_name FROM public.staff WHERE id = p_invoice.consultant_id)
  WHERE id = p_invoice.id;
END;
$$;

REVOKE ALL ON FUNCTION public.billing_next_number(public.clinic_location,text),
  public.billing_save_item(jsonb), public.billing_save_draft(jsonb,uuid),
  public.billing_issue(public.billing_invoices,uuid) FROM PUBLIC, anon, authenticated;

