-- Close direct API routes around the client role checks.
CREATE OR REPLACE FUNCTION public.current_staff_has_management_access()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp AS $$
  SELECT EXISTS(SELECT 1 FROM public.staff WHERE user_id=auth.uid() AND is_active
    AND (role IN ('super_admin','receptionist') OR (role='doctor' AND is_senior)));
$$;
REVOKE ALL ON FUNCTION public.current_staff_has_management_access() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.current_staff_has_management_access() TO authenticated;

DROP POLICY IF EXISTS "Staff can view all appointments" ON public.appointments;
DROP POLICY IF EXISTS "Staff can modify appointments" ON public.appointments;
CREATE POLICY "Read accessible appointments" ON public.appointments FOR SELECT TO authenticated
  USING (public.can_current_staff_access_patient(patient_id));
CREATE POLICY "Management creates appointments" ON public.appointments FOR INSERT TO authenticated
  WITH CHECK (public.current_staff_has_management_access());
CREATE POLICY "Update accessible appointments" ON public.appointments FOR UPDATE TO authenticated
  USING (public.can_current_staff_access_patient(patient_id))
  WITH CHECK (public.can_current_staff_access_patient(patient_id));
CREATE POLICY "Delete accessible appointments" ON public.appointments FOR DELETE TO authenticated
  USING (public.can_current_staff_access_patient(patient_id));

DROP POLICY IF EXISTS "Staff can modify appointment doctor assignments" ON public.appointment_doctors;
CREATE POLICY "Management modifies appointment assignments" ON public.appointment_doctors
  FOR ALL TO authenticated USING (public.current_staff_has_management_access())
  WITH CHECK (public.current_staff_has_management_access());
DROP POLICY IF EXISTS "Staff can view appointment doctor assignments" ON public.appointment_doctors;
CREATE POLICY "Read accessible appointment assignments" ON public.appointment_doctors
  FOR SELECT TO authenticated USING (EXISTS(SELECT 1 FROM public.appointments a
    WHERE a.id=appointment_id AND public.can_current_staff_access_patient(a.patient_id)));

DROP POLICY IF EXISTS "All active staff can view payment history logs" ON public.payment_records;
CREATE POLICY "Read accessible payment history" ON public.payment_records FOR SELECT TO authenticated
  USING (public.can_current_staff_access_patient(patient_id));

DROP POLICY IF EXISTS "Allow users to insert their own profile" ON public.staff;
CREATE POLICY "Allow users to insert their own profile" ON public.staff FOR INSERT TO authenticated
  WITH CHECK (user_id=auth.uid() AND NOT is_active AND NOT can_manage_payments
    AND NOT is_senior AND role IN ('doctor','receptionist'));

CREATE OR REPLACE FUNCTION public.guard_patient_balance_write()
RETURNS trigger LANGUAGE plpgsql SET search_path = public, pg_temp AS $$
BEGIN
  -- Nested database balance triggers remain authorized; direct doctor writes do not.
  IF auth.uid() IS NOT NULL AND pg_trigger_depth() = 1
     AND (NEW.session_balance IS DISTINCT FROM OLD.session_balance
       OR NEW.traction_balance IS DISTINCT FROM OLD.traction_balance)
     AND NOT EXISTS(SELECT 1 FROM public.get_auth_staff_profile()
       WHERE staff_active AND staff_role IN ('super_admin','receptionist')) THEN
    RAISE EXCEPTION 'Permission denied: cannot manually change package balances'
      USING ERRCODE='42501';
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER guard_patient_balance_write BEFORE UPDATE ON public.patients
  FOR EACH ROW EXECUTE FUNCTION public.guard_patient_balance_write();

CREATE OR REPLACE FUNCTION public.can_current_staff_edit_appointment(p_appointment_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=public,pg_temp AS $$
  SELECT public.current_staff_has_management_access() OR EXISTS (
    SELECT 1 FROM public.appointments a JOIN public.staff s ON s.user_id=auth.uid()
    WHERE a.id=p_appointment_id AND s.is_active AND s.role='doctor' AND (
      EXISTS(SELECT 1 FROM public.patient_doctors pd WHERE pd.patient_id=a.patient_id AND pd.doctor_id=s.id)
      OR (abs((a.scheduled_at AT TIME ZONE public.clinic_timezone())::date -
          (now() AT TIME ZONE public.clinic_timezone())::date)<=2
        AND EXISTS(SELECT 1 FROM public.appointment_doctors ad
          WHERE ad.appointment_id=a.id AND ad.doctor_id=s.id AND ad.is_active))));
$$;
REVOKE ALL ON FUNCTION public.can_current_staff_edit_appointment(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.can_current_staff_edit_appointment(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.guard_appointment_edit()
RETURNS trigger LANGUAGE plpgsql SET search_path=public,pg_temp AS $$
BEGIN
  IF auth.uid() IS NULL THEN RETURN coalesce(NEW,OLD); END IF;
  IF TG_OP='UPDATE' AND (NEW.patient_id IS DISTINCT FROM OLD.patient_id
      OR NEW.created_by IS DISTINCT FROM OLD.created_by OR NEW.id IS DISTINCT FROM OLD.id) THEN
    RAISE EXCEPTION 'Appointment identity cannot be changed' USING ERRCODE='42501';
  END IF;
  IF TG_OP='DELETE' OR NEW.scheduled_at IS DISTINCT FROM OLD.scheduled_at
      OR NEW.type IS DISTINCT FROM OLD.type OR NEW.use_package IS DISTINCT FROM OLD.use_package THEN
    IF NOT public.can_current_staff_edit_appointment(OLD.id) THEN
      RAISE EXCEPTION 'Permission denied: cannot edit appointment' USING ERRCODE='42501';
    END IF;
  END IF;
  RETURN coalesce(NEW,OLD);
END;
$$;
CREATE TRIGGER guard_appointment_edit BEFORE UPDATE OR DELETE ON public.appointments
  FOR EACH ROW EXECUTE FUNCTION public.guard_appointment_edit();

-- Explicit base grants for reproducible fresh Supabase databases.
GRANT SELECT,INSERT,UPDATE,DELETE ON public.staff,public.patients,public.patient_doctors,
  public.appointments,public.appointment_doctors,public.patient_notes,public.payment_records TO authenticated;
GRANT SELECT,INSERT,DELETE ON public.patient_documents TO authenticated;
GRANT UPDATE(file_name) ON public.patient_documents TO authenticated;
REVOKE ALL ON FUNCTION public.guard_patient_balance_write(),public.guard_appointment_edit() FROM PUBLIC,anon;

-- Restore the senior-role guard missing from the incremental migration path.
CREATE OR REPLACE FUNCTION public.verify_staff_update_permissions()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path=public,pg_temp
AS $function$
DECLARE
  caller_role public.user_role;
  caller_active boolean;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT role, is_active INTO caller_role, caller_active
  FROM staff
  WHERE user_id = auth.uid();

  IF caller_role = 'super_admin' AND caller_active = true THEN
    RETURN NEW;
  END IF;

  IF OLD.user_id = auth.uid() AND NEW.user_id = auth.uid() THEN
    IF NEW.role IS DISTINCT FROM OLD.role THEN
      RAISE EXCEPTION 'You cannot change your own role.';
    END IF;
    IF NEW.is_active IS DISTINCT FROM OLD.is_active THEN
      RAISE EXCEPTION 'You cannot change your active status.';
    END IF;
    IF NEW.can_manage_payments IS DISTINCT FROM OLD.can_manage_payments THEN
      RAISE EXCEPTION 'You cannot change your payment access.';
    END IF;
    IF NEW.is_senior IS DISTINCT FROM OLD.is_senior THEN
      RAISE EXCEPTION 'You cannot change your senior doctor status.';
    END IF;
    IF NEW.id IS DISTINCT FROM OLD.id OR NEW.user_id IS DISTINCT FROM OLD.user_id THEN
      RAISE EXCEPTION 'You cannot change your ID or User ID.';
    END IF;
    RETURN NEW;
  END IF;

  RAISE EXCEPTION 'Permission denied.';
END;
$function$;
