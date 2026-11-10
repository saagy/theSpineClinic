CREATE VIEW public.billing_register WITH (security_invoker = true) AS
SELECT i.*, coalesce(m.collected, 0)::bigint AS collected_minor,
  coalesce(m.credited, 0)::bigint AS credited_minor,
  coalesce(m.refunded, 0)::bigint AS refunded_minor,
  greatest(i.total_minor - coalesce(m.credited, 0) - coalesce(m.collected, 0)
    + coalesce(m.refunded, 0), 0)::bigint AS outstanding_minor,
  greatest(coalesce(m.collected, 0) - coalesce(m.refunded, 0) - i.total_minor
    + coalesce(m.credited, 0), 0)::bigint AS refundable_minor
FROM public.billing_invoices i LEFT JOIN LATERAL (
  SELECT sum(amount_minor) FILTER (WHERE kind = 'receipt') AS collected,
    sum(amount_minor) FILTER (WHERE kind = 'return') AS credited,
    sum(amount_minor) FILTER (WHERE kind = 'refund') AS refunded
  FROM public.billing_movements WHERE invoice_id = i.id
) m ON true;
GRANT SELECT ON public.billing_register TO authenticated;

CREATE FUNCTION public.billing_lookup(p_kind text, p_query text)
RETURNS TABLE(id uuid, name text, file_number bigint, branch public.clinic_location)
LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $$
  SELECT p.id, p.full_name AS name, p.file_number, p.clinic FROM public.patients p
    WHERE public.billing_can('transact') AND p_kind = 'patient'
    AND (strpos(lower(p.full_name), lower(btrim(p_query))) > 0
      OR strpos(p.phone_number, btrim(p_query)) > 0
      OR p.file_number = CASE WHEN ltrim(btrim(p_query), '#') ~ '^[0-9]{1,18}$' THEN ltrim(btrim(p_query), '#')::bigint END)
  UNION ALL
  SELECT s.id, s.full_name, NULL::bigint, NULL::public.clinic_location FROM public.staff s
    WHERE public.billing_can('transact') AND p_kind = 'doctor' AND s.role = 'doctor' AND s.is_active
    AND (btrim(p_query) = '' OR strpos(lower(s.full_name), lower(btrim(p_query))) > 0)
  ORDER BY name, id LIMIT 40;
$$;

CREATE FUNCTION public.billing_invoice_detail(p_id uuid)
RETURNS jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $$
  SELECT to_jsonb(i) || jsonb_build_object(
    'lines', coalesce((SELECT jsonb_agg(to_jsonb(l) ORDER BY l.position)
      FROM public.billing_invoice_lines l WHERE l.invoice_id = i.id), '[]'::jsonb),
    'movements', coalesce((SELECT jsonb_agg(to_jsonb(m) || jsonb_build_object(
      'allocations', coalesce((SELECT jsonb_agg(to_jsonb(a) ORDER BY l.position)
        FROM public.billing_allocations a JOIN public.billing_invoice_lines l ON l.id = a.line_id
        WHERE a.movement_id = m.id), '[]'::jsonb)) ORDER BY m.recorded_at, m.id)
      FROM public.billing_movements m WHERE m.invoice_id = i.id), '[]'::jsonb))
  FROM public.billing_register i WHERE i.id = p_id;
$$;

CREATE FUNCTION public.billing_list(p_query text, p_branch public.clinic_location, p_state text,
  p_from date, p_to date, p_offset integer, p_limit integer, p_collections boolean DEFAULT false)
RETURNS SETOF jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $$
  WITH matched AS (
    SELECT i.* FROM public.billing_register i
    WHERE (p_branch IS NULL OR i.branch = p_branch)
    AND (btrim(p_query) = '' OR strpos(lower(i.patient_name), lower(btrim(p_query))) > 0
      OR strpos(lower(i.doctor_name), lower(btrim(p_query))) > 0
      OR i.file_number::text = ltrim(btrim(p_query), '#') OR i.number::text = ltrim(btrim(p_query), '#'))
    AND (p_state IS NULL OR (p_state = 'draft' AND i.number IS NULL)
      OR (p_state = 'outstanding' AND i.number IS NOT NULL AND i.outstanding_minor > 0)
      OR (p_state = 'settled' AND i.number IS NOT NULL AND i.outstanding_minor = 0))
    AND (p_collections OR ((p_from IS NULL OR i.service_date >= p_from)
      AND (p_to IS NULL OR i.service_date <= p_to)))
  ), rows AS (
    SELECT to_jsonb(i) AS row, i.created_at AS moment, i.id FROM matched i WHERE NOT p_collections
    UNION ALL
    SELECT to_jsonb(m) || jsonb_build_object('patient_name', i.patient_name, 'file_number', i.file_number,
      'invoice_number', i.number, 'doctor_name', i.doctor_name), m.recorded_at, m.id
    FROM matched i JOIN public.billing_movements m ON m.invoice_id = i.id
    WHERE p_collections AND m.kind IN ('receipt','refund')
      AND (p_from IS NULL OR m.recorded_at >= (p_from::timestamp AT TIME ZONE public.clinic_timezone()))
      AND (p_to IS NULL OR m.recorded_at < ((p_to + 1)::timestamp AT TIME ZONE public.clinic_timezone()))
  )
  SELECT row FROM rows ORDER BY moment DESC, id DESC OFFSET greatest(p_offset, 0)
  LIMIT least(greatest(p_limit, 1), 10001);
$$;

REVOKE ALL ON FUNCTION public.billing_lookup(text,text), public.billing_invoice_detail(uuid),
  public.billing_list(text,public.clinic_location,text,date,date,integer,integer,boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.billing_lookup(text,text), public.billing_invoice_detail(uuid),
  public.billing_list(text,public.clinic_location,text,date,date,integer,integer,boolean) TO authenticated;

