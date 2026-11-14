# Testing

The review combines Flutter unit/widget tests, a pure edge-handler suite and
SQL tests in ephemeral PostgreSQL (PGlite). Automated suites do not write live data.
The separately authorized pre-production browser/API checks use one fictional
patient; see [hands-on review](hands-on-browser-review.md).

## Flutter

Validated toolchain: Flutter 3.44.1 / Dart 3.12.1.

```sh
flutter analyze --no-pub
flutter test --no-pub --coverage
flutter build web --release --no-pub
```

As of 27 September 2026, there are 88 Dart test files and 353 passing tests. The hardening suite covers
schedule-cap/count, durable retry, upload reconciliation, booking-role,
pending-booking balance guards and bounded-cache regressions.
The invoice detail slice (11 November 2026) adds
`test/features/payments/invoice_rules_test.dart` (document parsing, action
rules, refund arithmetic from the billing plan, command payloads, route guards
and PDF rendering), `invoice_detail_test.dart` (payment, void, lock messages,
refund, correction and failure paths through real routing) and
`test/previews/invoice_detail_render_test.dart`. Removing the pilot and legacy
payment code (slice 5) retired their tests; the full suite is 588 tests.
The billing reports slice (11 November 2026) adds
`test/features/payments/billing_reports_test.dart` (periods, request
parameters, report parsing, PDF rendering, filters, the doctor
requirement, row navigation, expansion, paging, capped rows, empty, failure
and denied states) and `test/previews/billing_reports_render_test.dart`; the
full suite is 604 tests. CSV export was removed on November 12, 2026 (the
suite is now 624 tests). The print dialog and the shared date-range picker
(`showAppDateRangePicker`) are not exercised by tests.
The staff reference details slice (12 November 2026) adds
`test/features/auth/staff_details_test.dart` (database shape, directory
schedule text, loading saved details, unchanged details not resent, changed
details saved, validation, failed load with Retry, creation) and
employment-details captures in `test/previews/staff_editor_render_test.dart`;
the full suite is 617 tests. The native date and time pickers are not
exercised by tests.
The staff branches slice (14 November 2026) adds
`test/features/staff/staff_schedule_rules_test.dart` (shift order and
overlap, schedule mismatch for bookings, branch-first doctor picker rows,
head-receptionist access, the patient identity line), reworks
`staff_details_test.dart` around branches and the weekly schedule, and adds
`test/previews/staff_profile_render_test.dart`,
`patient_record_render_test.dart` and `booking_branch_render_test.dart`;
the full suite is 680 tests.
The billing freshness follow-up (14 November 2026) adds
`test/features/payments/billing_freshness_test.dart` (invoice commands reload
open reports, Billing reloads on return and resume, reloaded tables keep page
and open rows, the invoice's patient link from Billing and its absence over
the patient page, workspace tab order by role) and an entry case in
`refresh_on_return_test.dart`; the full suite is 649 tests.
The return-refresh follow-up adds 12 tests covering the 60-second boundary,
no polling, concurrent returns, failed refresh retention/cooldown, local status
races, independent week ages, branch changes, browser lifecycle events and
nested-route/subtab visibility. Lifecycle events are simulated in widget tests;
these are not a two-account live browser acceptance test.
The full run is logged in `build/schedule-return-tests.log`.
Repository fakes keep widget tests independent
of live services; they do not prove HTTP/RLS behavior. There is no complete
authenticated browser integration suite.

## Document edge handler

With Node 24.12.0:

```sh
node --test test/document_storage_security_test.ts test/document_upload_recovery_test.ts
```

Twelve tests cover the handler and tracked-upload recovery with fake services,
including tracked JPEG validation and CORS on rejected metadata.
Coverage includes object-key access, conflicting IDs, mixed-patient deletion,
folder cleanup ordering, malformed inputs, unique keys and errors. This does
not exercise deployed JWT verification, R2 CORS or the AWS client.
`deno check supabase/functions/document-storage/index.ts` also passes locally.

Run the actual R2 SDK transport with synthetic configuration and mocked native
fetch (Deno 2.9.6; outbound network access deliberately disabled):

```sh
deno test --allow-env --allow-sys test/document_storage_transport_test.ts
```

Two tests cover HEAD 404/200/403, listing/deletion and upload URL signing. They
fail if the client switches back to Node HTTP, which crashed deployed Deno
workers on R2 replies. CI runs these checks alongside the Node handler tests.

## Isolated PostgreSQL

Install the test-only dependency outside the application:

```sh
npm install --prefix /tmp/spine-review-tools --no-save @electric-sql/pglite@0.5.8
node test/review_database.mjs /tmp/spine-review-tools/node_modules/@electric-sql/pglite
node test/review_database.mjs /tmp/spine-review-tools/node_modules/@electric-sql/pglite --migrations
```

On Windows use a directory under $env:TEMP. The harness accepts no database URL.
It creates an ephemeral database, loads the snapshot or replays migrations,
then runs these scripts:

- trigger_sanity.sql
- doctor_role_integrity.sql
- patient_document_permissions.sql
- review_access_boundaries.sql
- review_financial_integrity.sql
- review_booking_and_edits.sql
- empty_patient_deletion.sql
- production_retry_integrity.sql
- program_save_integrity.sql
- read_access_equivalence.sql
- invoice_fixture.sql + invoice_workflow.sql (catalog, issuing permissions,
  discounts, receipts, the three refund examples, line allocations, retries)
- invoice_fixture.sql + invoice_corrections.sql (voids, corrections, the
  refund barrier, booked-session protection, request resolution)
- staff_seniority_management.sql and staff_reference_details.sql (admin-only
  detail reads, atomic saves with the profile, validation, unique national
  IDs, unchanged behavior for callers that send no details)
- staff_branches.sql (split weeks, touching versus overlapping shifts,
  shifts at unassigned branches, working branch moved when its branch is
  removed, receptionists kept within their branches, head-receptionist
  detail reads by shared branch, booking with and without `p_branch`,
  transfers leaving visits in place, the branch lock after check-in and the
  change log)
- invoice_fixture.sql + invoice_discounts.sql (discounts after issue:
  permissions, the split between lines, payback, own number series, the
  invoice keeping its number and receipts, the refund barrier, cancelling,
  money and revenue reports, 100% discounts)
- invoice_fixture.sql + invoice_reports.sql (report access, money totals and
  void log, revenue, exact doctor shares, outstanding balances, services)
- invoice_fixture.sql + doctor_session_report.sql (doctor sessions access,
  checked-in counts per type, shared sessions, traction and cancelled
  appointments left out, pending appointments, branch and doctor filters)

`invoice_fixture.sql` opens a transaction that the following invoice test
rolls back, so always pass the pair together when running a subset.

Check the destructive invoice demo seed only in the ephemeral database:

```sh
node test/review_database.mjs <pglite> test/invoice_seed_setup.sql \
  supabase/seed_invoice_demo.sql supabase/seed_invoice_demo_events.sql test/invoice_seed_check.sql
```

Bootstrap definitions imitate Supabase roles, auth.uid() and storage tables.
Hosted services and multi-connection concurrency require separate staging checks.
Never run fixture scripts against production, even if they include rollback.

The default runner covers all scripts above except the seed check, on either
setup path.
Pass explicit SQL filenames after the package path (or after `--migrations`)
to run a focused subset.

The [27 September assessment](production-readiness-2026-09-27.md) records current
verification, live read-only observations and separate synthetic scale diagnostics.

Final local hardening checks: zero analyzer issues, release web build and Wasm
check pass, 11 Node tests pass, and all eight SQL suites pass against both the
schema snapshot and the complete 31-migration replay. Deno type checking passes.
Logs are in `build/production-hardening-{analyze,tests,web-build,edge-check,edge-tests,sql-snapshot,sql-migrations}.log`.
See the [rollout record](production-rollout-2026-09-27.md) for live deployment
checks. Authenticated PostgREST/R2 concurrency and full device/load acceptance
remain pending.

## CI and acceptance

The [September 29 follow-up](launch-hardening-2026-09-29.md) adds regression
coverage for program/save attachment recovery, edit links, partial profile saves,
permission-provider disposal, invalid seeded paths and useful sanitized Sentry
events. Current run logs are under `build/launch-review-20260929/`.
The full suite passes 370 tests, with zero analyzer issues and ten SQL suites
passing against both setup paths. Release build and live sign-in smoke checks pass.
Private Sentry source-map symbolication and source context were verified with a
labeled synthetic event; this is not a real user crash or authenticated workflow test.

.github/workflows/web-review.yml runs analysis, Flutter tests/build, the edge
suite and both database setup paths. It uses placeholder public configuration
and does not deploy. Its first hosted run remains unverified.

See [meeting checklist](client-review-checklist.md) for browser, failure/retry,
recovery and client acceptance checks, and [results](pre-delivery-review-results.md)
for exact local outcomes and limitations.
