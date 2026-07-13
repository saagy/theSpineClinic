# Database Schema Reference

This document provides the complete reference for the Spine Clinic Supabase Postgres schema represented by `supabase/full_schema.sql`.

## 1. Custom Enum Types

### `user_role`
Values:
- `super_admin`: System administrator with unrestricted management permissions.
- `receptionist`: Front-desk staff managing patients and appointments. Payment writes require `can_manage_payments`.
- `doctor`: Physical therapist handling patient sessions and clinical notes.

### `clinic_location`
Values:
- `tagamoa`: Tagamoa branch location.
- `masr_elgedida`: Masr El-Gedida branch location.

### `appointment_type`
Values:
- `normal_pt_session`: Standard physical therapy treatment session.
- `spinal_traction_session`: Specialized spinal traction treatment session.
- `check_up`: Follow-up check-up visit.
- `initial_assessment`: First-time patient assessment (never deducts session/traction balance).
- `reassessment`: Periodic progress re-evaluation (never deducts session/traction balance).

### `appointment_status`
Values:
- `scheduled`: Appointment booked for a future date/time.
- `checked_in`: Patient arrived at clinic (deducts session/traction balance if `use_package` is true).
- `cancelled`: Appointment cancelled (refunds deducted balance if previously checked in).

---

## 2. Core Database Tables

### `staff`
Stores staff user profiles linked to Supabase Auth (`auth.users`).
- `id` (`uuid`, PK, Default: `gen_random_uuid()`)
- `user_id` (`uuid`, UNIQUE, FK -> `auth.users(id)` `ON DELETE CASCADE`, Nullable)
- `full_name` (`text`, NOT NULL)
- `email` (`text`, UNIQUE, NOT NULL)
- `role` (`user_role`, NOT NULL)
- `is_active` (`boolean`, NOT NULL, Default: `true`)
- `can_manage_payments` (`boolean`, NOT NULL, Default: `false`)
- `created_at` (`timestamptz`, NOT NULL, Default: `now()`)
- `phone` (`text`, Nullable)
- `branch` (`clinic_location`, Nullable)
- `deactivated_at` (`timestamptz`, Nullable)

### `patients`
Central patient registry and session/traction package balances.
- `id` (`uuid`, PK, Default: `gen_random_uuid()`)
- `full_name` (`text`, NOT NULL)
- `phone_number` (`text`, NOT NULL)
- `program` (`text`, Nullable)
- `clinic` (`clinic_location`, NOT NULL)
- `session_balance` (`integer`, NOT NULL, Default: `0`)
- `traction_balance` (`integer`, NOT NULL, Default: `0`)
- `created_by` (`uuid`, FK -> `staff(id)` `ON DELETE SET NULL`, Nullable)
- `created_at` (`timestamptz`, NOT NULL, Default: `now()`)

### `patient_doctors`
M:N long-term doctor assignments for patients. Enforced by trigger `tr_check_patient_has_doctors`.
- `doctor_id` must reference a `staff` row whose role is `doctor`; Clinic Admin accounts cannot be assigned as doctors.
- `patient_id` (`uuid`, PK/FK -> `patients(id)` `ON DELETE CASCADE`, NOT NULL)
- `doctor_id` (`uuid`, PK/FK -> `staff(id)` `ON DELETE CASCADE`, NOT NULL)
- `assigned_at` (`timestamptz`, NOT NULL, Default: `now()`)

### `appointments`
Patient visit schedule and status.
- `id` (`uuid`, PK, Default: `gen_random_uuid()`)
- `patient_id` (`uuid`, FK -> `patients(id)` `ON DELETE CASCADE`, NOT NULL)
- `type` (`appointment_type`, NOT NULL)
- `status` (`appointment_status`, NOT NULL, Default: `'scheduled'`)
- `use_package` (`boolean`, NOT NULL, Default: `true`)
- `scheduled_at` (`timestamptz`, NOT NULL, Default: `now()`)
- `created_by` (`uuid`, FK -> `staff(id)` `ON DELETE SET NULL`, Nullable)
- `created_at` (`timestamptz`, NOT NULL, Default: `now()`)

### `appointment_doctors`
Appointment-level doctor assignments with inactive rows retained as history.
- `doctor_id` must reference a `staff` row whose role is `doctor`.
- `id` (`uuid`, PK, Default: `gen_random_uuid()`)
- `appointment_id` (`uuid`, FK -> `appointments(id)` `ON DELETE CASCADE`, NOT NULL)
- `doctor_id` (`uuid`, FK -> `staff(id)` `ON DELETE RESTRICT`, NOT NULL)
- `is_active` (`boolean`, NOT NULL, Default: `true`)
- `added_by` (`uuid`, FK -> `staff(id)` `ON DELETE SET NULL`, Nullable)
- `added_at` (`timestamptz`, NOT NULL, Default: `now()`)

### `patient_documents`
Metadata for uploaded clinical files stored in Supabase Storage (`patient-documents` bucket).
- Active admins and receptionists have full document access. Doctors have access only through a direct patient assignment or any active appointment-doctor relationship.
- Authenticated clients may update only `file_name`; Storage object paths and other metadata columns are immutable through document rename.
- `id` (`uuid`, PK, Default: `gen_random_uuid()`)
- `patient_id` (`uuid`, FK -> `patients(id)` `ON DELETE CASCADE`, NOT NULL)
- `file_url` (`text`, NOT NULL)
- `file_name` (`text`, NOT NULL)
- `thumbnail_url` (`text`, Nullable)
- `uploaded_by` (`uuid`, FK -> `staff(id)` `ON DELETE SET NULL`, Nullable)
- `uploaded_at` (`timestamptz`, NOT NULL, Default: `now()`)

### `patient_notes`
Clinical progress notes created by doctors or staff.
- `id` (`uuid`, PK, Default: `gen_random_uuid()`)
- `patient_id` (`uuid`, FK -> `patients(id)` `ON DELETE CASCADE`, NOT NULL)
- `appointment_id` (`uuid`, FK -> `appointments(id)` `ON DELETE SET NULL`, Nullable)
- `created_by` (`uuid`, FK -> `staff(id)` `ON DELETE RESTRICT`, NOT NULL)
- `note_text` (`text`, NOT NULL)
- `created_at` (`timestamptz`, NOT NULL, Default: `now()`)
- `updated_at` (`timestamptz`, NOT NULL, Default: `now()`)

### `payment_records`
Financial transactions and package balance top-ups.
- `id` (`uuid`, PK, Default: `gen_random_uuid()`)
- `patient_id` (`uuid`, FK -> `patients(id)` `ON DELETE CASCADE`, NOT NULL)
- `amount` (`numeric`, NOT NULL)
- `total_price` (`numeric`, Nullable)
- `reason` (`text`, NOT NULL)
- `session_balance_added` (`integer`, NOT NULL, Default: `0`)
- `traction_balance_added` (`integer`, NOT NULL, Default: `0`)
- `recorded_by` (`uuid`, FK -> `staff(id)` `ON DELETE SET NULL`, Nullable)
- `recorded_at` (`timestamptz`, NOT NULL, Default: `now()`)

---

## 3. Database Functions & RPCs

1. `get_auth_staff_profile()`: Returns `(staff_id uuid, staff_role user_role, staff_active boolean)` for `auth.uid()`. Used internally by all RLS policies.
2. `create_patient_with_doctors(...)`: Atomically registers a patient and inserts assigned doctor records in `patient_doctors`.
3. `update_patient_doctors(...)`: Safely updates a patient's long-term assigned doctors while ensuring at least one active doctor remains.
4. `create_staff_user(...)`: Creates an `auth.users` row and linked `staff` record for super admin staff onboarding.
5. `update_user_password(...)`: Enables super admins to reset a staff user's encrypted password.
6. `delete_doctor_user(...)`: Enables super admins to reject/delete doctor auth users (cascades to `staff`).
7. `book_recurring_appointments(...)`: Books multiple recurring appointments and doctor assignments in a single transaction.
8. `handle_package_deduction()`: Trigger function on `appointments` status update that deducts or refunds package balance.
9. `handle_payment_package_sync()`: Trigger function on `payment_records` insert/delete that adds or subtracts purchased package credits.
10. `check_patient_has_doctors()`: Trigger function on `patient_doctors` delete/update that prevents leaving a patient with 0 assigned doctors.
11. `sync_staff_email_to_auth_users()`: Trigger function on `staff` email update that syncs email changes to `auth.users`.
12. `verify_staff_update_permissions()`: Trigger function on `staff` update that prevents staff members from altering their own role, active status, or payment access.
13. `enforce_doctor_reference_roles()`: Rejects non-doctor staff IDs in patient and appointment doctor references.
14. `prevent_referenced_doctor_role_change()`: Prevents changing a referenced doctor into another role before reassignment.

---

## 4. Storage Bucket Configuration

- Bucket Name: `patient-documents`
- Public Access: `false` (Private bucket)
- RLS Policies: Controlled via `storage.objects` policies matching `patient_documents` permissions for authenticated staff and scoped doctors.
