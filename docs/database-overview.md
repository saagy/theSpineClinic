# Database Overview

The Spine Clinic backend uses Supabase Postgres as the system of record. The
database owns the most important integrity rules: role checks, patient-doctor
assignment safety, package-balance sync, payment-balance sync, and document
storage access.

- Full reference: [Database Schema](database-schema.md)
- Policies & rationale: [Security Model](security-model.md)

## Source of Truth

[`supabase/full_schema.sql`](../supabase/full_schema.sql) is the verified full DDL — run it to recreate the
schema from scratch. Incremental changes live in `supabase/migrations/`:

```text
20260705000000_baseline.sql                              # initial schema
20260705010000_add_payment_receptionist_permission.sql    # can_manage_payments
20260706000000_add_branch_to_create_staff_user.sql        # staff branch field
20260712000000_separate_admin_doctor_identities.sql       # admin/doctor role split
20260713000000_allow_document_rename.sql                  # file_name-only updates
20260713010000_remove_dormant_workflows.sql               # dormant feature cleanup
20260713020000_add_booking_workboard.sql                  # due-queue booking RPC
20260713030000_allow_unfiltered_due_patients.sql          # receptionist queue scope
```

## Main Data Areas

- **Staff**: auth-linked staff records, roles, activation, payment permission,
  branch, and deactivation.
- **Patients**: patient registry, assigned doctors, clinic branch, package
  balances, and next-visit recall dates.
- **Appointments**: visit schedule, appointment type, status, package usage,
  and appointment doctor assignments.
- **Clinical records**: patient notes and uploaded documents.
- **Payments**: payment records, due amounts, and package credits.

## App-Owned Storage

Documents use the private `patient-documents` Supabase storage bucket. The
baseline creates the bucket row if needed and defines storage-object policies
for select, insert, update, and delete access.

## Database Change Workflow

1. Start from the baseline migration and apply every change as a new
   timestamped migration in `supabase/migrations/`.
2. Keep migrations idempotent when practical.
3. After applying a change, update `supabase/full_schema.sql` **and**
   [database-schema.md](database-schema.md) so the canonical reference stays
   truthful — tables, columns, functions, triggers, or policies that changed.
4. Run the SQL sanity scripts after trigger, balance, or permission changes
   (see [Testing](testing.md)).

### Remote baseline verification

Before delivery, link the Supabase CLI to the real project and regenerate or
verify the baseline:

```bash
supabase link --project-ref your-project-ref
supabase db dump --linked --schema public --file supabase/migrations/20260705000000_baseline.sql
```

Back up the remote schema before replacing local baseline files. Do not commit
data-only dumps.
