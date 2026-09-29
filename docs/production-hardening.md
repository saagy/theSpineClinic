# Production hardening — 27 September 2026

Implemented and deployed for the approved items 1, 2, 3, 4 and 6. Supabase Free
remains the target. Backend migrations, upload function and web app are live; see the
[rollout record](production-rollout-2026-09-27.md) for deployment and verification status.

## Behavior

The [September 29 follow-up](launch-hardening-2026-09-29.md) extends durable
receipts to program create/edit, improves read-policy query plans and fixes
navigation, partial profile saves and Sentry diagnostics.

- Doctor and reception schedules fetch the selected Saturday–Friday week in
  ordered pages of up to 500, continuing until an empty page. There is no 1,000-row
  cutoff. A failed page produces an error, not a partially populated schedule.
  Weeks are cached only after the complete read. Adjacent weeks load on navigation.
- Doctor/reception schedules also check freshness when the browser regains focus,
  the schedule route is revisited, or reception returns to its Schedule subtab.
  Only the selected week reloads, and only after 60 seconds since its last
  successful full read. There is no timer or realtime subscription. Rows stay
  visible while refreshing; failures retain them and retry only on a later return,
  with a 60-second attempt cooldown. Concurrent return events share one refresh.
  Day/filter selections survive; obsolete requests and responses overlapping a
  local status change are discarded. A local edit does not renew the week's age.
- Operational appointment, patient appointment and future package-reservation
  counts use exact server counts with at most one returned row. Doctor filters
  use an embedded join instead of downloading a capped list of assignment IDs.
  Patient search filters reference their selected `patient` alias.
- Payments, collections and booking batches have durable request IDs and database
  receipts. A lost response can be retried without repeating money, credits or
  appointments. Bundled treatment/assessment booking is one transaction.
  Pending booking retries can reach reconciliation even if the successful first
  attempt used the remaining credits; fresh bookings retain the balance guard.
- Collections additionally compare the displayed prior paid amount under a row
  lock. A second receptionist working from an older amount must refresh.
- Uploads have stable object keys and a database receipt before the PUT. On retry,
  the Edge Function checks whether R2 already has the object, verifies its size,
  and completes or returns the saved metadata. Only a definitive, persisted
  failed insert allows compensating deletion. Unknown results retain the receipt.
- The PUT is aborted/closed after 45 seconds. This is an uncertain outcome, not
  a claim that R2 definitely received nothing. Retrying the same file reconciles it.
- R2 requests explicitly use the SDK's native-fetch transport. The default Node
  HTTP adapter crashed deployed Deno workers during upload existence checks;
  the September 27 follow-up replaces it and adds transport regression coverage.
- The file-byte cache retains at most 50 entries and 64 MiB using LRU eviction.
  Decoded images and active viewers have separate memory usage. No thumbnails.

Admin reports, realtime subscriptions, the Madinaty branch, account recovery,
backup automation and paid hosting changes are outside this patch.

## Durable retry contract

The browser persists a UUID and SHA-256 payload digest in SharedPreferences,
scoped by account, operation and subject. Clinical fields and upload bytes are
not stored in preferences. The ID survives navigation and a normal browser reload.
Uploads require reselecting the same file if the page was closed.

Success clears the pending ID; a later intentional identical action gets a new ID.
A definite database rejection is also recorded and clears the pending ID.
Unknown network outcomes keep it. Editing a pending payment/booking first calls
`resolve_clinic_mutation`: it waits on the same transaction lock, returns whether
the old action completed, or writes a tombstone preventing a delayed old request
from executing. Completed prior requests require review before another write.

This is retry protection, not universal duplicate detection. Separate browsers,
cleared site data, separate staff accounts or deliberate new submissions have
different IDs. Do not clear site data to recover an uncertain financial operation
without checking its receipt and actual records. Browser tabs are not a single
atomic local-storage transaction. Schedule pages are separate reads, not a frozen
database snapshot during concurrent rescheduling/deletion; manual refresh remains.

## Schema additions

`20260927010000_mutation_receipts.sql` adds `mutation_receipts`:

| Column | Definition |
| --- | --- |
| request_id | UUID primary key; caller-generated |
| actor_id | Required staff UUID |
| kind | Required text: payment, collect_due, booking, program_create, program_update, or cancellation tombstone |
| payload_hash | Required SHA-256 text digest of canonical JSONB (tombstones use `{}`) |
| outcome | Required JSONB: success/ID or definitive error |
| created_at | Required timestamptz, default now() |

`execute_clinic_mutation(uuid,text,jsonb)` serializes each ID, verifies ownership
and payload identity, and writes the outcome in the same transaction. Existing
booking/payment rules and balance triggers remain authoritative. A bundle calls
the existing booking function twice inside this single transaction; either both
parts commit or neither does. `resolve_clinic_mutation(uuid)` fences edited retries.

`20260927020000_document_upload_receipts.sql` adds `document_uploads`:

| Column | Definition |
| --- | --- |
| request_id | UUID primary key and resulting document ID |
| actor_id, patient_id | Required UUIDs |
| file_name | Required original filename |
| program_id | Optional UUID |
| content_hash | Required SHA-256 text digest of client file bytes |
| byte_size | Required integer, 1–10,485,760 |
| object_key | Required unique text, patient UUID/request UUID |
| status | pending, completed or failed; defaults to pending |
| outcome | Optional JSONB finalization result/document |
| created_at | Required timestamptz, default now() |

`begin_document_upload(...)` validates patient access, identity, size, program
ownership and retry metadata. `complete_document_upload(uuid)` locks the receipt
and creates metadata exactly once, retaining success or definite failure. Receipts
are not cascaded away when documents/patients are removed, so old retries cannot
recreate them. The file hash identifies a retry; R2 HEAD verifies size, not a
cryptographic content checksum. The Edge Function performs the object-existence
check; PostgreSQL cannot atomically transact with R2.

Both tables have RLS, explicit authenticated grants and **no client policies**;
clients cannot directly read/write receipts. The four SECURITY DEFINER RPCs have
fixed search paths, explicit active-staff checks and authenticated-only grants.
Existing RPCs and the legacy upload action remain for rollout compatibility;
older app versions do not gain retry protection until updated.

Receipts add small database writes and storage. Upload recovery adds R2 HEAD
requests. Neither requires a paid plan. Do not delete receipts merely to reclaim
space: doing so removes old retry protection. Retention needs a separate design.
Abandoned pending uploads and failed cleanups remain identifiable in the receipt
table; there is no scheduled janitor in this patch. An operator can inspect old
receipts and compare database metadata/R2 objects. Cleanup must fence finalization
and account for outstanding signed PUT URLs before deleting any object.

## Release order and validation boundary

1. Review the linked database's actual definitions against the new migrations.
   Earlier local/remote migration IDs diverge; do not blindly push the entire
   historical migration directory or mark old entries applied.
2. Apply the two September 27 migrations in order, then deploy `document-storage`.
3. Verify the new RPCs and upload actions with fictional staging records through
   actual PostgREST/RLS and R2; include slow/lost responses and concurrent operators.
4. Publish the Flutter web build and ask staff to reload old tabs. Deploying the
   frontend before its RPCs/function will make protected writes fail safely.
5. Test iPhone Safari, Android Chrome and clinic PCs; measure real load and latency
   before broad rollout. These local tests do not prove hosting capacity or backups.

Local regression coverage includes >1,000 appointments with a lower server page
cap, exact counts, later-page failure, browser retry persistence, duplicate clicks,
changed pending requests, upload response loss, role checks and atomic bundles.
The SQL runner tests schema snapshot and migration replay in ephemeral PostgreSQL;
it does not simulate multiple database connections. Edge tests use fake storage.
Original hardening results: zero analyzer issues, 341 Flutter tests, 11 Node tests, eight
SQL suites on both setup paths, Deno type check and release web build all pass.
See [testing](testing.md) for current follow-up results, commands and logs.

Query syntax references: [PostgREST embedding](https://docs.postgrest.org/en/v13/references/api/resource_embedding.html)
and [exact counts](https://docs.postgrest.org/en/v13/references/api/pagination_count.html).
