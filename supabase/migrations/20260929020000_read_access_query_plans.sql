-- Evaluate the current doctor's accessible IDs once per statement instead of
-- repeating staff and assignment lookups for each row of a history/search scan.
-- Membership matches can_current_staff_access_patient; write policies stay intact.
CREATE FUNCTION public.current_staff_accessible_patient_ids() RETURNS SETOF uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=public,pg_temp AS $$
  WITH actor AS MATERIALIZED (
    SELECT id FROM public.staff
    WHERE user_id=auth.uid() AND is_active AND role='doctor'
  )
  SELECT pd.patient_id FROM public.patient_doctors pd JOIN actor s ON s.id=pd.doctor_id
  UNION
  SELECT a.patient_id FROM public.appointment_doctors ad JOIN actor s ON s.id=ad.doctor_id
  JOIN public.appointments a ON a.id=ad.appointment_id WHERE ad.is_active;
$$;
REVOKE ALL ON FUNCTION public.current_staff_accessible_patient_ids() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.current_staff_accessible_patient_ids() TO authenticated;

ALTER POLICY "Read accessible appointments" ON public.appointments USING (
  (SELECT public.current_staff_has_management_access())
  OR patient_id IN (SELECT public.current_staff_accessible_patient_ids())
);
ALTER POLICY "Staff can view accessible patients" ON public.patients USING (
  (SELECT public.current_staff_has_management_access())
  OR id IN (SELECT public.current_staff_accessible_patient_ids())
);

-- The default patient directory is ordered by name and fetched one page at a time.
CREATE INDEX IF NOT EXISTS idx_patients_full_name_order ON public.patients(full_name);
