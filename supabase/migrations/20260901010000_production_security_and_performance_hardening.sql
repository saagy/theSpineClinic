-- Migration: 20260901010000_production_security_and_performance_hardening.sql
-- Purpose:
--   1. Add performance indexes for unindexed foreign keys and high-frequency search fields.
--   2. Harden search_path on all existing functions/triggers via ALTER FUNCTION.
--   3. Revoke public/anon EXECUTE privileges from internal/admin functions while preserving anon access on register_doctor_application.

-- ============================================================================
-- 1. EXTENSIONS & PERFORMANCE INDEXES
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Unindexed foreign keys
CREATE INDEX IF NOT EXISTS idx_appointment_doctors_doctor_id ON public.appointment_doctors(doctor_id);
CREATE INDEX IF NOT EXISTS idx_appointment_doctors_appointment_id ON public.appointment_doctors(appointment_id);
CREATE INDEX IF NOT EXISTS idx_appointment_doctors_added_by ON public.appointment_doctors(added_by);
CREATE INDEX IF NOT EXISTS idx_appointments_created_by ON public.appointments(created_by);
CREATE INDEX IF NOT EXISTS idx_patient_doctors_doctor_id ON public.patient_doctors(doctor_id);
CREATE INDEX IF NOT EXISTS idx_patient_documents_patient_id ON public.patient_documents(patient_id);
CREATE INDEX IF NOT EXISTS idx_patient_documents_uploaded_by ON public.patient_documents(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_patient_medical_history_updated_by ON public.patient_medical_history(updated_by);
CREATE INDEX IF NOT EXISTS idx_patient_notes_appointment_id ON public.patient_notes(appointment_id);
CREATE INDEX IF NOT EXISTS idx_patient_notes_created_by ON public.patient_notes(created_by);
CREATE INDEX IF NOT EXISTS idx_patient_programs_created_by ON public.patient_programs(created_by);
CREATE INDEX IF NOT EXISTS idx_patients_created_by ON public.patients(created_by);
CREATE INDEX IF NOT EXISTS idx_payment_records_patient_id ON public.payment_records(patient_id);
CREATE INDEX IF NOT EXISTS idx_payment_records_recorded_by ON public.payment_records(recorded_by);
CREATE INDEX IF NOT EXISTS idx_program_conditions_condition_id ON public.program_conditions(condition_id);
CREATE INDEX IF NOT EXISTS idx_treatment_plans_created_by ON public.treatment_plans(created_by);

-- High-frequency search indexes
CREATE INDEX IF NOT EXISTS idx_patients_phone ON public.patients(phone_number);
CREATE INDEX IF NOT EXISTS idx_patients_full_name_trgm ON public.patients USING gin (full_name gin_trgm_ops);

-- ============================================================================
-- 2. HARDEN search_path ON ALL FUNCTIONS
-- ============================================================================

ALTER FUNCTION public.clinic_timezone() SET search_path = public, pg_temp;
ALTER FUNCTION public.get_auth_staff_profile() SET search_path = public, pg_temp;
ALTER FUNCTION public.can_current_staff_access_patient(uuid) SET search_path = public, pg_temp;
ALTER FUNCTION public.can_current_staff_modify_patient_programs(uuid) SET search_path = public, pg_temp;
ALTER FUNCTION public.current_staff_can_manage_payments() SET search_path = public, pg_temp;
ALTER FUNCTION public.check_patient_has_doctors() SET search_path = public, pg_temp;
ALTER FUNCTION public.enforce_doctor_reference_roles() SET search_path = public, pg_temp;
ALTER FUNCTION public.prevent_referenced_doctor_role_change() SET search_path = public, pg_temp;
ALTER FUNCTION public.sync_staff_email_to_auth_users() SET search_path = public, pg_temp;
ALTER FUNCTION public.verify_staff_update_permissions() SET search_path = public, pg_temp;
ALTER FUNCTION public.handle_package_deduction() SECURITY DEFINER;
ALTER FUNCTION public.handle_package_deduction() SET search_path = public, pg_temp;
ALTER FUNCTION public.handle_payment_package_sync() SET search_path = public, pg_temp;

ALTER FUNCTION public.create_patient_with_doctors(text, text, text, public.clinic_location, uuid, uuid[]) SET search_path = public, pg_temp;
ALTER FUNCTION public.update_patient_doctors(uuid, uuid[]) SET search_path = public, pg_temp;
ALTER FUNCTION public.create_staff_user(text, text, text, public.user_role, text, boolean, public.clinic_location) SET search_path = public, extensions, pg_temp;
ALTER FUNCTION public.update_user_password(uuid, text) SET search_path = public, extensions, pg_temp;
ALTER FUNCTION public.delete_doctor_user(uuid) SET search_path = public, pg_temp;
ALTER FUNCTION public.get_due_patients(date, uuid, public.clinic_location) SET search_path = public, pg_temp;
ALTER FUNCTION public.book_recurring_appointments(uuid, public.appointment_type, timestamp with time zone[], boolean, uuid, uuid[], date) SET search_path = public, pg_temp;
ALTER FUNCTION public.bulk_replace_appointment_doctor(uuid, uuid[], uuid[], date) SET search_path = public, pg_temp;
ALTER FUNCTION public.register_doctor_application(text, text, text, text, public.user_role, public.clinic_location) SET search_path = public, extensions, pg_temp;
ALTER FUNCTION public.update_appointment_doctors(uuid, uuid[], uuid) SET search_path = public, pg_temp;
ALTER FUNCTION public.collect_payment_due(uuid, numeric) SET search_path = public, pg_temp;
ALTER FUNCTION public.create_patient_program(uuid, uuid[], text, text, text, text, text, jsonb, jsonb) SET search_path = public, pg_temp;
ALTER FUNCTION public.update_patient_program(uuid, uuid[], text, text, text, text, text, public.program_status, jsonb, jsonb) SET search_path = public, pg_temp;
ALTER FUNCTION public.upsert_treatment_plan(uuid, uuid, text, boolean, text, jsonb) SET search_path = public, pg_temp;
ALTER FUNCTION public.delete_treatment_plan(uuid) SET search_path = public, pg_temp;
ALTER FUNCTION public.activate_treatment_plan(uuid, uuid) SET search_path = public, pg_temp;

-- ============================================================================
-- 3. REVOKE ANON/PUBLIC PRIVILEGES & GRANT APPROPRIATE ACCESS
-- ============================================================================

-- Revoke EXECUTE from PUBLIC and ANON on all sensitive functions
REVOKE EXECUTE ON FUNCTION public.clinic_timezone() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.get_auth_staff_profile() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.can_current_staff_access_patient(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.can_current_staff_modify_patient_programs(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.current_staff_can_manage_payments() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.check_patient_has_doctors() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.enforce_doctor_reference_roles() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.prevent_referenced_doctor_role_change() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.sync_staff_email_to_auth_users() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.verify_staff_update_permissions() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.handle_package_deduction() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.handle_payment_package_sync() FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.create_patient_with_doctors(text, text, text, public.clinic_location, uuid, uuid[]) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.update_patient_doctors(uuid, uuid[]) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.create_staff_user(text, text, text, public.user_role, text, boolean, public.clinic_location) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.update_user_password(uuid, text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.delete_doctor_user(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.get_due_patients(date, uuid, public.clinic_location) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.book_recurring_appointments(uuid, public.appointment_type, timestamp with time zone[], boolean, uuid, uuid[], date) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.bulk_replace_appointment_doctor(uuid, uuid[], uuid[], date) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.update_appointment_doctors(uuid, uuid[], uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.collect_payment_due(uuid, numeric) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.create_patient_program(uuid, uuid[], text, text, text, text, text, jsonb, jsonb) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.update_patient_program(uuid, uuid[], text, text, text, text, text, public.program_status, jsonb, jsonb) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.upsert_treatment_plan(uuid, uuid, text, boolean, text, jsonb) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.delete_treatment_plan(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.activate_treatment_plan(uuid, uuid) FROM PUBLIC, anon;

-- Grant EXECUTE to AUTHENTICATED on all required operational functions
GRANT EXECUTE ON FUNCTION public.clinic_timezone() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_auth_staff_profile() TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_current_staff_access_patient(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_current_staff_modify_patient_programs(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.current_staff_can_manage_payments() TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_patient_with_doctors(text, text, text, public.clinic_location, uuid, uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_patient_doctors(uuid, uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_staff_user(text, text, text, public.user_role, text, boolean, public.clinic_location) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_user_password(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_doctor_user(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_due_patients(date, uuid, public.clinic_location) TO authenticated;
GRANT EXECUTE ON FUNCTION public.book_recurring_appointments(uuid, public.appointment_type, timestamp with time zone[], boolean, uuid, uuid[], date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.bulk_replace_appointment_doctor(uuid, uuid[], uuid[], date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_appointment_doctors(uuid, uuid[], uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.collect_payment_due(uuid, numeric) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_patient_program(uuid, uuid[], text, text, text, text, text, jsonb, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_patient_program(uuid, uuid[], text, text, text, text, text, public.program_status, jsonb, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_treatment_plan(uuid, uuid, text, boolean, text, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_treatment_plan(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.activate_treatment_plan(uuid, uuid) TO authenticated;

-- Explicitly ensure register_doctor_application is executable by anon and authenticated for doctor applications
REVOKE EXECUTE ON FUNCTION public.register_doctor_application(text, text, text, text, public.user_role, public.clinic_location) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.register_doctor_application(text, text, text, text, public.user_role, public.clinic_location) TO anon, authenticated;
