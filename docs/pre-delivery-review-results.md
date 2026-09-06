# Pre-delivery review results

Date: 2026-09-06. Target: web on PCs and phones.
Scope: local working tree based on 9f99b56d263b404cf597c3ec4cc85b093e72d0e6.
Existing Sentry/configuration changes were preserved; review fixes are uncommitted.

## Decision

**Ready for an engineering review; not yet approved for client handover.**
Confirmed access-control and financial bugs were fixed locally and regression
tested. Production deployment, authenticated browser acceptance, recovery and
the open issues below remain gates. Passing tests cannot guarantee that another
engineer will find no defects or that the client will accept the application.

The user confirmed there is only one Supabase project. We did not insert
fixtures into it, apply migrations, deploy the edge function, push code or
change live accounts. No production patient records were accessed for this review.

## Evidence

| Check | Outcome / limit |
| --- | --- |
| Flutter analysis | Final analysis: zero issues. |
| Flutter unit/widget suite | 156/156 passed across 41 Dart test files. |
| Release web build | Final release build passed (124.1 seconds compilation); Wasm dry run passed. |
| Edge handler | 7/7 Node tests passed using fake authorization and object services. |
| Schema snapshot | Loads successfully; all 6 SQL scripts pass. |
| Incremental migrations | All 27 replay successfully; the same 6 scripts pass. |
| Public UI | Login at desktop size and registration at 375Ã—812 visually checked; empty required fields reject locally. |
| Browser configuration | Source and built .env contain only URL, anon-role JWT and Sentry DSN. |
| Secret inspection | Focused private-key/config inspection found no private key in examined material; not an exhaustive historical secret audit. |
| CI | Added web-review.yml; local commands validated, hosted workflow not run. |

SQL tests execute actual PostgreSQL in PGlite 0.5.8, with stand-ins for Supabase
auth/storage schemas. They do not test GoTrue, PostgREST, deployed grants,
R2, true multi-connection races or production data. The two setup paths pass
the tested behaviors; exact catalog equivalence was not established.

Toolchain: Flutter 3.44.1, Dart 3.12.1, Node 24.12.0. Reproduction commands and
test boundaries are in [testing](testing.md). Build/test logs are under build/.

## Confirmed defects fixed locally

| Priority | Before | Change and evidence |
| --- | --- | --- |
| High | A caller could provide an accessible patient ID while requesting another patient's object key. | Edge authorization now derives patient from the key and rejects mismatch; targeted IDOR regression passes. |
| High | Broad appointment-assignment writes let a doctor self-assign to unrelated patients and gain access. | Management-only assignment writes and scoped appointment policies; SQL denial regression passes. |
| High | Migration history did not retain the snapshot's senior-flag protection. | Restored guard prevents ordinary doctors promoting themselves; replay test passes. |
| High | Appointment type/package edits and deletion could leave incorrect charged balances. | Old/new charged-state reconciliation, insufficient-credit checks and SQL tests for insert/update/delete/reversal. |
| High | Patient/appointment edits used separate requests; stale patient payloads could overwrite balances. | Atomic edit RPCs include assignments; demographic edits preserve balances; rollback tests pass. |
| High | Recurring booking ignored package selection and lost expected due-date protections. | Respects cash/package, validates stale dates and counts matching reservations; SQL tests pass. |
| High | Due collection allowed excessive collection; payment-credit edits did not synchronize balances. | Locked bounded collection, credit-delta update trigger and finite/positive constraints; SQL tests pass. |
| Medium | Mutation controllers could be disposed during unobserved async work. | Action controllers use generated keepAlive providers; permanent permission errors avoid retry delays. |
| Medium | Failed sign-out cleared app state as if sign-out succeeded. | Failure preserves session and reaches UI; success/failure tests pass. |
| Medium | Document cache could survive account changes; auth logs exposed identity details. | Repository dependency follows session; removed identity logs and sanitized custom error reporting. |
| Medium | Legacy signed document links retained query tokens in object lookup. | Strip query/fragment before decoding; three path tests cover signed URLs/raw keys/malformed encoding. |
| Medium | Storage request validation and cleanup errors were inconsistent. | Validate keys/types/actions; unique keys; authorize all deletion targets first; reject folder cleanup before DB deletion; detect partial R2 deletion failures. |
| Medium | Baseline SQL had incomplete policy syntax. | Repaired eight policy terminators; complete migration replay now succeeds. |

The client now requires the new edit RPCs. Deploying only Flutter will break
those edits. Changes are not evidence that the currently hosted application is
already fixed. See [database overview](database-overview.md) for migration order.

## Open release gates and findings

1. **High â€” live access and deployment remain unverified.**
   Create an isolated Supabase/R2 test environment, apply the reviewed candidate,
   then test every role directly through the API and UI. Include inactive users,
   guessed patient/document IDs, role changes and already-open sessions.
   Compare live schema/ACLs with migrations before planning production rollout.

2. **High â€” uncertain network outcomes can duplicate financial operations.**
   Payment inserts have no stable retry/idempotency key. Due collection is
   bounded and atomic but repeated valid retries can still collect twice.
   Add durable operation IDs and test dropped responses/two operators.
   Sources: payment_repository_impl.dart and collect_payment_due.

3. **High â€” report totals can silently truncate at configured API row limits.**
   admin_report_sources.dart and analytics helpers fetch unpaginated row lists.
   Aggregation needs SQL RPCs or verified complete pagination, plus a >1,000-row
   fixture. Supabase documents a default 1,000-row response maximum; the actual
   project setting was not inspected. [Supabase select reference](https://supabase.com/docs/reference/javascript/v1/select)

4. **High â€” upload timeout/compensation can leave ambiguous outcomes.**
   PatientDocumentsRepositoryImpl applies Future.timeout without cancelling the
   operation. It may finish after failure is shown; a lost insert response can
   also trigger deletion of an object whose metadata committed. Add operation
   reconciliation before retries or compensation, and test slow/dropped responses.

5. **High â€” recovery is not demonstrated.**
   Establish database and R2 backup retention and restore both in isolation.
   A database backup alone excludes stored file objects. Record recovery owner,
   recovery-time target and credentials handover.
   [Supabase backup scope](https://supabase.com/docs/guides/platform/backups)

6. **Medium â€” anonymous registration needs abuse and identity review.**
   The RPC directly creates auth rows. Confirm supported Auth creation behavior,
   server password requirements and rate/abuse controls before exposing signup.
   Frontend recovery is absent; agree on an admin recovery procedure.

7. **Medium â€” some profile/password edits are sequential.**
   A password update may succeed before a later profile update fails. Make the
   account workflow transactional where possible or explicitly reconcile/report
   partial success; test both failure orders.

8. **Medium â€” patient-read and covering-doctor edit windows differ.**
   SQL patient access can persist through active appointment assignments beyond
   the UI edit window. Agree on intended historical/cancelled appointment access
   and enforce it consistently. Verify revocation of already-open UI caches.

9. **Medium â€” documents need hosted end-to-end and resource checks.**
   Deno type checking, deployed JWT validation, R2 signing/CORS, full upload/open/
   rename/delete, oversized uploads and malformed file content remain untested.
   Signing does not enforce the client 10 MB limit. Cache limits are count-based,
   so phone memory pressure needs testing. Issued download URLs last 15 minutes.

10. **Medium â€” audit existing data and mutation feedback.**
    New financial constraints are NOT VALID until historical rows are checked.
    Reconcile existing balances. Some legacy update/delete calls do not verify
    affected rows and may appear successful after a no-op. Confirm patient
    hard-delete semantics and whether an audit trail is required. Check-in now
   rejects insufficient credits; confirm that policy for existing debt accounts.

11. **Medium â€” patient privacy and operational ownership need sign-off.**
    Inspect complete Sentry events/breadcrumbs with fictional data; custom
    sanitization does not cover every automatic event. Confirm client ownership,
    billing, retention/export, support, recovery access and incident contact.

12. **Low â€” architecture and documentation debt remains.**
    Legacy files exceed the 200-line guideline and some data helpers lack the
    desired repository interface/Result structure. Registration is already a
    two-step form; its stale deferred-task note was corrected. README readiness
    guarantees and storage documentation were narrowed to verifiable claims.

## What was not demonstrated

Authenticated clinical and payment flows in a real browser; actual iPhone/
Android Safari/Chrome; keyboard/screen-reader accessibility throughout the app;
load/performance at clinic volume; backup restore; offline/reconnect behavior;
fresh hosted CI; full dependency/CVE or historical secret scanning; legal or
health-data compliance certification. These are explicit limits, not passes.

Use the [meeting checklist](client-review-checklist.md) to assign owners and
record observed acceptance results. Do not enter real patient data into a demo.

## Final verification

Final candidate: flutter analyze --no-pub passed with zero issues; flutter test
--no-pub --coverage passed 156/156; flutter build web --release --no-pub passed.
The seven edge tests and six SQL scripts on both setup paths passed. git diff
--check passed. Review-document local links were checked. Browser smoke checks
used the preceding release build; the final change only localizes sign-out error
text. No live deployment, push or production fixture writes occurred.

Local logs: [Flutter tests](../build/review-flutter-tests.log),
[release build](../build/review-web-build.log),
[coverage](../coverage/lcov.info). These generated files are Git-ignored.


## Subsequent authorized deployment and hands-on verification

The earlier sections describe the original local-only review. On 2026-09-06,
the user authorized fictional pre-production writes and later deployment.
The four review migrations and document-storage function are now deployed;
patient editing and document authorization passed live checks. See the
[hands-on report](hands-on-browser-review.md) for current fixes, 161 passing
Flutter tests, fixture records and remaining limitations.
