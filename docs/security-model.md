# Security model

This describes the schema through the September 29 hardening migrations. See
[September 27 rollout](production-rollout-2026-09-27.md) and the
[September 29 follow-up](launch-hardening-2026-09-29.md) for deployment evidence
and the limits of verification.

## Roles and enforcement

Supabase RLS and permission-checked functions enforce access. Flutter checks
currentUserProvider before mutations for early rejection; client checks alone
are not a security boundary.

| Role | Intended access |
| --- | --- |
| Super admin | Staff administration, clinic operations, finance and clinical records. |
| Receptionist | Patient/appointment operations; payment writes require can_manage_payments. |
| Ordinary doctor | Patients assigned permanently or linked through active appointment assignments. |
| Senior doctor | Broader patient management and program privileges; no payment-write permission. |
| Inactive staff | Own application/profile only; no operational patient access. |

The isolated database contains 17 public application tables. Table grants
must exist before RLS can authorize queries. Sensitive SECURITY DEFINER
functions check the staff profile and use explicit search paths and execute ACLs.

Review migrations scope appointments and payment reads to patient access,
restrict assignment writes to management, prevent direct doctor balance edits,
and protect self-service role, activation, payment and senior privileges.
Appointment identity is immutable for authenticated callers. Schedule edits and
deletion have a separate permission guard. Temporary covering doctors have a
clinic-local edit window; patient-read scope is broader and needs policy review.

Financial triggers account for charged appointment state on insert/update/delete
and synchronize payment-credit changes. Due collection locks its row. New
financial constraints are NOT VALID until historical values are audited.
Durable receipts now protect the current clients' financial, booking and program
save retries; they do not provide universal duplicate detection across accounts
or cleared browser storage. See [retry contract](production-hardening.md).

## Documents

Current uploads use private Cloudflare R2 objects through the document-storage
Supabase Edge Function. Legacy Supabase storage policies remain in the schema.
Metadata lives in patient_documents.

The edge handler authorizes the patient UUID derived from the object key,
rejects conflicting supplied patient IDs, and checks all keys before batch
deletion. Uploads require an existing accessible patient and use durable random
request IDs as object keys.
Whole-folder cleanup requires prior patient deletion. Metadata deletion precedes
best-effort object cleanup. Tracked uploads compensate only after a persisted
failed metadata receipt fences future finalization; uncertain outcomes retain
the object and request identity for reconciliation.

Download URLs expire after 15 minutes; upload URLs after 5 minutes. Issued
bearer URLs can remain usable until expiry after access changes. Extension/type
allowlisting is not malware scanning. Tracked uploads enforce a 1-byte to 10-MiB
declared size and verify R2 object size before finalization. The old untracked
signing action remains for compatibility; old clients lack these retry guarantees.

## Identity, configuration and telemetry

Registration creates inactive doctor/receptionist applications using an
anonymous RPC that directly creates auth rows. Supported Auth signup controls,
server password validation and abuse prevention require follow-up review.
Self-service password recovery UI remains deferred.

.env is a browser asset: only public configuration belongs in it. The reviewed
copy contains a Supabase URL, anon-role JWT and Sentry DSN. Never add service-role
keys, database passwords or R2 credentials. R2 credentials belong only in Edge
Function secrets. Never commit real patient data.

Custom error reporting removes raw database details and staff names. Complete
automatic Sentry events and breadcrumbs still need staging privacy verification.
