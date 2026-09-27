# Production rollout — 27 September 2026

The user authorized applying the hardening changes, committing and pushing.

## Backend applied

Supabase project: `ujketpugttdqpcixrnga` (`the spine`).

- Applied `20260927010000_mutation_receipts.sql`.
- Applied `20260927020000_document_upload_receipts.sql`.
- Deployed `document-storage` version **5**, status ACTIVE, JWT verification enabled.
- Downloaded all four deployed TypeScript files and compared them with the local
  sources; they match exactly.
- Post-deployment dry run reports the isolated rollout is up to date.
- All four new RPCs are present and deny anonymous execution with SQLSTATE 42501.
- The new tracked-upload endpoint denies anonymous patient access with HTTP 403.

The rollout used `build/production-deploy-20260927`: copied the linked connection
configuration, fetched actual remote migration history, then added only the two
new migrations. The dry run listed exactly those two files. No historical SQL
was replayed and no migration history entries were repaired or marked reverted.

The recorded September 6 access/financial/booking dependencies match the local
versions when whitespace is ignored. Full live database lint reports no new
errors. The pre-existing unrelated `seed_clinic_schedule_range` ambiguity remains
unchanged. A separate attempt to replay fetched historical SQL in an ephemeral
database hit invalid syntax in the recorded baseline; this history is not a
reproducible schema backup. The repository's canonical schema and 31-migration
path both pass all eight local SQL suites.

## Web release

Firebase project and site: `spine-clinic-app`.
URL: https://spine-clinic-app.web.app/

The release is built with `--dart-define-from-file=.env`. The file contains only
the public Supabase URL/anonymous key and Sentry DSN, and is excluded from Git.
The previous Firebase version is `92488bebd7677931`; it is retained by Hosting.
Published Firebase version `f1969f7508bbe116`, release `1790519590751000`,
with status FINALIZED. The live `index.html`, `main.dart.js` and
`flutter_bootstrap.js` return HTTP 200 and their SHA-256 hashes match the local
release build. The sign-in screen renders in the browser with no captured
console warnings or errors. Existing staff tabs need a reload to use the update.

## Verification boundary and rollback

Local verification: zero analyzer issues, 341 Flutter tests, 11 Node tests,
eight SQL suites against both canonical setup paths, Deno type check and release
web build. Deployment probes did not create clinical data or exercise authenticated
staff payment/booking/upload flows, real R2 uploads, device compatibility or load.
Those acceptance checks remain separate from this deployment.

The previous Edge Function sources are saved in the ignored rollout directory
under `supabase/functions/document-storage`. Restore the previous web release
first if a rollback is needed; the old client remains compatible with the new
additive database schema and function's legacy upload action. Keep receipt tables
and RPCs intact so unknown in-flight operations can still reconcile. Do not drop
receipt data as part of a rollback.

Implementation and ongoing constraints: [production hardening](production-hardening.md).
