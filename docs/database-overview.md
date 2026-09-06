# Database overview

Supabase PostgreSQL owns staff, patient, scheduling, payment, program and
treatment-plan records. Cloudflare R2 stores current document objects;
patient_documents stores metadata. Legacy Supabase storage policies remain.

- [Schema reference](database-schema.md)
- [Security model](security-model.md)
- [Review results](pre-delivery-review-results.md)

## Reproduction and changes

The review replayed all 27 migrations in an isolated PostgreSQL engine and
separately loaded supabase/full_schema.sql. Both passed six SQL scripts.
The harness imitates Supabase-managed auth/storage schemas; this does not
verify hosted configuration or exact parity of every schema detail.

The snapshot is for **fresh recreation**, never for applying to an existing
project. Keep it and schema documentation aligned with new migrations.
Do not overwrite an applied baseline with a new production dump. Compare a
separate schema-only export, reconcile drift and add a new migration instead.

## Review migrations

1. 20260906000000_review_access_boundaries.sql: scoped appointments/payments,
   management assignment writes, direct-balance/appointment guards, grants and
   protection against self-promotion to senior doctor.
2. 20260906010000_review_financial_integrity.sql: charged-state balance sync,
   payment-credit update sync, input constraints and bounded due collection.
3. 20260906020000_review_booking_integrity.sql: package/cash behavior,
   reservation counting, stale due-date guards and atomic booking.
4. 20260906030000_review_atomic_edits.sql: atomic patient/appointment edits
   with assignments, preserving unrelated fields and balances.

Validate in staging before deploying the matching Flutter client, which calls
new edit RPCs. Deploy the document edge function with the reviewed release.
No deployment occurred during the review.

Financial constraints use NOT VALID so historical rows are not silently changed
or assumed correct. Audit invalid values and reconcile balances before validating
constraints. Take backups and test restoration first. See [testing](testing.md).

## Pre-production deployment — 2026-09-06

Applied the four `20260906*` review migrations to project
`ujketpugttdqpcixrnga` with the Supabase CLI. The existing remote migration
versions differ from local historical filenames. Deployment used an isolated
`build/review-deploy` directory: copy the linked `.temp` configuration, fetch
remote migration history, copy only the four new migrations, inspect `db push
--dry-run`, then `db push --yes`. No old migrations or full schema were replayed;
no remote history was marked reverted or repaired. Future deployment must
reconcile history or repeat this isolated approach rather than blindly push
all local historical files.

Live verification: receptionist `update_patient_details` saved the fictional
QA patient while retaining package balances. The `document-storage` edge
function was also deployed. This does not publish the web frontend.
