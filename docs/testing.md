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

There are 43 Dart test files. Repository fakes keep widget tests independent
of live services; they do not prove HTTP/RLS behavior. There is no complete
authenticated browser integration suite.

## Document edge handler

With Node 24.12.0:

```sh
node --test test/document_storage_security_test.ts
```

Seven tests call the real handler with fake authorization/storage services.
Coverage includes object-key access, conflicting IDs, mixed-patient deletion,
folder cleanup ordering, malformed inputs, unique keys and errors. This does
not exercise Deno, deployed JWT verification, R2 CORS or the AWS client.

## Isolated PostgreSQL

Install the test-only dependency outside the application:

```sh
npm install --prefix /tmp/spine-review-tools --no-save @electric-sql/pglite@0.5.8
node test/review_database.mjs /tmp/spine-review-tools/node_modules/@electric-sql/pglite
node test/review_database.mjs /tmp/spine-review-tools/node_modules/@electric-sql/pglite --migrations
```

On Windows use a directory under $env:TEMP. The harness accepts no database URL.
It creates an ephemeral database, loads the snapshot or replays migrations,
then runs these six scripts:

- trigger_sanity.sql
- doctor_role_integrity.sql
- patient_document_permissions.sql
- review_access_boundaries.sql
- review_financial_integrity.sql
- review_booking_and_edits.sql

Bootstrap definitions imitate Supabase roles, auth.uid() and storage tables.
Hosted services and multi-connection concurrency require separate staging checks.
Never run fixture scripts against production, even if they include rollback.

## CI and acceptance

.github/workflows/web-review.yml runs analysis, Flutter tests/build, the edge
suite and both database setup paths. It uses placeholder public configuration
and does not deploy. Its first hosted run remains unverified.

See [meeting checklist](client-review-checklist.md) for browser, failure/retry,
recovery and client acceptance checks, and [results](pre-delivery-review-results.md)
for exact local outcomes and limitations.
