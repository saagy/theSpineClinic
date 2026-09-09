-- Empty means no clinical/financial records or nonzero session balances.
-- The parent row lock serializes against concurrent child inserts via their FKs.
CREATE OR REPLACE FUNCTION public.patient_has_records(p_patient_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.patients WHERE id = p_patient_id
    AND (session_balance <> 0 OR traction_balance <> 0))
    OR EXISTS (SELECT 1 FROM public.appointments WHERE patient_id = p_patient_id)
    OR EXISTS (SELECT 1 FROM public.payment_records WHERE patient_id = p_patient_id)
    OR EXISTS (SELECT 1 FROM public.patient_programs WHERE patient_id = p_patient_id)
    OR EXISTS (SELECT 1 FROM public.patient_medical_history WHERE patient_id = p_patient_id)
    OR EXISTS (SELECT 1 FROM public.patient_notes WHERE patient_id = p_patient_id)
    OR EXISTS (SELECT 1 FROM public.patient_documents WHERE patient_id = p_patient_id);
$$;
REVOKE ALL ON FUNCTION public.patient_has_records(uuid) FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.guard_nonempty_patient_delete()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF public.patient_has_records(OLD.id) THEN
    RAISE EXCEPTION 'patient_not_empty' USING ERRCODE = '23514';
  END IF;
  RETURN OLD;
END;
$$;
REVOKE ALL ON FUNCTION public.guard_nonempty_patient_delete() FROM PUBLIC, anon, authenticated;
DROP TRIGGER IF EXISTS guard_nonempty_patient_delete ON public.patients;
CREATE TRIGGER guard_nonempty_patient_delete BEFORE DELETE ON public.patients
FOR EACH ROW EXECUTE FUNCTION public.guard_nonempty_patient_delete();

CREATE OR REPLACE FUNCTION public.delete_empty_patient(p_patient_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.staff WHERE user_id = auth.uid() AND is_active
    AND (role IN ('super_admin', 'receptionist') OR (role = 'doctor' AND is_senior))) THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE = '42501';
  END IF;
  PERFORM 1 FROM public.patients WHERE id = p_patient_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Patient not found' USING ERRCODE = 'P0002';
  END IF;
  DELETE FROM public.patients WHERE id = p_patient_id;
END;
$$;
REVOKE ALL ON FUNCTION public.delete_empty_patient(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.delete_empty_patient(uuid) TO authenticated;
