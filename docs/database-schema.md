# Database Schema Reference

Canonical reference for the Spine Clinic Supabase Postgres schema, derived from
[`supabase/full_schema.sql`](../supabase/full_schema.sql) (the verified full DDL). When the schema changes, update
that file and this document together. For the narrative architecture see
[Database Overview](database-overview.md); for the policy deep-dive see
[Security Model](security-model.md).

All times are stored as `timestamptz`; clinic-local calendar logic goes through
`clinic_timezone()` (currently `Africa/Cairo`).

## 1. Enums

| Type | Values | Notes |
| --- | --- | --- |
| `user_role` | `super_admin`, `receptionist`, `doctor` | `doctor` = physical therapist. No patient login exists — patients are data, not users. |
| `clinic_location` | `tagamoa`, `masr_elgedida` | The two branches. |
| `appointment_type` | `normal_pt_session`, `spinal_traction_session`, `check_up`, `initial_assessment`, `reassessment` | Only PT and traction sessions consume package balance; assessments and check-ups never deduct. |
| `appointment_status` | `scheduled`, `checked_in`, `cancelled` | `checked_in` deducts balance; reverting to `scheduled`/`cancelled` refunds it. |

## 2. Tables

### `staff`
Auth-linked staff profiles. One row per Supabase Auth user (`auth.users`).
- `id` (`uuid`, PK, default `gen_random_uuid()`)
- `user_id` (`uuid`, UNIQUE, FK → `auth.users(id)` ON DELETE CASCADE, nullable)
- `full_name` (`text`, NOT NULL)
- `email` (`text`, UNIQUE, NOT NULL) — kept in sync with `auth.users.email` by trigger `trigger_sync_staff_email`
- `role` (`user_role`, NOT NULL)
- `is_active` (`boolean`, NOT NULL, default `true`)
- `can_manage_payments` (`boolean`, NOT NULL, default `false`) — payment-write permission for receptionists
- `created_at` (`timestamptz`, NOT NULL, default `now()`)
- `phone` (`text`, nullable)
- `branch` (`clinic_location`, nullable)
- `deactivated_at` (`timestamptz`, nullable)

### `patients`
Patient registry plus package credit balances.
- `id` (`uuid`, PK, default `gen_random_uuid()`)
- `full_name` (`text`, NOT NULL)
- `phone_number` (`text`, NOT NULL)
- `program` (`text`, nullable)
- `clinic` (`clinic_location`, NOT NULL)
- `session_balance` (`integer`, NOT NULL, default `0`) — PT session credits
- `traction_balance` (`integer`, NOT NULL, default `0`) — traction session credits
- `next_visit_date` (`date`, nullable) — recall date for the due-patients queue
- `created_by` (`uuid`, FK → `staff(id)` ON DELETE SET NULL, nullable)
- `created_at` (`timestamptz`, NOT NULL, default `now()`)

### `patient_doctors`
Long-term (M:N) doctor assignments. Composite PK (`patient_id`, `doctor_id`).
- `patient_id` (`uuid`, PK/FK → `patients(id)` ON DELETE CASCADE, NOT NULL)
- `doctor_id` (`uuid`, PK/FK → `staff(id)` ON DELETE CASCADE, NOT NULL) — must reference a `doctor`-role staff row (enforced by `tr_enforce_patient_doctor_role`)
- `assigned_at` (`timestamptz`, NOT NULL, default `now()`)

### `appointments`
Visit schedule.
- `id` (`uuid`, PK, default `gen_random_uuid()`)
- `patient_id` (`uuid`, FK → `patients(id)` ON DELETE CASCADE, NOT NULL)
- `type` (`appointment_type`, NOT NULL)
- `status` (`appointment_status`, NOT NULL, default `'scheduled'`)
- `use_package` (`boolean`, NOT NULL, default `true`) — whether check-in consumes a credit
- `scheduled_at` (`timestamptz`, NOT NULL, default `now()`)
- `created_by` (`uuid`, FK → `staff(id)` ON DELETE SET NULL, nullable)
- `created_at` (`timestamptz`, NOT NULL, default `now()`)

### `appointment_doctors`
Per-appointment doctor assignments. Inactive rows are kept as history; a partial
unique index allows only one active row per (appointment, doctor).
- `id` (`uuid`, PK, default `gen_random_uuid()`)
- `appointment_id` (`uuid`, FK → `appointments(id)` ON DELETE CASCADE, NOT NULL)
- `doctor_id` (`uuid`, FK → `staff(id)` ON DELETE RESTRICT, NOT NULL) — must reference a `doctor`-role staff row
- `is_active` (`boolean`, NOT NULL, default `true`)
- `added_by` (`uuid`, FK → `staff(id)` ON DELETE SET NULL, nullable)
- `added_at` (`timestamptz`, NOT NULL, default `now()`)

### `patient_documents`
Metadata for files stored in the private `patient-documents` Storage bucket.
- `id` (`uuid`, PK, default `gen_random_uuid()`)
- `patient_id` (`uuid`, FK → `patients(id)` ON DELETE CASCADE, NOT NULL)
- `file_url` (`text`, NOT NULL)
- `file_name` (`text`, NOT NULL) — the only mutable column for authenticated clients
- `thumbnail_url` (`text`, nullable)
- `uploaded_by` (`uuid`, FK → `staff(id)` ON DELETE SET NULL, nullable)
- `uploaded_at` (`timestamptz`, NOT NULL, default `now()`)

`UPDATE` is revoked on the whole table and re-granted for `file_name` only, so
paths and other metadata are immutable through rename.

### `patient_notes`
Clinical progress notes, optionally linked to an appointment.
- `id` (`uuid`, PK, default `gen_random_uuid()`)
- `patient_id` (`uuid`, FK → `patients(id)` ON DELETE CASCADE, NOT NULL)
- `appointment_id` (`uuid`, FK → `appointments(id)` ON DELETE SET NULL, nullable)
- `created_by` (`uuid`, FK → `staff(id)` ON DELETE RESTRICT, NOT NULL)
- `note_text` (`text`, NOT NULL)
- `created_at` (`timestamptz`, NOT NULL, default `now()`)
- `updated_at` (`timestamptz`, NOT NULL, default `now()`)

### `payment_records`
Financial ledger entries and package top-ups.
- `id` (`uuid`, PK, default `gen_random_uuid()`)
- `patient_id` (`uuid`, FK → `patients(id)` ON DELETE CASCADE, NOT NULL)
- `amount` (`numeric`, NOT NULL)
- `total_price` (`numeric`, nullable)
- `reason` (`text`, NOT NULL)
- `session_balance_added` (`integer`, NOT NULL, default `0`)
- `traction_balance_added` (`integer`, NOT NULL, default `0`)
- `recorded_by` (`uuid`, FK → `staff(id)` ON DELETE SET NULL, nullable)
- `recorded_at` (`timestamptz`, NOT NULL, default `now()`)

## 3. Relationships

```text
staff.user_id            -> auth.users.id          (1:1 profile link)
staff                    -> patients.created_by
staff                    -> appointments.created_by
staff                    -> patient_documents.uploaded_by
staff                    -> patient_notes.created_by
staff                    -> payment_records.recorded_by
patients                 <- patient_doctors.patient_id   (M:N to doctors)
patients                 <- appointments.patient_id
patients                 <- patient_notes.patient_id
patients                 <- patient_documents.patient_id
patients                 <- payment_records.patient_id
appointments             <- appointment_doctors.appointment_id
appointments             <- patient_notes.appointment_id (optional)
```

## 4. Indexes

| Index | Table | Purpose |
| --- | --- | --- |
| `unique_active_appointment_doctor` (unique, partial: `WHERE is_active`) | `appointment_doctors` | One active assignment per appointment+doctor. |
| `idx_appointments_patient_status_scheduled` | `appointments` | Patient history lookups by status, newest first. |
| `idx_appointments_scheduled_at` | `appointments` | Day/timeline schedule queries. |
| `idx_patients_clinic_next_visit` (partial: `WHERE next_visit_date IS NOT NULL`) | `patients` | Due-patients queue per branch. |
| `idx_patient_notes_patient` | `patient_notes` | Notes listing per patient. |

## 5. Functions & RPCs

### RLS helpers
| Function | Purpose |
| --- | --- |
| `get_auth_staff_profile()` | Returns `(staff_id, staff_role, staff_active)` for `auth.uid()`. Backbone of every policy. |
| `current_staff_can_manage_payments()` | True for active super admins and receptionists with `can_manage_payments = true`. Gates payment writes. |
| `clinic_timezone()` | Returns `'Africa/Cairo'`; single calendar-timezone configuration point. |

### Data-access RPCs (called by repositories)
| Function | Purpose |
| --- | --- |
| `create_patient_with_doctors(p_name, p_phone, p_program, p_clinic, p_created_by, p_doctor_ids)` | Registers a patient and inserts assignments atomically; rejects empty or non-doctor doctor lists (receptionist/super admin only). |
| `update_patient_doctors(p_patient_id, p_doctor_ids)` | Replaces long-term assignments; guarantees at least one active doctor remains (receptionist/super admin only). |
| `update_appointment_doctors(p_appointment_id, p_doctor_ids, p_editor_id)` | Synchronizes appointment doctor assignments in a single transaction; deactivates removed doctors, reactivates existing, and inserts new ones (receptionist/super admin only). |
| `collect_payment_due(p_payment_id, p_additional_amount)` | Atomically adds collected due to payment record amount, preventing race condition lost updates (staff with payment permission only). |
| `book_recurring_appointments(p_patient_id, p_type, p_slots, p_use_package, p_creator_id, p_doctor_ids, p_expected_next_visit_date)` | Books one or more slots with all doctors in a single transaction. When `p_use_package` is true it locks the patient row and enforces that requested slots do not exceed available package balance. When `p_expected_next_visit_date` is passed it re-verifies the due state inside the transaction so two receptionists cannot double-book the same recall (receptionist/super admin only). |
| `bulk_replace_appointment_doctor(p_absent_doctor_id, p_replacement_doctor_ids, p_appointment_ids, p_day)` | Transactionally swaps an absent doctor off a selected day's appointments (receptionist/super admin only); returns replaced/remaining counts. |
| `get_due_patients(p_due_on, p_doctor_id, p_clinic)` | Branch-scoped due-patient queue, optionally filtered by doctor; excludes patients who already have a scheduled appointment on/after their `next_visit_date`. |

### Auth & Staff Registration RPCs
| Function | Purpose |
| --- | --- |
| `register_doctor_application(p_email, p_password, p_full_name, p_phone, p_role, p_branch)` | Atomically creates the `auth.users` row and inactive `staff` application profile without requiring a client session. Accessible by unauthenticated applicants (`anon`). |
| `create_staff_user(new_email, new_password, new_full_name, new_role, new_phone, new_can_manage_payments, new_branch)` | Creates an `auth.users` row plus the linked active `staff` profile (super admin only). |
| `update_user_password(target_user_id, new_password)` | Resets a staff user's password (super admin only). |
| `delete_doctor_user(target_user_id)` | Deletes a doctor auth user (cascades to `staff`); used to reject applications (super admin only). |

### Trigger functions (invoked by the triggers in §6)
| Function | Purpose |
| --- | --- |
| `handle_package_deduction()` | Deducts/refunds the correct balance bucket on `appointments` status transitions. |
| `handle_payment_package_sync()` | Adds/subtracts credits when `payment_records` rows are inserted/deleted. |
| `check_patient_has_doctors()` | Blocks assignment deletion that would leave a patient with zero doctors. |
| `enforce_doctor_reference_roles()` | Rejects non-doctor staff IDs in `patient_doctors` / `appointment_doctors`. |
| `prevent_referenced_doctor_role_change()` | Blocks demoting a doctor who is still referenced by assignments. |
| `verify_staff_update_permissions()` | Prevents staff from self-promoting, self-deactivating, or granting themselves payment access. |
| `sync_staff_email_to_auth_users()` | Mirrors `staff.email` changes into `auth.users`. |

## 6. Triggers

| Trigger | Fires on | Effect |
| --- | --- | --- |
| `trigger_appointment_package_deduction` | `AFTER UPDATE` on `appointments` | `scheduled → checked_in` with `use_package` deducts one credit from the type's bucket; `checked_in → scheduled/cancelled` refunds it. Assessments/check-ups never touch balances. |
| `trigger_payment_insert_package_sync` | `AFTER INSERT` on `payment_records` | Adds purchased `session_balance_added` / `traction_balance_added` credits to the patient. |
| `trigger_payment_delete_package_sync` | `AFTER DELETE` on `payment_records` | Reverses the credits of the deleted payment. |
| `tr_check_patient_has_doctors` | `AFTER DELETE OR UPDATE` on `patient_doctors` (deferred) | Rejects the change if it would leave the patient with zero assigned doctors. |
| `tr_enforce_patient_doctor_role` | `BEFORE INSERT/UPDATE` on `patient_doctors.doctor_id` | `doctor_id` must be a doctor-role staff row. |
| `tr_enforce_appointment_doctor_roles` | `BEFORE INSERT/UPDATE` on `appointment_doctors.doctor_id` | Same doctor-role guarantee at appointment level. |
| `tr_verify_staff_update_permissions` | `BEFORE UPDATE` on `staff` | Super admins may edit anyone; everyone else may edit only their own profile and cannot change their own role, active flag, payment permission, or IDs. |
| `tr_prevent_referenced_doctor_role_change` | `BEFORE UPDATE OF role` on `staff` | Blocks changing a doctor's role while they still hold patient or appointment assignments. |
| `trigger_sync_staff_email` | `AFTER UPDATE` on `staff` | Syncs email changes to the linked `auth.users` row. |

## 7. Row-Level Security Summary

RLS is enabled on all eight tables and on `storage.objects` for the documents
bucket. Complete policy text lives in
[`supabase/full_schema.sql`](../supabase/full_schema.sql); the rationale
is documented in the [Security Model](security-model.md). Summary:

| Table | Read | Write |
| --- | --- | --- |
| `staff` | Active staff (directory) + own profile | Own profile (limited by trigger) / super admin |
| `patients` | Super admin + receptionist; doctors scoped to assigned/appointment patients | Super admin + receptionist; doctors scoped (update only) |
| `patient_doctors` | All active staff | Super admin + receptionist |
| `appointments`, `appointment_doctors` | All active staff | All active staff (RPC/trigger layer adds role checks) |
| `patient_documents` | Super admin + receptionist; doctors scoped | Same scope; `file_name` rename only |
| `patient_notes` | Super admin + receptionist; doctors scoped (read/insert) | Super admin + receptionist + doctors |
| `payment_records` | All active staff | Only `current_staff_can_manage_payments()` callers |
| `storage.objects` (`patient-documents`) | Mirrors document scope via `path_tokens[1]` = patient id | Object rename: super admin + receptionist only |

## 8. Storage Bucket

- Bucket: `patient-documents`, **private** (`public = false`).
- Object paths are prefixed with the patient id; policies scope doctor access
  through `path_tokens[1]`.
- Four `storage.objects` policies (select/insert/update/delete) mirror the
  `patient_documents` table rules; update (rename) is limited to super admins
  and receptionists.
