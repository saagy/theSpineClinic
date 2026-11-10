CREATE FUNCTION public.billing_export(p_query text, p_branch public.clinic_location, p_state text,
  p_from date, p_to date, p_collections boolean)
RETURNS jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $$
  SELECT coalesce(jsonb_agg(row), '[]'::jsonb)
  FROM public.billing_list(p_query, p_branch, p_state, p_from, p_to, 0, 10001, p_collections) AS row;
$$;
REVOKE ALL ON FUNCTION public.billing_export(text,public.clinic_location,text,date,date,boolean)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.billing_export(text,public.clinic_location,text,date,date,boolean)
  TO authenticated;

