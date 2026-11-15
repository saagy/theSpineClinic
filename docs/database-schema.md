# Database Schema Reference

Canonical reference for the Spine Clinic Supabase Postgres schema, derived from
[`supabase/full_schema.sql`](../supabase/full_schema.sql) (the verified full DDL). When the schema changes, update
that file and this document together. For the narrative architecture see
[Database Overview](database-overview.md); for the policy deep-dive see
[Security Model](security-model.md).

All times are stored as `timestamptz`; clinic-local calendar logic goes through
`clinic_timezone()` (currently `Africa/Cairo`).

The schedule seed helpers are omitted from the schema snapshot. Migration
`20261114033333_restrict_schedule_seed_functions.sql` revokes `EXECUTE` from
`PUBLIC`, `anon`, `authenticated`, and `service_role` on every installed overload.
It was written on November 10 but only applied to the linked project on
November 14, 2026; until then signed-out callers could run the helpers.
The [standalone seed script](../supabase/seed_realistic_data.sql) is for disposable
development databases and applies the same restrictions when it installs the helpers.

September 27 deployed additions: `mutation_receipts` and `document_uploads`, with
four checked RPCs for durable financial/booking retries and document finalization.
See [production hardening](production-hardening.md#schema-additions) for every
column, grant, lifecycle and release requirement. The two migrations are applied
to the linked project; see the [rollout record](production-rollout-2026-09-27.md).

## 1. Enums

September 29 additions (see [launch review](launch-hardening-2026-09-29.md)):
`save_program_mutation(uuid,jsonb)` stores `program_create`/`program_update`
outcomes in `mutation_receipts`, returning a complete program model in the same
transaction. Only active senior doctors/admins can execute it successfully.
`current_staff_accessible_patient_ids()` returns current active-doctor assignment
membership. Patient/appointment SELECT policies combine that set with a scalar
management-access check; write policies retain their existing guards. Both new
functions use fixed search paths and authenticated-only execute grants.
`idx_patients_full_name_order` indexes `patients(full_name)` for directory ordering.

Migration `20261101010000_staged_program_document_removal.sql` (deployed November 2)
extends the same `save_program_mutation(uuid,jsonb)` signature. Optional payload
`p_removed_document_ids` commits document-row deletions with program edits after
checking patient/program ownership. The receipt includes `removed_document_ids`
and `removed_document_paths` (original and thumbnail URLs) for best-effort storage
cleanup after commit. Missing rows are harmless; cross-program IDs reject and
roll back the save. Existing payloads and receipts remain compatible. A retry of
an older successful receipt that ignored removal IDs finishes only the missing
deletions, preserving current program fields, conditions and treatment plans.
It stores the acknowledged result under the same request ID; rejected recovery
keeps the original receipt. The linked database now has this function and its
authenticated-only execution grants; see [recovery and validation](save-feedback.md#november-2-deployment-repair).

Patient deletion safeguard (migration `20260909010000`): `delete_empty_patient(p_patient_id uuid)`
checks an active receptionist, senior doctor or administrator, locks the patient
row and deletes atomically. A `BEFORE DELETE` trigger rejects any patient with
appointments, payment records, programs, notes, documents, medical history or
nonzero session/traction balances, including direct deletes. The private
`patient_has_records` helper is not callable by client roles. Storage cleanup
occurs only after successful database deletion. The schema snapshot also corrects
the existing `create_patient_with_doctors` grants to its current five-argument signature.

| Type | Values | Notes |
| --- | --- | --- |
| `user_role` | `super_admin`, `receptionist`, `doctor` | `doctor` = physical therapist. No patient login exists — patients are data, not users. |
| `clinic_location` | `tagamoa`, `masr_elgedida`, `madinaty` | The branches. See "Adding a branch" below the table. |
| `appointment_type` | `normal_pt_session`, `spinal_traction_session`, `initial_assessment`, `reassessment` | Only PT and traction sessions consume package balance; assessments never deduct. |
| `appointment_status` | `scheduled`, `checked_in`, `cancelled` | `checked_in` deducts balance; reverting to `scheduled`/`cancelled` refunds it. |
| `body_region` | `shoulder`, `elbow`, `hand`, `lumbar_spine`, `thoracic_spine`, `cervical_spine`, `hip_joint`, `knee_joint`, `ankle_joint`, `foot` | Body regions for condition catalog and injury classifications. |
| `program_status` | `active`, `completed`, `archived` | Rehabilitation program lifecycle status. |

### Adding a branch

Branches are the `clinic_location` enum. Adding one is a developer task by design:
there is no in-app branch management, and admins cannot add or rename branches.
Keep it that way unless the product owner asks otherwise. To add one:

1. Add a migration: `ALTER TYPE public.clinic_location ADD VALUE IF NOT EXISTS '<value>';`
   and add the value to the enum in `supabase/full_schema.sql`. Enum values cannot be
   removed, so agree the stored value first. Apply it before releasing the app.
2. Add the value to `ClinicLocation` (`lib/features/patient/domain/clinic_location.dart`)
   with its stored value and document-number prefix, and its label in `AppStrings`.
3. Run `dart run build_runner build --delete-conflicting-outputs` so JSON enum maps
   include it.

Screens, filters, pickers, reports and number series read the enum, so nothing else
changes. Invoice, receipt and refund numbers start a new series on first use.
| `modality_type` | `muscle_pain`, `mass_built`, `tecar`, `tecar_focal`, `neurodynamic_non_wb`, `neurodynamic_wb`, `release`, `met`, `mobilization`, `mulligan`, `exercise` | Physiotherapy equipment & modality devices. |
| `laterality` | `right`, `left`, `both` | Side selection for bilateral body regions. |

## 2. Tables

### Patient identity and details

- `patients.file_number` is the patient's **ID number**, unique within a branch
  (`UNIQUE (clinic, file_number)`). Each branch counts from 1 through
  `patient_number_series`. Triggers assign it: a new patient takes the next
  number of their branch; changing `clinic` restores the number the patient
  held at that branch before (`patient_branch_ids`) or takes the next one.
  Direct updates are rejected and numbers are never reused. Invoices keep the
  ID the patient had when they were issued. Migration `20261112100000`.
- `patients.personal_details` stores optional demographics, contact and referral
  fields. The profile RPCs normalize these values inside the existing patient
  creation or edit transaction. New profiles default to Egyptian nationality.
  Insurance keys were removed by migration `20261111120000`.

The self-pay billing pilot (`billing_*` tables, `billing_register`,
`execute_billing_mutation`) and the legacy `payment_records` ledger with its
package triggers and `collect_payment_due` were removed by migration
`20261111120000_remove_legacy_billing.sql`. Invoices v2 below is the only
billing schema.

### Invoices v2

Migrations `20261110202337`-`20261110202732` (applied to the linked project
on November 10, 2026) add the redesigned billing schema beside the pilot (see
[billing plan](billing-plan.md)). Amounts are EGP
minor units. Rows are never deleted; voided rows keep `voided_at`,
`voided_by`, `voided_by_name` and a required `void_reason`.

| Table | Purpose |
| --- | --- |
| `service_catalog` | Name (unique ignoring case and outer spaces), `service_type` (`pt_session`, `traction_session`, `initial_assessment`, `reassessment`, `other`), `sessions_per_unit` (above 1 only for PT and traction), price, `attributes_doctors`, `active`, `version`. |
| `invoice_number_series` | Last number per branch and kind (`invoice`, `receipt`, `refund`, `discount`). |
| `invoices` | Branch and number, patient name and file-number snapshots, `invoice_date` (today or earlier), subtotal, `discount_kind` (`none`, `percent` in basis points, `amount`), discount, total, optional note, `replaces_invoice_id` for corrections, creator snapshot, `version`. |
| `invoice_lines` | Service snapshot (name, type, sessions per unit), quantity, unit price, gross, the line's share of the invoice discount, net, and `sessions_granted`. |
| `invoice_line_doctors` | Zero or more doctors per line, with name snapshots. |
| `invoice_receipts` | Branch and number, amount, `cash` or `visa`, `received_at` (kept by corrections), `recorded_at`, recorder snapshot, `replaces_receipt_id`. |
| `invoice_refunds` | Refunds and discounts given after issue. `kind` (`refund` or `discount`), branch and number (unique per branch and kind), `value_minor`, derived `payback_minor` and `payback_method`, required reason, recorder snapshot. |
| `invoice_refund_lines` | Cancelled sessions and value per reduced line. Discount lines never cancel sessions. |
| `invoice_allocations` | Signed collected-money shares per line for each receipt or refund; the basis for collected-money doctor earnings. |

Rules enforced in the database:

- `execute_invoice_command(request_id, kind, payload)` is the only write path.
  It is idempotent per request ID through `mutation_receipts` (kind
  `invoice:<kind>`), checks `version` for existing invoices, and returns
  `{ok, invoice_id, document_id}` or `{ok:false, error}`.
  `resolve_invoice_command(request_id, kind)` tombstones an unanswered request.
- `invoice_can('issue')` (active receptionists and super admins) covers reads,
  `invoice_create` and `receipt_create`. `invoice_can('manage')` (payment
  receptionists and super admins) also covers discounts, `service_save`,
  `invoice_void`, `invoice_correct`, `receipt_void`, `receipt_correct`,
  `refund_create`, `discount_create` and `refund_void` (which also cancels a
  discount). Doctors read nothing.
- Creating an invoice adds its PT and traction sessions to the patient's
  balance. Refunds and invoice voids remove only sessions that remain unused
  and are not committed to future package bookings (`sessions_in_use`).
  Voiding a refund restores its sessions.
- Receipts never exceed the amount due. Refund payback is
  `max(0, net collected - (value - refund value))`. The client sends the
  payback it displayed, and a mismatch returns `stale`.
- Receipts are allocated across lines in proportion to each line's
  uncollected value. A refund removes paid-back money from lines collected
  above their new value and moves the remainder to lines with room. A later
  active refund or discount blocks voiding earlier money documents
  (`refund_after`); active refunds and discounts block editing or cancelling
  the invoice (`has_refunds`, `refunds_first`).
- `discount_create` (migration `20261114120000`, applied to the linked
  project on November 14, 2026 as version `20261114120320`) lowers an issued invoice
  without replacing it: the invoice keeps its number and receipts. Payload
  `discount {kind: percent|amount, value}`, `payback_minor`,
  `payback_method`, `branch`, `reason`. A percentage (basis points, up to
  10000) is of the invoice value now; the discount must be from 1 piaster to
  that value (`invalid_discount`). It is stored in `invoice_refunds` with
  `kind = 'discount'` and its own number series, split between lines in
  proportion to each line's value now (cumulative integer division), and
  reallocated like a refund. It never changes session balances. Payback and
  `stale` work as for refunds.
- `invoice_register` (security invoker) adds `refunded_minor` (refunds
  only), `later_discount_minor` (discounts given after issue), `value_minor`,
  `received_minor`, `paid_back_minor`, `net_collected_minor`, `due_minor`,
  `status` (`paid`, `partially_paid`, `unpaid`, `refunded`, `voided`; a
  discount alone never makes an invoice `refunded`), a
  `services` summary and `doctors`. `invoice_detail(id)` returns the
  complete document. `invoice_patient_summary(patient_id)` returns due,
  collected and invoice counts. Invoices also protect a patient from deletion.
- `invoice_report(kind, from, to, branch, doctor)` (migration
  `20261111144013`) is the only report entry point. It requires
  `invoice_can('manage')`, accepts at most 366 clinic days and returns JSON
  with `totals` and `rows` (capped at 5000; totals always cover every row).
  Kinds: `money` (active receipts and refund and discount paybacks by `received_at` /
  `recorded_at` and their own branch, plus `staff` totals and `voids` listed
  by `voided_at`), `revenue` (one row per collected line allocation; the
  doctor filter keeps lines credited to that doctor), `doctor` (requires a
  doctor; that doctor's share of each allocation), `doctors` (share per
  doctor, with a NULL-doctor row for lines without doctor credit),
  `outstanding` (due per patient as of now, by invoice branch; dates are
  ignored) and `services` (lines on non-voided invoices dated in the range:
  units, current value and money collected on them to date, with the lines).
  An allocation is split equally among the line's doctors with cumulative
  floors, so shares always add up to the money collected. Each refund row is
  split (migration `20261113175332`, applied to the linked project on
  November 13, 2026): the money handed back keeps the payback method, and
  money that only moved between lines has a NULL method, reported as
  "Adjustment". Since migration `20261114120000` report rows carry the
  document's `kind` (`receipt`, `refund` or `discount`). Only lines that lost money hold payback, shared in
  proportion to what each lost; stored allocations are unchanged. The private builders
  (`invoice_report_*`) are not executable by clients.
- `doctor_session_report(from, to, branch, doctor)` (migration
  `20261113100000`, applied to the linked project on November 13, 2026) is
  the Billing tab's Doctor sessions report, for doctor pay. It reads
  appointments, never invoices, with the same `invoice_can('manage')` check,
  366-day limit and 5000-row cap. A session counts when its appointment is
  `checked_in` in the clinic-day range; every active doctor on it is credited,
  so a shared session counts once per doctor (`totals.credits`) and once in
  `totals.sessions`. Spinal traction is never counted, even on older
  appointments that still have a doctor. Past appointments still `scheduled`
  are returned as `pending` and are not counted. The branch is the
  appointment's own branch (migration `20261114150000`). Returns `totals`, `rows` (per doctor: `pt_sessions`, `assessments`,
  `reassessments`, `total`, `shared`, `pending`), `sessions` (one row per
  doctor credit, with `shared_with`) and `pending` (with `doctors`).

### `staff`
Auth-linked staff profiles. One row per Supabase Auth user (`auth.users`).
- `id` (`uuid`, PK, default `gen_random_uuid()`)
- `user_id` (`uuid`, UNIQUE, FK → `auth.users(id)` ON DELETE CASCADE, nullable)
- `full_name` (`text`, NOT NULL)
- `email` (`text`, UNIQUE, NOT NULL) — kept in sync with `auth.users.email` by trigger `trigger_sync_staff_email`
- `role` (`user_role`, NOT NULL)
- `is_active` (`boolean`, NOT NULL, default `true`)
- `can_manage_payments` (`boolean`, NOT NULL, default `false`) — payment-write permission for receptionists
- `is_senior` (`boolean`, NOT NULL, default `false`) — senior doctor assessment & program creation permission; shown as **Consultant** in the app
- `created_at` (`timestamptz`, NOT NULL, default `now()`)
- `phone` (`text`, nullable)
- `branch` (`clinic_location`, nullable) — a receptionist's working branch
  right now; NULL for other roles. When they have branches in
  `staff_branches` it must be one of them (trigger
  `tr_guard_staff_working_branch`, error `branch_not_assigned`).
- `deactivated_at` (`timestamptz`, nullable)

### Invoice dates
`tr_guard_invoice_backdate` (migration `20261115100000`) rejects an invoice
dated before today unless the signed-in user is payment staff
(`invoice_can('manage')`), with error `backdate_not_allowed`. Receipts and
refunds are always dated by the server. Seeds and maintenance with no
signed-in user are unaffected.

### `staff_branches`
Which branches a person works at (migration `20261114150000`, applied to
the linked project on November 14, 2026). Primary key
`(staff_id, branch)`; `created_at`, `created_by`. Every active staff member
can read it (pickers list a branch's staff first); nothing is hidden or
blocked by it. Backfilled from `staff.branch`.

### `staff_shifts`
The weekly schedule, one row per shift at one branch: `staff_id`, `branch`
(FK `(staff_id, branch)` → `staff_branches`, ON DELETE CASCADE),
`weekday` (ISO 1–7), `starts_at < ends_at`. Shifts of one person on one day
may touch but not overlap (`staff_shifts_overlap`). Readable by every
active staff member; used only for booking warnings, never to block one.

`create_staff_account` reads `branches` and `shifts` from `new_details`;
`update_staff_account` replaces both when `profile` has a `branches` key and
leaves them alone otherwise. Both call the private `staff_save_branches`
(`staff_schedule_invalid` for bad values) and keep a receptionist's working
branch within their branches (`staff_working_branch`).
`staff_upcoming_at_branch(staff, branch)` (super admins) counts a doctor's
upcoming scheduled visits at a branch, for the warning before removing it.

### `staff_details`
Employment details for one staff member (billing plan slice 7, migration
`20261111170000`, applied to the linked project on November 12, 2026). Kept apart from `staff` because every active staff member
can read the staff directory; active super admins read every row
(`staff_details_admin_read`) and head receptionists (receptionists who
manage payments) read colleagues who share a branch with them
(`staff_details_branch_manager_read`, `current_staff_manages`). There are no
client write policies. The working days and hours columns moved to
`staff_shifts` in `20261114150000`.
- `staff_id` (`uuid`, PK/FK → `staff(id)` ON DELETE CASCADE)
- `national_id` (`text`, nullable, exactly 14 digits, unique when set)
- `birth_date` (`date`, nullable, not in the future)
- `hire_date` (`date`, nullable, after `birth_date`, at most a year ahead)
- `updated_at` (`timestamptz`), `updated_by` (`uuid`, FK → `staff(id)` ON DELETE SET NULL)

Writes go through
`create_staff_account(..., new_details jsonb)` and
`update_staff_account(id, profile, password)` with a `details` key in
`profile`; a profile without that key leaves the details unchanged. Both
call the private `staff_save_details`, so details, profile and password
commit together. Invalid details raise `staff_details_invalid`; a national
ID already used by another staff member raises `staff_national_id_taken`.

### `patients`
Patient registry plus package credit balances.
- `id` (`uuid`, PK, default `gen_random_uuid()`)
- `full_name` (`text`, NOT NULL)
- `phone_number` (`text`, NOT NULL)
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
- `branch` (`clinic_location`, NOT NULL) — where the visit happens
  (migration `20261114150000`; existing rows took the patient's branch).
  `book_recurring_appointments(..., p_branch)` sets it (the dispatcher passes
  `p_branch` from the booking payload); a caller that sends none gets the
  patient's branch (trigger `tr_default_appointment_branch`). It changes
  through `update_appointment_details(..., p_branch)`: allowed while
  `scheduled` with the usual edit permission, afterwards only for super
  admins (`appointment_branch_locked`). Every change is logged in
  `appointment_branch_changes` (`from_branch`, `to_branch`, `changed_by`,
  `changed_at`; management can read it). Transferring a patient never moves
  their visits. Schedule, booking and filter queries use this column; the
  due-patients queue stays on the patient's branch.

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

## 3. Relationships

```text
staff.user_id            -> auth.users.id          (1:1 profile link)
staff                    -> patients.created_by
staff                    -> appointments.created_by
staff                    -> patient_documents.uploaded_by
staff                    -> patient_notes.created_by
staff                    -> patient_medical_history.updated_by
staff                    -> patient_programs.created_by
staff                    -> treatment_plans.created_by
patients                 <- patient_doctors.patient_id   (M:N to doctors)
patients                 <- appointments.patient_id
patients                 <- patient_notes.patient_id
patients                 <- patient_documents.patient_id
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
| `idx_appointment_doctors_doctor_id` | `appointment_doctors` | Doctor appointment joins and schedule queries. |
| `idx_appointment_doctors_appointment_id` | `appointment_doctors` | Appointment doctor list joins and cascades. |
| `idx_appointment_doctors_added_by` | `appointment_doctors` | Audit lookup by creator. |
| `idx_appointments_patient_status_scheduled` | `appointments` | Patient history lookups by status, newest first. |
| `idx_appointments_scheduled_at` | `appointments` | Day/timeline schedule queries. |
| `idx_appointments_created_by` | `appointments` | Appointment author audit lookup. |
| `idx_patient_doctors_doctor_id` | `patient_doctors` | Doctor-assigned patient queries and RLS evaluation. |
| `idx_patients_clinic_next_visit` (partial: `WHERE next_visit_date IS NOT NULL`) | `patients` | Due-patients queue per branch. |
| `idx_patients_phone` | `patients` | Fast patient phone lookup. |
| `idx_patients_full_name_trgm` (GIN trigram) | `patients` | Fast patient name substring and ILIKE searches. |
| `idx_patients_created_by` | `patients` | Patient registration author audit lookup. |
| `idx_patient_documents_patient_id` | `patient_documents` | Patient document gallery retrieval. |
| `idx_patient_documents_uploaded_by` | `patient_documents` | Document uploader audit lookup. |
| `idx_patient_documents_program` | `patient_documents` | Program imaging attachments query. |
| `idx_patient_medical_history_updated_by` | `patient_medical_history` | Medical history editor audit lookup. |
| `idx_patient_notes_patient` | `patient_notes` | Notes listing per patient. |
| `idx_patient_notes_appointment_id` | `patient_notes` | Clinical notes linked to appointments. |
| `idx_patient_notes_created_by` | `patient_notes` | Note author audit lookup. |
| `idx_condition_catalog_region` | `condition_catalog` | Sorted condition catalog retrieval by region. |
| `idx_patient_programs_patient` | `patient_programs` | Program lookups per patient. |
| `idx_patient_programs_created_by` | `patient_programs` | Program author audit lookup. |
| `idx_program_conditions_program` | `program_conditions` | Condition joins per program. |
| `idx_program_conditions_condition_id` | `program_conditions` | Catalog condition references. |
| `idx_treatment_plans_program` | `treatment_plans` | Active plan resolution per program. |
| `idx_treatment_plans_created_by` | `treatment_plans` | Treatment plan creator audit lookup. |
| `idx_plan_modalities_plan` | `plan_modalities` | Modality list per treatment plan. |
| `idx_modality_regions_modality` | `modality_regions` | Target regions per modality. |

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
| `update_appointment_doctors(...)` | Synchronizes appointment doctor assignments. Spinal traction never has a doctor; every other type needs at least one (migration `20261112113000`). |
| `execute_invoice_command` kind `invoice_void_all` | Cancels an invoice and all its active receipts in one transaction with one reason (`invoice_void_with_receipts`), for payments entered by mistake. Refused with `refunds_first` while a refund is active. Migration `20261113120000`, applied to the linked project on November 13, 2026. |
| `remove_service(service_id, version)` | Removes a catalog service for payment staff: deletes it when no invoice line uses it, otherwise sets `active = false` so issued invoices keep it. Returns `{ok, outcome: deleted|hidden}` or `{ok: false, error}`. Migration `20261113090000`, applied to the linked project by hand (SQL editor) on November 13, 2026. |
| `book_recurring_appointments(...)` | Books slots with package balance locking. Rejects doctors on spinal traction and requires one for other types. |
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
| `create_staff_account(...)` | Creates staff with doctor-only senior status and optional reference details atomically; active super admin only. |
| `update_staff_account(uuid,jsonb,text)` | Saves profile/seniority, optional reference details (`profile.details`) and optional password in one transaction; active super admin only. |
| `create_staff_user(...)` | Creates `auth.users` row plus linked active `staff` profile (super admin only). |
| `update_user_password(...)` | Resets a staff user's password (super admin only). |
| `delete_doctor_user(...)` | Deletes a doctor auth user to reject applications (super admin only). |

## 6. Triggers

| Trigger | Fires on | Effect |
| --- | --- | --- |
| `trigger_appointment_package_deduction` | `AFTER INSERT/UPDATE/DELETE` on `appointments` | Reconciles old/new charged state, including type/package changes and deletion. |
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
| `appointments` | Staff with patient access | Management creates; scoped status updates; guarded schedule edits/deletion. |
| `appointment_doctors` | Staff with appointment patient access | Management only. |
| `patient_documents` | Staff with patient access | Staff with patient access (file_name rename only) |
| `patient_notes` | Staff with patient access | Staff with patient access |
| `mutation_receipts`, `document_uploads` | No direct client reads | Checked SECURITY DEFINER RPCs only |
| `storage.objects` (`patient-documents`) | Staff with patient access | Super admin + receptionist + doctors |


## 8. Local review additions (2026-09-06)

Deployment is unverified; see [review results](pre-delivery-review-results.md).

| Function / guard | Contract |
| --- | --- |
| current_staff_has_management_access() | Active admin, receptionist or senior doctor. |
| can_current_staff_edit_appointment(id) | Management, permanent assignment, or covering doctor within the clinic-local edit window. |
| update_patient_details(...) | Demographics and optional doctor assignments in one transaction; preserves balances. |
| update_appointment_details(...) | Schedule/type/package and optional doctor assignments in one transaction. |
| guard_patient_balance_write() | Rejects direct balance changes by doctors; permits nested balance triggers and the invoice commands. |
| guard_appointment_edit() | Protects identity and enforces schedule/delete permission. |

book_recurring_appointments respects cash/package selection,
counts only matching future package reservations and validates the expected
recall date. Assessment appointments do not consume package credits.

Financial constraints require finite positive amounts, a finite total at least
as large as the amount (when present), and nonnegative purchased credits. They
are initially NOT VALID: historical rows require a separate audit/validation.
Self-service staff updates cannot change senior status or other privilege flags.

Current document storage is R2 behind the document-storage Edge Function;
storage.objects policies below describe legacy Supabase object access only.
