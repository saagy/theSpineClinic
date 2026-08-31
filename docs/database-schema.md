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
| `appointment_type` | `normal_pt_session`, `spinal_traction_session`, `initial_assessment`, `reassessment` | Only PT and traction sessions consume package balance; assessments never deduct. |
| `appointment_status` | `scheduled`, `checked_in`, `cancelled` | `checked_in` deducts balance; reverting to `scheduled`/`cancelled` refunds it. |
| `body_region` | `shoulder`, `elbow`, `hand`, `lumbar_spine`, `thoracic_spine`, `cervical_spine`, `hip_joint`, `knee_joint`, `ankle_joint`, `foot` | Body regions for condition catalog and injury classifications. |
| `program_status` | `active`, `completed`, `archived` | Rehabilitation program lifecycle status. |
| `modality_type` | `muscle_pain`, `mass_built`, `tecar`, `tecar_focal`, `neurodynamic_non_wb`, `neurodynamic_wb` | Physiotherapy equipment & modality devices. |
| `laterality` | `right`, `left`, `both` | Side selection for bilateral body regions. |

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
- `is_senior` (`boolean`, NOT NULL, default `false`) — senior doctor assessment & program creation permission
- `created_at` (`timestamptz`, NOT NULL, default `now()`)
- `phone` (`text`, nullable)
- `branch` (`clinic_location`, nullable)
- `deactivated_at` (`timestamptz`, nullable)

### `patients`
Patient registry plus package credit balances.
- `id` (`uuid`, PK, default `gen_random_uuid()`)
- `full_name` (`text`, NOT NULL)
- `phone_number` (`text`, NOT NULL)
- `program` (`text`, nullable) — legacy single-line program descriptor
- `clinic` (`clinic_location`, NOT NULL)
- `session_balance` (`integer`, NOT NULL, default `0`) — PT session credits
- `traction_balance` (`integer`, NOT NULL, default `0`) — traction session credits
- `next_visit_date` (`date`, nullable) — recall date for the due-patients queue
- `created_by` (`uuid`, FK → `staff(id)` ON DELETE SET NULL, nullable)
- `created_at` (`timestamptz`, NOT NULL, default `now()`)

### `patient_medical_history`
Structured patient medical history (1:1 with patients, managed by senior doctors).
- `id` (`uuid`, PK, default `gen_random_uuid()`)
- `patient_id` (`uuid`, UNIQUE, FK → `patients(id)` ON DELETE CASCADE, NOT NULL)
- `has_diabetes` (`boolean`, NOT NULL, default `false`)
- `hba1c_value` (`text`, nullable)
- `has_hypertension` (`boolean`, NOT NULL, default `false`)
- `has_hyperlipidemia` (`boolean`, NOT NULL, default `false`)
- `has_rheumatology` (`boolean`, NOT NULL, default `false`)
- `rheumatology_details` (`text`, nullable)
- `additional_notes` (`text`, nullable)
- `updated_by` (`uuid`, FK → `staff(id)` ON DELETE SET NULL, nullable)
- `created_at` (`timestamptz`, NOT NULL, default `now()`)
- `updated_at` (`timestamptz`, NOT NULL, default `now()`)

### `condition_catalog`
Reference catalog of injury/condition definitions organized by body region (~108 items).
- `id` (`uuid`, PK, default `gen_random_uuid()`)
- `region` (`body_region`, NOT NULL)
- `condition_name` (`text`, NOT NULL)
- `display_order` (`integer`, NOT NULL, default `0`)
- `created_at` (`timestamptz`, NOT NULL, default `now()`)

### `patient_programs`
Rehabilitation and assessment programs (1:N with patients).
- `id` (`uuid`, PK, default `gen_random_uuid()`)
- `patient_id` (`uuid`, FK → `patients(id)` ON DELETE CASCADE, NOT NULL)
- `created_by` (`uuid`, FK → `staff(id)` ON DELETE RESTRICT, NOT NULL)
- `status` (`program_status`, NOT NULL, default `'active'`)
- `examination` (`text`, nullable)
- `imaging_notes` (`text`, nullable)
- `exaggerating_positions` (`text`, nullable)
- `relieving_positions` (`text`, nullable)
- `notes` (`text`, nullable)
- `created_at` (`timestamptz`, NOT NULL, default `now()`)
- `updated_at` (`timestamptz`, NOT NULL, default `now()`)

### `program_conditions`
Junction table linking programs with selected conditions from the catalog (N:N).
- `id` (`uuid`, PK, default `gen_random_uuid()`)
- `program_id` (`uuid`, FK → `patient_programs(id)` ON DELETE CASCADE, NOT NULL)
- `condition_id` (`uuid`, FK → `condition_catalog(id)` ON DELETE CASCADE, NOT NULL)

### `treatment_plans`
Treatment plan configurations within a program (1:N with programs).
- `id` (`uuid`, PK, default `gen_random_uuid()`)
- `program_id` (`uuid`, FK → `patient_programs(id)` ON DELETE CASCADE, NOT NULL)
- `created_by` (`uuid`, FK → `staff(id)` ON DELETE RESTRICT, NOT NULL)
- `plan_name` (`text`, NOT NULL, default `'Plan 1'`)
- `is_active` (`boolean`, NOT NULL, default `true`)
- `notes` (`text`, nullable)
- `created_at` (`timestamptz`, NOT NULL, default `now()`)
- `updated_at` (`timestamptz`, NOT NULL, default `now()`)

### `plan_modalities`
Equipment/modalities attached to a treatment plan (1:N with treatment plans).
- `id` (`uuid`, PK, default `gen_random_uuid()`)
- `treatment_plan_id` (`uuid`, FK → `treatment_plans(id)` ON DELETE CASCADE, NOT NULL)
- `modality_type` (`modality_type`, NOT NULL)
- `notes` (`text`, nullable)

### `modality_regions`
Target regions and duration for modality configurations (1:N with plan modalities).
- `id` (`uuid`, PK, default `gen_random_uuid()`)
- `plan_modality_id` (`uuid`, FK → `plan_modalities(id)` ON DELETE CASCADE, NOT NULL)
- `target_region` (`text`, NOT NULL)
- `laterality` (`laterality`, nullable)
- `time_minutes` (`integer`, NOT NULL, default `15`)

### `patient_doctors`
Long-term (M:N) doctor assignments. Composite PK (`patient_id`, `doctor_id`).
- `patient_id` (`uuid`, PK/FK → `patients(id)` ON DELETE CASCADE, NOT NULL)
- `doctor_id` (`uuid`, PK/FK → `staff(id)` ON DELETE CASCADE, NOT NULL) — must reference a `doctor`-role staff row
- `assigned_at` (`timestamptz`, NOT NULL, default `now()`)

### `appointments`
Visit schedule.
- `id` (`uuid`, PK, default `gen_random_uuid()`)
- `patient_id` (`uuid`, FK → `patients(id)` ON DELETE CASCADE, NOT NULL)
- `type` (`appointment_type`, NOT NULL)
- `status` (`appointment_status`, NOT NULL, default `'scheduled'`)
- `use_package` (`boolean`, NOT NULL, default `true`)
- `scheduled_at` (`timestamptz`, NOT NULL, default `now()`)
- `created_by` (`uuid`, FK → `staff(id)` ON DELETE SET NULL, nullable)
- `created_at` (`timestamptz`, NOT NULL, default `now()`)

### `appointment_doctors`
Per-appointment doctor assignments.
- `id` (`uuid`, PK, default `gen_random_uuid()`)
- `appointment_id` (`uuid`, FK → `appointments(id)` ON DELETE CASCADE, NOT NULL)
- `doctor_id` (`uuid`, FK → `staff(id)` ON DELETE RESTRICT, NOT NULL)
- `is_active` (`boolean`, NOT NULL, default `true`)
- `added_by` (`uuid`, FK → `staff(id)` ON DELETE SET NULL, nullable)
- `added_at` (`timestamptz`, NOT NULL, default `now()`)

### `patient_documents`
Metadata for files stored in the private `patient-documents` Storage bucket.
- `id` (`uuid`, PK, default `gen_random_uuid()`)
- `patient_id` (`uuid`, FK → `patients(id)` ON DELETE CASCADE, NOT NULL)
- `program_id` (`uuid`, FK → `patient_programs(id)` ON DELETE SET NULL, nullable)
- `file_url` (`text`, NOT NULL)
- `file_name` (`text`, NOT NULL)
- `thumbnail_url` (`text`, nullable)
- `uploaded_by` (`uuid`, FK → `staff(id)` ON DELETE SET NULL, nullable)
- `uploaded_at` (`timestamptz`, NOT NULL, default `now()`)

### `patient_notes`
Clinical progress notes.
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
staff                    -> patient_medical_history.updated_by
staff                    -> patient_programs.created_by
staff                    -> treatment_plans.created_by
patients                 <- patient_doctors.patient_id   (M:N to doctors)
patients                 <- appointments.patient_id
patients                 <- patient_notes.patient_id
patients                 <- patient_documents.patient_id
patients                 <- payment_records.patient_id
patients                 <- patient_medical_history.patient_id (1:1)
patients                 <- patient_programs.patient_id (1:N)
patient_programs         <- program_conditions.program_id (1:N)
condition_catalog        <- program_conditions.condition_id (N:1)
patient_programs         <- treatment_plans.program_id (1:N)
patient_programs         <- patient_documents.program_id (optional imaging link)
treatment_plans          <- plan_modalities.treatment_plan_id (1:N)
plan_modalities          <- modality_regions.plan_modality_id (1:N)
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
| `idx_medical_history_patient` | `patient_medical_history` | Medical history lookup per patient. |
| `idx_condition_catalog_region` | `condition_catalog` | Sorted condition catalog retrieval by region. |
| `idx_patient_programs_patient` | `patient_programs` | Program lookups per patient. |
| `idx_program_conditions_program` | `program_conditions` | Condition joins per program. |
| `idx_treatment_plans_program` | `treatment_plans` | Active plan resolution per program. |
| `idx_plan_modalities_plan` | `plan_modalities` | Modality list per treatment plan. |
| `idx_modality_regions_modality` | `modality_regions` | Target regions per modality. |
| `idx_patient_documents_program` | `patient_documents` | Program imaging attachments query. |

## 5. Functions & RPCs

### RLS helpers
| Function | Purpose |
| --- | --- |
| `get_auth_staff_profile()` | Returns `(staff_id, staff_role, staff_active)` for `auth.uid()`. Backbone of every policy. |
| `current_staff_can_manage_payments()` | True for active super admins and receptionists with `can_manage_payments = true`. Gates payment writes. |
| `can_current_staff_access_patient(p_patient_id)` | Checks if authenticated staff has operational access to patient (admin/receptionist or assigned/booked doctor). |
| `can_current_staff_modify_patient_programs(p_patient_id)` | Checks if authenticated staff is super admin or senior doctor with patient access. |
| `clinic_timezone()` | Returns `'Africa/Cairo'`; single calendar-timezone configuration point. |

### Data-access RPCs (called by repositories)
| Function | Purpose |
| --- | --- |
| `create_patient_with_doctors(...)` | Registers a patient and inserts assignments atomically. |
| `update_patient_doctors(...)` | Replaces long-term assignments. |
| `update_appointment_doctors(...)` | Synchronizes appointment doctor assignments. |
| `collect_payment_due(...)` | Atomically adds collected due to payment record amount. |
| `book_recurring_appointments(...)` | Books slots with package balance locking. |
| `bulk_replace_appointment_doctor(...)` | Swaps an absent doctor off a day's appointments. |
| `get_due_patients(...)` | Branch-scoped due-patient queue. |
| `create_patient_program(...)` | Atomically creates a patient rehabilitation program with conditions and attached imaging documents. |
| `update_patient_program(...)` | Atomically updates a patient program, its conditions, status, and attached documents. |
| `upsert_treatment_plan(...)` | Atomically creates/updates a treatment plan and re-syncs child modalities and target regions. |
| `delete_treatment_plan(...)` | Atomically deletes a treatment plan and cascades child modalities/regions. |
| `activate_treatment_plan(...)` | Atomically marks a treatment plan as the active version and deactivates others. |

### Auth & Staff Registration RPCs
| Function | Purpose |
| --- | --- |
| `register_doctor_application(...)` | Creates `auth.users` row and inactive `staff` application profile (`anon` accessible). |
| `create_staff_user(...)` | Creates `auth.users` row plus linked active `staff` profile (super admin only). |
| `update_user_password(...)` | Resets a staff user's password (super admin only). |
| `delete_doctor_user(...)` | Deletes a doctor auth user to reject applications (super admin only). |

## 6. Triggers

| Trigger | Fires on | Effect |
| --- | --- | --- |
| `trigger_appointment_package_deduction` | `AFTER UPDATE` on `appointments` | Deducts/refunds session balances on status transitions. |
| `trigger_payment_insert_package_sync` | `AFTER INSERT` on `payment_records` | Adds purchased credits to patient balance. |
| `trigger_payment_delete_package_sync` | `AFTER DELETE` on `payment_records` | Reverses credits of deleted payment. |
| `tr_check_patient_has_doctors` | `AFTER DELETE OR UPDATE` on `patient_doctors` (deferred) | Rejects change if patient would have zero doctors. |
| `tr_enforce_patient_doctor_role` | `BEFORE INSERT/UPDATE` on `patient_doctors.doctor_id` | Guarantees doctor role on assignment. |
| `tr_enforce_appointment_doctor_roles` | `BEFORE INSERT/UPDATE` on `appointment_doctors.doctor_id` | Guarantees doctor role on appointment. |
| `tr_verify_staff_update_permissions` | `BEFORE UPDATE` on `staff` | Controls self-edits vs admin edits. |
| `tr_prevent_referenced_doctor_role_change` | `BEFORE UPDATE OF role` on `staff` | Blocks changing doctor role while referenced. |
| `trigger_sync_staff_email` | `AFTER UPDATE` on `staff` | Syncs email changes to `auth.users`. |

## 7. Row-Level Security Summary

| Table | Read | Write |
| --- | --- | --- |
| `staff` | Active staff (directory) + own profile | Own profile (limited by trigger) / super admin |
| `patients` | Super admin + receptionist; doctors scoped to assigned/appointment patients | Super admin + receptionist; doctors scoped (update only) |
| `patient_medical_history` | Staff with patient access (`can_current_staff_access_patient`) | Super admin + senior doctors (`can_current_staff_modify_patient_programs`) |
| `condition_catalog` | All active staff | Super admin only |
| `patient_programs` | Staff with patient access | Super admin + senior doctors |
| `program_conditions` | Staff with patient access | Super admin + senior doctors |
| `treatment_plans` | Staff with patient access | Super admin + senior doctors |
| `plan_modalities` | Staff with patient access | Super admin + senior doctors |
| `modality_regions` | Staff with patient access | Super admin + senior doctors |
| `patient_doctors` | All active staff | Super admin + receptionist |
| `appointments`, `appointment_doctors` | All active staff | All active staff |
| `patient_documents` | Staff with patient access | Staff with patient access (file_name rename only) |
| `patient_notes` | Staff with patient access | Staff with patient access |
| `payment_records` | All active staff | Only `current_staff_can_manage_payments()` callers |
| `storage.objects` (`patient-documents`) | Staff with patient access | Super admin + receptionist + doctors |
