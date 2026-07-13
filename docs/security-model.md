# Security Model

Supabase RLS is the primary backend security boundary. The Flutter app also
performs role checks before write actions, but client checks are not trusted as
the only enforcement layer.

## Roles

| Role | Access Model |
| --- | --- |
| `super_admin` | Full administrative access, staff management, and payments. |
| `receptionist` | Operational access for patients, appointments, and documents. Payment writes require `can_manage_payments`. |
| `doctor` | Clinical access to assigned or appointment-related patients. |

## RLS Principles

- Every app table has row-level security enabled.
- Staff access flows through `get_auth_staff_profile()`.
- Inactive staff should not gain operational access.
- Doctors are scoped to patients they are assigned to or booked with through
  active appointment assignments.
- Payment writes are limited to super admins and receptionists with
  `can_manage_payments = true`.
- Document storage policies mirror document metadata access rules.

## Security Fixes Captured In Baseline

- The baseline includes the recurring appointment RPC that was missing from the
  stale full-schema file.
- The storage delete role-cast typo from the stale schema was corrected.
- The patient update policy was tightened so doctor updates follow the same
  patient-access scope as doctor reads instead of allowing a broad update.

## Public Repo Safety

- Do not commit `.env` or service-role keys.
- Do not commit real patient, payment, appointment, or document data.
- Do not publish Supabase project refs in public-facing docs.
- Treat the anon key as browser-public but still keep it out of checked-in
  config files.
