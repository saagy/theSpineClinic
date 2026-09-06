# Hands-on browser review



2026-09-06. Local release web build connected to the configured pre-production

Supabase project. User authorized fictional writes and subsequently authorized

migration/edge-function deployment. Credentials are not stored here.



## Passed hands-on checks



- Login, required-field and malformed-email validation.

- Patient creation/search; required fields and nonnumeric phone validation.

- Mixed Arabic/English/emoji names; rapid double-save created only one patient.

- Negative payment rejected; partial payment and outstanding collection persisted;

  collection above the remaining due was rejected.

- Appointment booking/check-in; package credits deducted in the database.

- Empty note rejected; multiline Arabic/symbol note saved and reopened.

- PDF uploaded, opened at phone width and renamed persistently.

- Main receptionist flows exercised at desktop and 375px phone viewport widths.



## Confirmed fixes



- Patient editing initially failed because the local client required an unapplied

  RPC. All four review migrations are now applied. A live receptionist RPC edit

  of the fictional patient succeeded without changing its package balances.

- Doctor selector cleared through list aliasing on form save: shared field now

  passes copies; a widget regression saves twice and retains the selection.

- Patient header kept stale balances after appointment status changes: both

  appointment action paths now invalidate the patient detail provider.

- Reloading a protected URL lost the destination during authentication loading:

  splash now retains the URL and rechecks role access before restoration.

- Browser payment timestamp was three hours ahead: local DateTime serialization

  omitted the timezone. Payment JSON now always emits UTC. Existing historical

  timestamps were not bulk-shifted because their provenance is not established.

- Document object access safeguard deployed to Supabase, including authorization

  based on the object's patient rather than a separate caller-supplied ID.



## Follow-up observations and limits



- Two transient Flutter web null-value exceptions occurred during text-input

  interactions. The app recovered. Root cause and reproducibility remain

  unestablished; no speculative engine change was made.

- The first document picker attempt did not open; the Quick Actions upload flow

  worked. Not established as a reproducible application defect.

- Senior doctor can read the fictional patient; unassigned regular doctor cannot

  (live API checks). This is not a complete walkthrough of both doctor UIs.

- These are focused checks, not a load test, penetration test or guarantee of

  compatibility with every physical phone/browser. Frontend changes are local

  until the new web build is published.



## Fixture ledger



Only the review's fictional records were intentionally changed.



- Patient `303be71e-e269-4898-84a3-69f68fa571bf`, name begins `QA REVIEW 0906`,

  assigned Sagy Tamer at Tagamoa; program now `QA REVIEW - edit verified`.

- Diagnostic payment 100 EGP, +2 PT/+1 traction; browser payment initially

  20/50 EGP, then remaining 30 collected. Total paid 150 EGP; due zero.

- One Sep 6 09:00 PT appointment checked in; remaining PT 1, traction 1.

- One clearly labeled fictional multiline note.

- One fictional PDF renamed `QA renamed document.pdf`.



## Verification



- Final Flutter analysis: zero issues.
- Release web build: passed; output in `build/web`. Frontend not published.
- Post-deployment dry run: remote database up to date for the isolated rollout.

- Final Flutter suite: 161 tests passed (43 test files), including timezone

  round-trip, authenticated deep-link restoration and role guard regressions.

- Document handler suite: all 7 tests passed.

- Live deployment: all 4 review migrations and document-storage function applied.

- Live document check: receptionist downloaded the QA PDF; unassigned regular

  doctor received HTTP 403 for its object key.

- Live patient edit passed; senior doctor read allowed, unassigned doctor read

  denied. Final UI balance/selector fixes are not claimed as browser-retested.

- Two transient browser exceptions remain untriaged; they did not prevent the

  completed flows. This review does not claim every issue is fixed.

