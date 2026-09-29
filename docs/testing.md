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
schedule-cap/count, durable retry, upload reconciliation, booking-role/bundle,
pending-booking balance guards and bounded-cache regressions.
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
then runs these ten scripts:

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

Bootstrap definitions imitate Supabase roles, auth.uid() and storage tables.
Hosted services and multi-connection concurrency require separate staging checks.
Never run fixture scripts against production, even if they include rollback.

The default runner covers all ten scripts above on either setup path.
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
