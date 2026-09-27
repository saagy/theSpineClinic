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

## Upload transport follow-up

After rollout, a JPEG upload produced HTTP 503 without CORS headers. Function
logs at 14:37–14:39 UTC showed repeated uncaught `unexpected end of file` errors
in Deno's `node:http` IncomingMessage stream adapter, including timestamps
matching the gateway 503s. Preflight itself returned HTTP 200 with CORS enabled.

Deployed `document-storage` version **6**, ACTIVE with JWT verification retained.
The shared R2 S3 client now explicitly uses `FetchHttpHandler` 5.8.0 rather than
Node HTTP. Fixed rejection messages are logged without request bodies, filenames,
patient identifiers or credentials to distinguish any remaining HTTP 400 errors.
No database, frontend, account-plan or access-control changes were needed.

Validation: zero Flutter analyzer issues, 12 Node tests, two Deno transport tests
and Deno type checking pass. The new transport tests fail before the fix and pass
after it with outbound network access disabled. Live preflight returns 200 and
anonymous upload access remains 403; both include CORS headers. Downloaded
deployed sources match the local patch. The user retried the same JPEG and
confirmed **Upload succeeded**. The initial HTTP 400 response body was not
available, so that earlier rejection is not attributed to a specific cause.

## Schedule return-refresh follow-up

Published the web-only schedule freshness change to the same Firebase site.
Doctor and reception schedules quietly reload their selected week on a visible
return only when the last successful read is at least 60 seconds old. No polling
or realtime subscription. A refresh keeps rows visible, retains them on failure,
and cannot undo a status change made while it was loading. Rapid return events
coalesce; a failed attempt has a 60-second cooldown before a later return retries.
The receipt migrations and document-storage version 6 remain unchanged.

Validation: zero analyzer issues, all **353 Flutter tests across 88 files** pass,
and the release web build/Wasm dry run pass. Twelve new tests cover freshness,
request/status/branch/week races and simulated browser lifecycle/nested-route/
subtab visibility. Live index, JavaScript and bootstrap files return HTTP 200 and
match the local build byte-for-byte. The sign-in page renders with no captured
browser warnings/errors. These checks do not claim live two-account schedule or
mobile-device acceptance. Existing staff tabs need one reload for the update.

Logs: `build/schedule-return-{tests,web-build,deploy}.log` and
`build/schedule-return-live-verification.json`. Live `main.dart.js` SHA-256:
`e3e8868346b8f9e041d3d0e75117341ff46bf250a3ee057589ee8d8c5a3acee4`.
