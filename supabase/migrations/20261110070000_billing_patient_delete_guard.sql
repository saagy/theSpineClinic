CREATE OR REPLACE FUNCTION public.patient_has_records(p_patient_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT EXISTS (SELECT 1 FROM public.patients WHERE id = p_patient_id
    AND (session_balance <> 0 OR traction_balance <> 0))
    OR EXISTS (SELECT 1 FROM public.appointments WHERE patient_id = p_patient_id)
    OR EXISTS (SELECT 1 FROM public.payment_records WHERE patient_id = p_patient_id)
    OR EXISTS (SELECT 1 FROM public.patient_programs WHERE patient_id = p_patient_id)
    OR EXISTS (SELECT 1 FROM public.patient_medical_history WHERE patient_id = p_patient_id)
    OR EXISTS (SELECT 1 FROM public.patient_notes WHERE patient_id = p_patient_id)
    OR EXISTS (SELECT 1 FROM public.patient_documents WHERE patient_id = p_patient_id)
    OR EXISTS (SELECT 1 FROM public.billing_invoices WHERE patient_id = p_patient_id);
$$;

-- Expose only the deletion decision, never financial data.
CREATE FUNCTION public.billing_patient_has_invoices(p_patient_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT public.can_current_staff_access_patient(p_patient_id) AND
    EXISTS (SELECT 1 FROM public.billing_invoices WHERE patient_id = p_patient_id);
$$;
REVOKE ALL ON FUNCTION public.billing_patient_has_invoices(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.billing_patient_has_invoices(uuid) TO authenticated;

