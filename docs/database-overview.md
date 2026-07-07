# Database Overview

The Spine Clinic backend uses Supabase Postgres as the system of record. The
database owns the most important integrity rules: role checks, patient-doctor
assignment safety, package-balance sync, payment-balance sync, and document
storage access.

## Source of Truth

Active baseline and DDL files:

```text
supabase/migrations/20260705000000_baseline.sql
supabase/full_schema.sql
```

The schema has been 100% verified against the active Supabase project (`ujketpugttdqpcixrnga`).
Future database changes should be added as new migrations after `20260705000000_baseline.sql`.

## Main Data Areas

- Staff: auth-linked staff records, roles, activation, payment permission, branch, and deactivation.
- Patients: patient registry, assigned doctors, clinic branch, and package
  balances.
- Appointments: visit schedule, appointment type, status, package usage, and
  appointment doctor assignments.
- Clinical records: patient notes and uploaded documents.
- Payments: payment records, due amounts, and package credits.
- Admin settings: package configuration stored as JSONB.
- Coverage: daily doctor replacements.

## App-Owned Storage

Documents use the private `patient-documents` Supabase storage bucket. The
baseline creates the bucket row if needed and defines storage-object policies
for select, insert, update, and delete access.

## Remote Project Verification

All DDL definitions, table constraints, foreign key delete rules (`ON DELETE CASCADE`,
`ON DELETE SET NULL`, `ON DELETE RESTRICT`), RPC functions, triggers, and RLS policies
have been directly queried and synchronized with live Supabase project `ujketpugttdqpcixrnga`.
