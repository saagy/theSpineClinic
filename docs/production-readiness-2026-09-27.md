# Production readiness assessment — 27 September 2026

**Decision: hold broad client rollout until the correctness and recovery gates below pass.**
The expected workload is reasonable for Flutter web, Supabase and private R2.
The initial audit reproduced data-completeness defects and identified retry risks.
Buying more capacity will not correct those defects. A rewrite is not indicated by this review.

Scope: working tree at `c2fdca7`, browser launch on PCs and phones; native apps are future work.
Reviewed code, ran local checks and performed read-only linked-project inspection.
The initial audit changed no live services. [Authorized fixes](production-hardening.md) are implemented; see the [rollout record](production-rollout-2026-09-27.md) for deployment status and validation limits.

Follow-up scope: the user will replace the entire admin workflow, so fixes to its
reports/analytics are deferred to that replacement. Operational appointment counts
and pagination remain in scope. Stay on Supabase Free; use R2's free allowance until exceeded.
Thumbnails are explicitly excluded. The planned third branch is Madinaty; timing is undecided.

## Expected workload

| Input | Planning interpretation |
| --- | --- |
| Three branches; 15–25 doctors and 3–5 receptionists each | 54–90 staff accounts, plus administrators; account count is not simultaneous request count. |
| 40–50 appointments/day/branch | 120–150/day overall; 3,120–3,900/month at 26 working days; 37,440–46,800/year. |
| One new branch acquired 100 patient files/month | If all three match that rate: 300 new files/month, 3,600/year. This is a scenario, not an established forecast. |
| Usually one program, 0–10 notes, sometimes up to about five scan images | Text/metadata is relatively small; image size and how often files are reopened drive storage, bandwidth and browser memory. |

Recurring patients increase appointments and clinical history without necessarily increasing
patient count. Test with a year or two of appointments, not only new patient records.

## Initial audit evidence (before the complete hardening patch)

| Check | Result and boundary |
| --- | --- |
| `flutter analyze --no-pub` | Zero issues on final run. |
| `flutter test --no-pub --reporter expanded` | Initial audit: 319/81 files. After the bounded-cache change: 327 tests pass across 82 files. Most HTTP is replaced by fakes. |
| `flutter build web --release --no-pub` | Pass; Wasm dry run passes. This does not certify Safari or Android browser behavior. |
| Document handler tests | 7/7 pass with fake authorization/storage. |
| Ephemeral PostgreSQL | Schema snapshot and all 29 incremental migrations load; six standard SQL suites plus empty-patient deletion pass on both setup paths. |
| Focused scale diagnostics | Probes confirm schedule/count caps and a 38-request legacy report path. The latter is not connected to the current reports route; it is not a current-screen performance finding. HTTP was intercepted. |
| Linked Supabase project | `ACTIVE_HEALTHY`, region `eu-west-1`; CLI reports database size 16 MB. This is a snapshot, not the billing dashboard's quota measurement. |
| Live table statistics | Estimated 105 patients, 1,111 appointments, 1,668 appointment assignments, 230 document metadata rows and 94 payments. Estimates can lag; objects in R2 are excluded. |
| Live migration ledger | Local and remote IDs differ for several July–September migrations. Review migrations dated 20260906 and empty-patient deletion are recorded remotely. Different IDs do not prove missing behavior. |
| Live database lint | Finds shadowed/unused variables in seed functions and an ambiguous `seed_clinic_day_schedule` call in `seed_clinic_schedule_range`. No production workflow failure was established from these seed-only diagnostics. |

This review did not measure authenticated peak-load latency, monthly egress, current R2
usage, actual backup retention, restore success, or full role behavior on physical phones.
The [earlier browser review](hands-on-browser-review.md) records two transient input
exceptions whose root cause was not established; no evidence here closes that issue.

## Launch findings, in priority order

### 1. High — schedule can silently omit booked appointments

[Receptionist schedule](../lib/features/appointment/presentation/receptionist_appointments_providers.dart)
requests one three-week window with `limit: 1000`, then caches all three weeks as complete.
[Window calculation](../lib/features/appointment/presentation/schedule_week.dart) includes the
previous, selected and following week. The doctor schedule uses the same approach.
At 150 appointments/day, an all-branch previous week alone can exceed that cap.
The diagnostic used 3,150 synthetic appointments over 21 days: the selected week
contained 1,050, but the provider returned an empty list with no error.
This daily scenario assumes all seven days are active; six-day operation can still truncate.

Fix: fetch the selected week with complete pagination and explicit completeness handling;
prefetch adjacent weeks independently if useful. Test >1,000 matching rows and cache navigation.
Raising Supabase's row limit alone does not remove the client's explicit 1,000 limit.

### 2. High — operational counts can be wrong; admin reporting excluded

[Appointment counts](../lib/features/appointment/data/appointment_repository_all_queries.dart)
return a downloaded list's length rather than a server count. A simulated API cap made
1,500 matching appointments report as 1,000. Patient-specific counts and doctor-ID
prefiltering also use unpaginated reads. Pagination controls rely on those counts.
[Report sources](../lib/features/admin/data/admin_report_sources.dart) and
[analytics helpers](../lib/features/admin/data/analytics_query_helpers.dart) aggregate raw,
unpaginated rows. Monthly appointments exceed 1,000 even at one branch's expected volume.
Supabase's documented default maximum is [1,000 rows per response](https://supabase.com/docs/reference/dart/select);
the deployed API maximum was not inspected.

Reachability correction: the 38-request trend path belongs to unused `ReportsScreen`.
The router opens `AnalyticsScreen`; no current call site constructing `ReportsScreen` was found.
Withdraw the earlier 38-request claim as a live UI finding. Fix exact server counts and
doctor filtering in operational appointment lists; leave admin aggregation to its redesign.

### 3. High — a lost response can lead to duplicate money or bookings

[Payment submission](../lib/features/payments/presentation/record_payment_controller.dart)
constructs a fresh payment without a durable operation ID. The
[repository](../lib/features/payments/data/payment_repository_impl.dart) inserts it and
`collect_payment_due` accepts an additional amount without a retry identity.
The service's timeout does not undo an already committed database transaction.
A staff member retrying after a lost response can record money/credits twice;
due collection's upper bound only rejects retries that exceed the remaining due.
Recurring-booking RPCs serialize balance checks, but ordinary booking retries have no
durable identity either. The special due-queue guard does not cover every booking.

Fix: a stable per-operation ID reused on retry, enforced transactionally in the database;
reconcile unknown outcomes before presenting another save as safe. Verify dropped
responses, double clicks, concurrent operators and package balances on real staging.

### 4. High — document timeout and compensation need reconciliation

[Document uploads](../lib/features/patient/data/patient_documents_repository.dart) report
"cancelled" after 30 seconds, but `Future.timeout` leaves the underlying work running.
Metadata may therefore appear after failure is shown. If metadata commits but its response
is lost, unconditional compensation can remove the object referenced by that metadata.
Fix: durable upload identity/status lookup, distinguish definite rejection from uncertain
commit, and reconcile before cleanup or retry. Test slow uploads and lost insert responses.
A 10 MB upload over 2 Mbps takes about 40 seconds before overhead, so the timeout is realistic.

### 5. Medium/high — images can cause mobile-browser memory and transfer pressure

The original cache retained up to 50 files by count (potentially about 500 MiB of file bytes).
The authorized follow-up limits [the cache](../lib/features/patient/data/patient_document_cache.dart)
to 64 MiB and 50 entries, evicting least-recently used entries; oversized files bypass it.
Eight unit checks cover eviction, replacement, removal, patient cleanup and disabled caching.
Original scans remain unchanged; no thumbnails are added. Evicted files may need downloading again.
This budget excludes decoded images and bytes held by active viewers, so physical phone
testing is still needed. No phone crash has been reproduced. Upload limits remain a separate check.

### 6. Medium/high — other staff members' screens can remain stale

Schedule caches have no time expiry. No active database-change subscription, periodic
refresh or app-resume refresh was found in `lib/`; local mutations refresh local providers.
Another receptionist's booking or check-in may remain invisible until manual refresh.
Start with foreground/reconnect refresh and expiry of revisited cached weeks; manual refresh stays available.
Live updates are optional follow-up work. Avoid blanket polling; measure any realtime fan-out and refetch usage.

### 7. Required before branch three opens — only two branches exist in the model

[ClinicLocation](../lib/features/patient/domain/clinic_location.dart), the schema enum,
branch filtering and branch-specific reports currently support Tagamoa and Masr El-Gedida.
Add the actual third branch consistently through schema, serialization, controls and
reports; do not invent its name or add only a UI label. Confirm cross-branch patient rules.

### 8. Operational gate — reconcile deployment and prove recovery

Compare deployed functions, grants, policies and columns with the intended schema before
repairing migration bookkeeping. Do not blindly push old migrations or mark them applied.
Review/remove unused live seed RPCs and inspect their execution grants before handover.
Perform a database-plus-R2 restore in isolation; record backup owner, frequency, retention
and acceptable data-loss window. Database backups do not contain R2 objects.
Confirm Sentry receives a fictional test failure without patient data, triage the previous
browser exceptions, and establish account/password recovery and a clinic internet-outage procedure.

## Hosting recommendation

**User constraint: stay on Supabase Free until measured usage requires an upgrade.**
The proposed correctness fixes and cache limit do not require Pro. Keep network queries
bounded, monitor actual quotas, and provide a separate backup-and-restore process on Free.

Current published allowances: Free has 500 MB database capacity, shared CPU/500 MB RAM,
5 GB uncached egress and 500,000 edge invocations/month. Pro starts at $25/month, includes
compute credit covering one Micro (1 GB RAM), 8 GB disk, 250 GB uncached egress and daily
backups with seven-day retention. Free omits automatic backups and can pause after
inactivity. Extra projects/usage may add cost. [Official Supabase pricing](https://supabase.com/pricing).
Choose a backup frequency that matches the clinic's acceptable data-loss window.

The 16 MB current database is comfortably below the published Free size allowance.
Future row/index growth, query costs and quotas still need monitoring. Browser users use
the HTTP API; staff count is not a count of dedicated PostgreSQL connections.
For illustration, 60 staff × 100 screen loads/day × 26 days × 50 KB is 0.78 GB/month;
at 500 KB/load it is 7.8 GB. Payloads and repeated fetches can matter before CPU.
Database and edge egress count separately from R2 bytes; cached/uncached Supabase quotas
are distinct. [Egress accounting](https://supabase.com/docs/guides/platform/manage-your-usage/egress).

**Keep private R2.** The existing design signs URLs in a Supabase Edge Function and transfers
objects directly between the browser and R2, so scan bytes bypass Supabase's data path.
R2 Standard includes 10 GB-month, 1 million write-class and 10 million read-class operations
monthly, with free internet egress. Additional Standard storage is $0.015/GB-month;
the free allocation is usage pricing, not a separate speed tier. [Official R2 pricing](https://developers.cloudflare.com/r2/pricing/).
If all 300 new patients/month each receive five 2 MB images, that adds about 3 GB/month;
five 5 MB images gives 7.5 GB/month. Patients without scans reduce that; later scans increase it.
Stored files accumulate: the free allowance does not erase last month's files.

## Evidence required for launch

1. Close findings 1–4 excluding admin reports; verify memory/freshness and add branch three when needed.
2. Use isolated staging with fictional 10,000 patients and 100,000 appointments, representative
   payments/programs and scans. Exercise all roles through real PostgREST/RLS and the R2 function.
3. Measure 30 active users with human-paced workflows for an hour, then a 90-user login/activity
   burst. Include search, schedule, save, check-in, payments, programs and image viewing.
   Suggested acceptance: 95% of ordinary warm reads/saves within 1 second at the API and
   critical screens within 2 seconds; zero silent loss/duplicate writes.
   These are proposed targets on agreed clinic networks, not results obtained here.
4. Test lost responses, offline/reconnect, expired sessions, two operators editing the same
   record, denied writes, and an app update while another browser tab remains open.
5. On physical iPhone Safari, Android Chrome and clinic PCs: long Arabic names, keyboard/form
   editing, file picking, five large scans, PDF viewing and navigation/back behavior.
6. Restore DB and R2 together, verify monitoring and release rollback, then pilot one branch
   with real staff for several working days before expanding. Keep an agreed outage fallback.

Local evidence: `build/production-readiness-{analyze,tests,web-build,probes,sql-snapshot,sql-migrations,sql-deletion,sql-deletion-migrations}.log`.
The original diagnostic assertions describe pre-fix defects and are now superseded
by permanent regression tests listed in [testing](testing.md). Do not run the old
`build/` diagnostic as an acceptance suite; its assertions intentionally expect bugs.
