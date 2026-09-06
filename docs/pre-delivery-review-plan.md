# Pre-delivery review plan

Review date: 2026-09-06. Scope: the current working tree of the Flutter clinic
application, its SQL migrations, edge function, tests, and deployment files.
This is a practical engineering review, not a penetration-test certification.

## Evidence rules

- Record actual commands and outcomes in `pre-delivery-review-results.md`.
- Distinguish verified behavior, static inspection, confirmed defects, and
  checks blocked by missing environments or accounts.
- Preserve existing uncommitted work. Make focused fixes with regression tests.
- Never use real patient data for test fixtures or mutate a live database.
- Do not deploy, push, or apply production migrations during this review.
- Passing analysis, tests, or a build is not proof of live backend permissions.

## 1. Baseline and reproducibility

1. Record the Git revision, dirty files, Flutter/Dart versions, test inventory,
   installed local database/browser tooling, and available configurations.
2. Run full `flutter analyze --no-pub` and `flutter test --no-pub`.
3. Investigate every failure; distinguish environment failures from defects.
4. Verify generated providers/models match their source when modified.
5. Compile a release web build; check assets and startup configuration.
6. Inspect platform manifests, release signing, hosting, and CI configuration.

## 2. Secrets and patient-data exposure

1. Inspect configuration key names and credential types without printing secrets.
2. Check tracked files and Git history for private credentials and real data.
3. Check bundled environment assets and generated release files for private keys.
4. Inspect error reporting, logging, downloads, signed URLs, and document storage.
5. Verify document upload validation, compensation on failed database writes,
   database-first deletion, and authorization at edge-function boundaries.

## 3. Authentication and authorization

1. Trace sign-in, registration, inactive staff, sign-out, and session restoration.
2. Review router guards, role capabilities, and mutation controller checks.
3. Review RLS, table grants, function grants, SECURITY DEFINER authorization,
   search paths, storage policies, and privilege escalation protections.
4. Compare schema snapshot and incremental migrations for material drift.
5. Exercise role-denial tests locally where supported; record the separate need
   to verify direct API access in staging as anonymous, inactive, receptionist,
   payment-enabled receptionist, ordinary doctor, senior doctor, and admin.
6. Check session/account switching for stale privileged data and async races.

## 4. Financial and scheduling integrity

1. Trace payment recording through form, controller, repository, and SQL triggers.
2. Check amount parsing, bounds, due collection, package credits, and permissions.
3. Check check-in, reversal/refund, cancellation, appointment deletion, and
   assessment exemption from package deductions.
4. Review recurring booking, balances, doctor assignments, branch/date filters,
   Cairo date boundaries, and concurrent edits.
5. Inspect double submission, retries after uncertain network outcomes,
   transaction boundaries, and stale data refreshes.
6. Run existing SQL tests only in an isolated disposable database if available.

## 5. Patient, clinical, and staff workflows

1. Review patient creation/editing/search, assignments, and deletion dependencies.
2. Review clinical history, notes, programs, treatment plans, and senior privileges.
3. Review staff creation/activation/deactivation, privilege changes, and profile edits.
4. Trace critical operations end to end and add regression tests for confirmed bugs.
5. Check data-list pagination/limits and error propagation for misleading totals
   or silent partial results.

## 6. UI and state resilience

1. Run all existing widget tests, including small-screen and sheet interaction tests.
2. Inspect loading/error/empty/data states on critical screens.
3. Check provider dependencies, keepAlive mutation lifecycles, copyWith updates,
   disposal during requests, search debounce, and response ordering.
4. Trace appointment status-change callbacks to every displayed list.
5. Smoke-test browser startup and public authentication UI if browser tooling works.
6. Record authenticated workflows and actual mobile devices still requiring a
   staging walkthrough; do not substitute source inspection for these results.

## 7. Operational readiness

1. Inspect error-monitoring setup and safeguards for sensitive data.
2. Check account recovery gaps and document an owner/admin recovery procedure need.
3. Review backup/restore evidence for both database rows and stored files.
4. Identify deployment, rollback, hosting-account ownership, billing, support,
   retention/export, and incident-response questions for the handover.
5. Add repeatable CI checks when existing automation does not run analysis/tests.

## 8. Fixes and final validation

1. Prioritize unauthorized access, data loss, wrong balances, and broken core flows.
2. Fix confirmed local defects with small, reviewable changes.
3. Run Flutter analysis immediately after code changes, and run relevant tests.
4. Run the full suite and release build on the final candidate when warranted.
5. Update documentation that conflicts with verified code.
6. Produce results with severity, evidence, fixed/open status, exact limitations,
   and a concrete meeting walkthrough.

## Meeting walkthrough and acceptance gates

Use fictional data and the same release candidate that passed validation.

1. Sign in with each role; demonstrate permitted and denied actions.
2. Create a patient, assign a doctor, and book a normal and assessment visit.
3. Record a package payment; verify before/after balances and due collection.
4. Check in, reverse, and cancel a session; verify credits change exactly once.
5. Add a clinical note, program, treatment plan, and document; verify role scope.
6. Refresh/deep-link, switch accounts, and deactivate an already-signed-in account.
7. Simulate a failed/slow save and two simultaneous operators in staging.
8. Demonstrate backups and an isolated restore, including uploaded documents.

Delivery blockers: reproducible unauthorized patient access, exposed private
credentials, unexplained wrong balances, data loss, broken essential workflows,
or no established recovery path. Untested critical backend behavior remains an
open release gate. Cosmetic improvements and documented nonessential features
can be scheduled after acceptance with the client.
