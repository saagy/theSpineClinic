# Security Model

Supabase RLS is the primary backend security boundary. The Flutter app also
performs role checks before write actions (via `currentUserProvider`), but
client checks are never trusted as the only enforcement layer.

## Roles

| Role | Access Model |
| --- | --- |
| `super_admin` | Full administrative access: staff management, patient registry, payments, documents, and clinic-wide analytics. |
| `receptionist` | Operational access for patients, appointments, and documents. Payment writes additionally require `can_manage_payments = true`. |
| `doctor` | Clinical access, scoped to patients they are assigned to or booked with through an active appointment assignment. |

## Enforcement Layers

1. **Row-Level Security on every table.** All eight app tables and the
   documents storage bucket have RLS enabled. Policy summary:
   [Database Schema §7](database-schema.md#7-row-level-security-summary).
2. **RLS helper functions.** Every policy resolves the caller through
   `get_auth_staff_profile()` (`staff_id`, `staff_role`, `staff_active`), so
   inactive staff lose operational access everywhere at once. Payment writes
   go through `current_staff_can_manage_payments()`.
3. **Permission-checked RPCs.** Sensitive writes run inside `SECURITY DEFINER`
   functions that re-verify the caller's role and active status before acting
   (e.g. `create_patient_with_doctors`, `book_recurring_appointments`,
   `bulk_replace_appointment_doctor`, `create_staff_user`).
4. **Integrity triggers.** Database triggers enforce business invariants that
   RLS cannot express: package balance deduct/refund on status transitions,
   payment-credit sync, no-patient-without-doctor, doctor-role guarantees on
   assignments, and self-service privilege escalation prevention
   ([Database Schema §6](database-schema.md#6-triggers)).
5. **Column-level grants.** `patient_documents` updates are revoked at table
   level and re-granted for `file_name` only; storage-object rename is limited
   to super admins and receptionists.
6. **Scoped storage paths.** Object paths are prefixed with the patient id, and
   storage policies scope doctor access through `path_tokens[1]`.

## Staff Application Flow

New staff self-register as **inactive** profiles (`is_active = false`, role
restricted to `doctor` or `receptionist`). A super admin reviews and activates
them, or rejects them via `delete_doctor_user()`. Until activation the profile
grants no operational access.

## Public Repo Safety

- Do not commit `.env` or service-role keys.
- Do not commit real patient, payment, appointment, or document data.
- Do not publish Supabase project refs in public-facing docs.
- Treat the anon key as browser-public but still keep it out of checked-in
  config files.
