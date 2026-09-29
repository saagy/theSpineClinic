# Launch hardening — 29 September 2026

This follow-up addresses confirmed reliability problems and database read costs.
It retains Supabase Free, the existing R2 service and the current two branch values.
Legacy admin reports and unused screens were excluded from speculative rewrites.

## Changes

- Program creates/edits now commit with a durable result receipt. A lost response
  replays the saved result instead of creating another program. The transaction
  returns the complete display model, avoiding a post-save read failure being
  presented as a failed save. Attachments use deterministic child upload IDs.
- Files are validated before saving. If the program saved but a file is uncertain,
  retrying the same details/files reconciles it. A definitive file rejection tells
  the user to open the saved program and add missing files. Failed/uncertain file
  work never deletes a confirmed program. Browser reload requires reselecting files.
- Direct program-edit links load by URL ID and handle loading, errors, missing
  records and patient mismatch. Closing a direct link has a safe navigation fallback.
- Profile saves distinguish a confirmed profile update from an unconfirmed password
  change. Self-service password updates use Supabase Auth. Permission checks stay
  in place, duplicate submissions are prevented and partial success refreshes profile data.
- Appointment permission/balance providers stop accessing Riverpod after disposal.
  Flutter initialization and rendering share a guarded zone.
- Incomplete seeded file paths fail locally with an understandable message.
  Original error stacks and safe diagnostic tags reach Sentry without double-reporting.
  Development, CI and production releases are distinguished.

## Sentry findings

The latest document failures were `400 Invalid objectKey`, followed by duplicate
generic error events. Of 231 document rows, 175 had only a filename; the user
confirmed these were generated test data. They were not deleted. The remaining
paths included 41 legacy Supabase URLs and 15 R2 patient/object keys.

Recent provider failures exposed lifecycle checks now covered by tests. Older
development events also include hot reload, layout and mouse-tracker errors;
they were not all declared fixed or suppressed. Many old web events have no
usable release/source-map information. [Persistent API access](sentry-access.md)
is connected through Windows Credential Manager, with read and release-upload scopes.

## Database growth and measured query work

Read-only inspection found about 16 MiB in the database, 105 patients and 1,111
appointments. Historical query statistics included a 466-call schedule query
averaging 32.6 ms (maximum 169.9 ms); these are historical observations, not a
concurrent-load test or an estimate of end-to-end browser latency.

The significant scaling problem was repeated staff/assignment checks for each
row in patient and appointment reads. Two SELECT policies now evaluate management
access once and use a set of the doctor's accessible patient IDs. Membership
preserves permanent assignment and active appointment assignment semantics.
Write policies are unchanged. A name-order index supports the patient directory.

A local ephemeral PostgreSQL/WASM diagnostic used 10,000 fictional patients,
100,000 appointments and 76 staff. Appointments averaged 150/day, approximating
the combined three-branch volume while using the existing two branch enum values.
Single-run EXPLAIN ANALYZE execution times were:

| Representative read | Before | After |
| --- | ---: | ---: |
| Reception weekly page, 500 rows | 65.8 ms | 13.0 ms |
| Reception appointment count | 2,800.5 ms | 149.3 ms |
| Reception first 30 patients | 10.5 ms | 0.9 ms |
| Ordinary doctor weekly page, 14 rows | 133.6 ms | 21.0 ms |
| Ordinary doctor appointment count | 1,441.0 ms | 46.7 ms |
| Ordinary doctor first 30 patients | 1,355.2 ms | 9.3 ms |

These figures demonstrate reduced query work in that fixture. They do not predict
Supabase Free latency, maximum concurrent users or hosted throughput. They omit
network/browser rendering and the complete clinic workflow. A phone index trial
did not help that diagnostic and was not shipped. Raw aggregate plans and logs
are retained locally under `build/launch-review-20260929/`.

Reproduce the diagnostic from the repo root with the test-only PGlite package:

```sh
node test/review_query_plans.mjs PATH_TO_PGLITE 88609a3 build/query-plans.json
```

The baseline argument must reference a schema before the September 29 read-policy
migration. The script loads it into an ephemeral database, applies the current
read-policy migration and measures both states. It never connects to Supabase.
The due-patient fixture has zero returned rows and is not a useful due-list load
benchmark. A rerun reproduced the direction and approximate scale of the gains.

There is no evidence here requiring a paid plan immediately. Before all branches
depend on the app, run a small real-device, multi-account pilot covering booking,
status changes, payments, programs, uploads and reconnects. Watch actual database
latency, connection usage, disk and transfer as usage grows. The local results
cannot establish a hosted capacity guarantee or a backup/recovery guarantee.

## Validation and rollout

Validation covers interrupted saves, duplicate prevention, rejected attachments,
edit links, partial profile saves, provider disposal and sanitized error reporting.
SQL access-equivalence checks compare the old helper with the new policies for
admin, reception, senior/ordinary/inactive doctors and unauthenticated identities.

The two additive migrations are `20260929010000_program_save_receipts.sql` and
`20260929020000_read_access_query_plans.sql`. The isolated deployment dry run
listed exactly these files; historical migration IDs were not repaired or replayed.
The canonical schema and migration setup paths both pass all ten SQL suites.
Final checks: **370 Flutter tests passed**, **zero analyzer issues**, all ten SQL
suites passed on both setup paths, and the release web build/Wasm dry run passed.
The query-plan diagnostic was rerun successfully. These do not replace real-device
and authenticated multi-operator acceptance checks.

Both migrations were applied to project `ujketpugttdqpcixrnga`. Read-only checks
confirmed the two functions, authenticated-only execution grants, new SELECT
policies, name index and migration history. No clinical records were mutated by
these verification probes. The document-storage Edge Function was not redeployed.

Firebase site `spine-clinic-app` now serves release `spine-clinic@2026.09.29.1`.
Live index, bootstrap and JavaScript SHA-256 hashes match the local build;
`main.dart.js` is `5d444d09672257f548a587fb915cbfb8bb057adf2027999664a816d31bb40a7a`.
The login page renders with no captured warning/error console entries. Staff
should reload existing tabs to receive the update.

Sentry processed the matching private source-map bundle, including 563 application
source files. A labeled synthetic diagnostic event resolved to the expected Dart
file, function, line and source context with no processing errors. SDK/package
source-context warnings remain for non-embedded sources. Maps are excluded from
Firebase; requesting the map URL returns the SPA HTML, not the source map.

Rollback: restore the previous Firebase Hosting release if the web update regresses.
The additive program RPC can remain for compatibility. Reverting read policies
requires restoring the prior policy expressions; do not delete mutation receipts
or re-run historical migrations as a rollback mechanism.
