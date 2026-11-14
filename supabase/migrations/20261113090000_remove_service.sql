-- Removing a service from the catalog. A service that no invoice has used
-- is deleted for good. One that invoices already list is hidden instead:
-- those invoices and the reports keep its name and price, and it can be
-- restored later. Staff see one action, Remove, either way.
CREATE FUNCTION public.remove_service(p_service_id uuid, p_version integer)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  current_version integer;
BEGIN
  IF NOT public.invoice_can('manage') THEN
    RETURN jsonb_build_object('ok', false, 'error', 'denied');
  END IF;
  SELECT version INTO current_version FROM public.service_catalog
    WHERE id = p_service_id FOR UPDATE;
  IF NOT FOUND OR current_version <> p_version THEN
    RETURN jsonb_build_object('ok', false, 'error', 'stale');
  END IF;
  IF EXISTS (SELECT 1 FROM public.invoice_lines WHERE service_id = p_service_id) THEN
    UPDATE public.service_catalog SET active = false, version = version + 1
      WHERE id = p_service_id;
    RETURN jsonb_build_object('ok', true, 'outcome', 'hidden');
  END IF;
  DELETE FROM public.service_catalog WHERE id = p_service_id;
  RETURN jsonb_build_object('ok', true, 'outcome', 'deleted');
END;
$$;
REVOKE ALL ON FUNCTION public.remove_service(uuid, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.remove_service(uuid, integer) TO authenticated;
