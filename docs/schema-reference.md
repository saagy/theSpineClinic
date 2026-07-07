# Schema Reference

## Enums

| Type | Values |
| --- | --- |
| `user_role` | `super_admin`, `receptionist`, `doctor` |
| `clinic_location` | `tagamoa`, `masr_elgedida` |
| `appointment_type` | `normal_pt_session`, `spinal_traction_session`, `check_up`, `initial_assessment`, `reassessment` |
| `appointment_status` | `scheduled`, `checked_in`, `completed`, `cancelled`, `no_show` |

## Tables

| Table | Purpose |
| --- | --- |
| `staff` | Clinic personnel, auth link, role, activation, payment permission, branch, phone. |
| `patients` | Patient registry, clinic branch, package balances, creator. |
| `patient_doctors` | Long-term doctor assignments for each patient. |
| `appointments` | Patient visits, type, status, schedule, package use. |
| `appointment_doctors` | Appointment-level doctor assignments and replacements. |
| `patient_documents` | Uploaded document metadata and optional thumbnails. |
| `patient_notes` | Clinical notes, optionally tied to an appointment. |
| `payment_records` | Payment history, due tracking, and package credits. |
| `clinic_settings` | JSONB package configuration. |
| `doctor_replacements` | Daily absence and covering-doctor records. |

## Key Relationships

```text
staff -> patients.created_by
staff -> patient_doctors.doctor_id
staff -> appointments.created_by
staff -> appointment_doctors.doctor_id
patients -> appointments.patient_id
patients -> patient_notes.patient_id
patients -> patient_documents.patient_id
patients -> payment_records.patient_id
clinic_settings.packages -> app ClinicPackage model
```

## Key RPCs

| Function | Purpose |
| --- | --- |
| `get_auth_staff_profile()` | Shared RLS helper for current staff id, role, and active flag. |
| `current_staff_can_manage_payments()` | RLS helper for payment write permission. |
| `create_patient_with_doctors(...)` | Creates a patient and doctor assignments atomically. |
| `update_patient_doctors(...)` | Replaces assigned doctors without leaving a patient unassigned. |
| `create_staff_user(...)` | Creates an auth user plus staff row for admin staff management. |
| `update_user_password(...)` | Lets a super admin update a staff user's password. |
| `delete_doctor_user(...)` | Deletes a doctor auth user and cascades to staff. |
| `book_recurring_appointments(...)` | Books multiple appointment slots in one transaction. |

## Triggered Business Rules

- A patient cannot be left without at least one assigned doctor.
- Completing or checking in a package-backed PT session deducts session balance.
- Completing or checking in a traction session deducts traction balance.
- Reverting a deducted appointment back to scheduled or cancelled refunds the
  correct balance bucket.
- Assessment appointment types never deduct package balance.
- Payment insert/delete operations sync package credits to patient balances.
- Staff email changes sync back to Supabase auth.
- Staff cannot self-promote, deactivate themselves, or grant themselves payment access.
