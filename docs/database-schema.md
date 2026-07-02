# Spine Clinic — Database Schema Reference

> Canonical DDL: `supabase/full_schema.sql`  
> Active DB project: `ujketpugttdqpcixrnga` (Supabase)

---

## Enums

| Type | Values |
|------|--------|
| `user_role` | `super_admin` · `receptionist` · `doctor` |
| `clinic_location` | `tagamoa` · `masr_elgedida` |
| `appointment_type` | `normal_pt_session` · `spinal_traction_session` · `check_up` · `initial_assessment` · `reassessment` |
| `appointment_status` | `scheduled` · `checked_in` · `completed` · `cancelled` · `no_show` |

---

## Tables

### staff
All clinic personnel. Links to `auth.users` via `user_id`.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `id` | `uuid` | NO | `gen_random_uuid()` | PK |
| `user_id` | `uuid` | YES | — | FK `auth.users(id)`, UNIQUE |
| `full_name` | `text` | NO | — | |
| `email` | `text` | NO | — | UNIQUE |
| `role` | `user_role` | NO | — | |
| `is_active` | `boolean` | NO | `true` | Soft-delete/disabling |
| `created_at` | `timestamptz` | NO | `now()` | |
| `phone` | `text` | YES | — | |
| `branch` | `clinic_location` | YES | — | |
| `deactivated_at` | `timestamptz` | YES | — | Disambiguates pending vs deactivated |

**RLS:** Active staff can SELECT all. Users can read/update own row. Only super_admins can modify others. Self-registration allowed with `is_active=false`.

---

### patients
Patient registry. Balance columns are synced by triggers (not direct writes).

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `id` | `uuid` | NO | `gen_random_uuid()` | PK |
| `full_name` | `text` | NO | — | |
| `phone_number` | `text` | NO | — | |
| `program` | `text` | YES | — | |
| `clinic` | `clinic_location` | NO | — | |
| `session_balance` | `integer` | NO | `0` | PT sessions remaining |
| `traction_balance` | `integer` | NO | `0` | Traction sessions remaining |
| `created_by` | `uuid` | YES | — | FK `staff(id)` |
| `created_at` | `timestamptz` | NO | `now()` | |

**RLS:** Super_admins/receptionists have full access. Doctors see only assigned/replacement/appointment patients.

---

### patient_doctors
M:N junction: which doctors are assigned to which patients.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `patient_id` | `uuid` | NO | — | FK `patients(id)`, PK |
| `doctor_id` | `uuid` | NO | — | FK `staff(id)`, PK |
| `assigned_at` | `timestamptz` | NO | `now()` | |

**RLS:** All active staff can read. Only super_admin/receptionist can write.

**Trigger:** `tr_check_patient_has_doctors` — prevents leaving a patient with 0 doctors.

---

### appointments
Scheduled patient visits.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `id` | `uuid` | NO | `gen_random_uuid()` | PK |
| `patient_id` | `uuid` | NO | — | FK `patients(id)` |
| `type` | `appointment_type` | NO | — | |
| `status` | `appointment_status` | NO | `'scheduled'` | |
| `use_package` | `boolean` | NO | `true` | Deduct from balance? |
| `created_by` | `uuid` | YES | — | FK `staff(id)` |
| `created_at` | `timestamptz` | NO | `now()` | |
| `scheduled_at` | `timestamptz` | NO | `now()` | |

**RLS:** All active staff can read/write.

**Trigger:** `trigger_appointment_package_deduction` — auto-deducts/refunds patient balance on status change.

---

### appointment_doctors
M:N junction: which doctors are assigned to which appointments (with soft-delete & replacement tracking).

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `id` | `uuid` | NO | `gen_random_uuid()` | PK |
| `appointment_id` | `uuid` | NO | — | FK `appointments(id)` |
| `doctor_id` | `uuid` | NO | — | FK `staff(id)` |
| `is_replacement` | `boolean` | NO | `false` | Is this a covering doctor? |
| `replaced_doctor_id` | `uuid` | YES | — | FK `staff(id)` |
| `is_active` | `boolean` | NO | `true` | Soft-delete |
| `added_by` | `uuid` | YES | — | FK `staff(id)` |
| `added_at` | `timestamptz` | NO | `now()` | |

**RLS:** All active staff can read/write.

---

### patient_documents
File uploads per patient. Files stored in `patient-documents` storage bucket.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `id` | `uuid` | NO | `gen_random_uuid()` | PK |
| `patient_id` | `uuid` | NO | — | FK `patients(id)` |
| `file_url` | `text` | NO | — | |
| `file_name` | `text` | NO | — | |
| `uploaded_by` | `uuid` | YES | — | FK `staff(id)` |
| `uploaded_at` | `timestamptz` | NO | `now()` | |
| `thumbnail_url` | `text` | YES | — | 320x320 JPEG thumbnail |

**RLS:** Super_admin/receptionist: full access. Doctors: only their own patients' documents. Update: only super_admin/receptionist.

---

### patient_notes
Clinical notes, optionally linked to an appointment.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `id` | `uuid` | NO | `gen_random_uuid()` | PK |
| `patient_id` | `uuid` | NO | — | FK `patients(id)` |
| `appointment_id` | `uuid` | YES | — | FK `appointments(id)` |
| `created_by` | `uuid` | NO | — | FK `staff(id)` |
| `note_text` | `text` | NO | — | |
| `created_at` | `timestamptz` | NO | `now()` | |
| `updated_at` | `timestamptz` | NO | `now()` | |

**RLS:** Same pattern as documents — super_admin/receptionist see all, doctors see their patients.

---

### payment_records
Financial transactions. Balance changes synced to `patients` via trigger.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `id` | `uuid` | NO | `gen_random_uuid()` | PK |
| `patient_id` | `uuid` | NO | — | FK `patients(id)` |
| `amount` | `numeric` | NO | — | |
| `reason` | `text` | NO | — | |
| `recorded_by` | `uuid` | YES | — | FK `staff(id)` |
| `recorded_at` | `timestamptz` | NO | `now()` | |
| `session_balance_added` | `integer` | NO | `0` | |
| `traction_balance_added` | `integer` | NO | `0` | |
| `total_price` | `numeric` | YES | `NULL` | Full service cost. NULL if paid in full. |

**RLS:** All active staff can read. Only super_admin/receptionist can insert/update/delete.

**Triggers:** `trigger_payment_insert_package_sync` (adds balance), `trigger_payment_delete_package_sync` (subtracts balance on delete).

---

### clinic_settings
Single-row configuration store. Packages defined as JSONB array.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `id` | `uuid` | NO | `gen_random_uuid()` | PK |
| `packages` | `jsonb` | NO | — | Array of `ClinicPackage` objects |
| `updated_by` | `uuid` | YES | — | FK `staff(id)` |
| `updated_at` | `timestamptz` | NO | `now()` | |

**RLS:** All active staff can read. Only super_admin can write.

**JSONB structure (`packages`):**
```json
[{
  "name": "6 Sessions",
  "kind": "session" | "traction" | "combined",
  "sessionCount": 6,
  "tractionsCount": 0,
  "price": 1500
}]
```

---

### doctor_replacements
Daily replacement coverage when a doctor is absent.

| Column | Type | Nullable | Default | Notes |
|--------|------|----------|---------|-------|
| `id` | `uuid` | NO | `gen_random_uuid()` | PK |
| `absent_doctor_id` | `uuid` | NO | — | FK `staff(id)` |
| `covering_doctor_id` | `uuid` | NO | — | FK `staff(id)` |
| `replacement_date` | `date` | NO | — | |
| `initiated_by` | `uuid` | YES | — | FK `staff(id)` |
| `created_at` | `timestamptz` | NO | `now()` | |

**RLS:** All active staff can read/create.

---

## Relationships Diagram

```
staff ──┬── patients (created_by)
        ├── patient_doctors (doctor_id)
        ├── appointment_doctors (doctor_id / replaced_doctor_id / added_by)
        ├── patient_documents (uploaded_by)
        ├── patient_notes (created_by)
        ├── payment_records (recorded_by)
        ├── clinic_settings (updated_by)
        └── doctor_replacements (absent/covering/initiated_by)

patients ──┬── patient_doctors (patient_id)
           ├── appointments (patient_id)
           ├── patient_documents (patient_id)
           ├── patient_notes (patient_id)
           └── payment_records (patient_id)

appointments ──┬── appointment_doctors (appointment_id)
               └── patient_notes (appointment_id)
```

---

## Key Functions (RPCs)

| Function | Returns | Called From | Purpose |
|----------|---------|-------------|---------|
| `get_auth_staff_profile()` | TABLE | Internal (RLS) | Returns (staff_id, staff_role, staff_active) for current user |
| `create_patient_with_doctors(...)` | `patients` | Receptionist/Admin screen | Atomic patient + doctor assignments |
| `update_patient_doctors(...)` | void | Patient edit screen | Reassign doctors atomically |
| `create_staff_user(...)` | uuid | Admin → Staff management | Creates auth user + staff record |
| `update_user_password(...)` | void | Admin → Staff management | Updates auth password |
| `delete_doctor_user(...)` | void | Admin → Staff management | Deletes auth user (cascades to staff) |

**All RPCs are `SECURITY DEFINER`** — they run with owner privileges and enforce their own auth checks internally.

---

## Business Rules (Enforced in DB)

1. **Patient must have ≥1 doctor** — `tr_check_patient_has_doctors` constraint trigger blocks any operation that would leave a patient with zero assigned doctors.
2. **Package deduction** — Appointment check-in/completion deducts 1 from the patient's balance (session or traction). Reverting to scheduled/cancelled refunds it. Assessments never deduct.
3. **Payment → balance sync** — Inserting a payment with `session_balance_added > 0` or `traction_balance_added > 0` automatically increments the patient's balance. Deleting the payment decrements it.
4. **Staff self-registration** — New signups insert with `is_active=false`. Super_admin must activate them.
5. **Email sync** — Changing `staff.email` propagates to `auth.users` automatically.
6. **No self-promotion** — Staff cannot change their own `role` or `is_active` status (enforced by `verify_staff_update_permissions` trigger).

---

## Dart Model ↔ Table Mapping

| Dart Model | File | DB Table |
|-----------|------|----------|
| `Staff` | `lib/features/auth/domain/staff.dart` | `staff` |
| `Patient` | `lib/features/patient/domain/patient.dart` | `patients` |
| `PatientDocument` | `lib/features/patient/domain/patient_document.dart` | `patient_documents` |
| `Appointment` | `lib/features/appointment/domain/appointment.dart` | `appointments` |
| `AppointmentDoctor` | `lib/features/appointment/domain/appointment_doctor.dart` | `appointment_doctors` |
| `PaymentRecord` | `lib/features/payments/domain/payment_record.dart` | `payment_records` |
| `ClinicSettings` | `lib/features/payments/domain/clinic_settings.dart` | `clinic_settings` |
| `ClinicPackage` | `lib/features/payments/domain/clinic_package.dart` | (JSONB inside `clinic_settings.packages`) |
| `PatientNote` | `lib/features/medical_records/domain/patient_note.dart` | `patient_notes` |
| *(none)* | — | `doctor_replacements` |

---

## DB Recreation

To recreate the schema on a fresh project:

```bash
# Option 1: Apply the full schema directly
supabase db execute --file supabase/full_schema.sql

# Option 2: Run against a project
psql "$DATABASE_URL" -f supabase/full_schema.sql

# Option 3: Use the Supabase SQL editor
# Paste the contents of supabase/full_schema.sql
```

Then create the `patient-documents` storage bucket (public: false) via the Supabase dashboard.
