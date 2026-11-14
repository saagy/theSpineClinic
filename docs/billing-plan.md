# Billing redesign plan

Status: agreed November 10, 2026. **Slice 1 (database) is built, tested
locally and applied** to the linked project on November 10, 2026 as migrations
`20261110202337` through `20261110202732` (files renamed to the recorded
versions). The demo wipe and seed were run there the same day: 10 services,
168 invoices from September 12 to November 10 across both branches, all
reconciling with patient session balances. **Slice 2 (service catalog) is
built**: `/billing/services` and `/billing/services/:id`, opened from the
Billing tab's Services action and the Admin hub, for payment receptionists and
super admins. **Slice 3 (Payments tab and new invoice) is built**: the patient
workspace's Payments tab and overview due banner read the new invoices, and
`/patient/:id/invoices/new` issues an invoice with optional cash and Visa
payment for any receptionist (discounts for payment staff only). **Slice 4
(invoice detail and money actions) is built** on November 11, 2026: invoice
rows open `/patient/:id/invoices/:invoiceId`, a side panel from 1000 px and a
full screen below it. Any receptionist can record a payment and print; payment
staff can also void and correct receipts, void refunds, void the invoice,
refund (`.../refund`) and correct the invoice (`.../correct`). Invoices,
receipts and refunds print as A4 PDFs with a placeholder clinic-details line.
**Slice 5 (legacy removal) is built in the app** on November 11, 2026: the
self-pay pilot screens, the legacy payment entry, ledger and collect-due
sheets, the manual package balance dialog, the old admin Reports screen and
the patient insurance fields are removed. The Billing tab (payment
receptionists) now opens a short Billing screen that links to Services and
prices; slice 6 adds the reports there. Super admins reach Services from the
Admin hub. Migration `20261111120000_remove_legacy_billing.sql` drops the
pilot tables and commands, `payment_records` with its triggers and
`collect_payment_due`, narrows `execute_clinic_mutation` to bookings, and
removes insurance keys from `patients.personal_details`. It passes the SQL
suites locally and was **applied to the linked project by hand** (SQL editor)
on November 11, 2026, then verified object by object. Its version
`20261111120000` was then recorded in the project's migration history, so a
later `supabase db push` treats it as applied. **Slice 6 (reports) is built
in the app** on November 11, 2026: the Billing screen shows the reports
below with a shared period, branch and doctor (regrouped into five reports on
November 13, 2026; see [the reports redesign](billing-reports-redesign.md)) and A4 landscape
printing (CSV export was removed on November 12, 2026), and super admins open it from the Admin hub. Migration
`20261111144013_invoice_reports.sql` adds the `invoice_report` RPC; it passes
the SQL suites locally and was **applied to the linked project** on November
11, 2026 through the Supabase tooling (file renamed to the recorded version;
grants checked: only `invoice_report` is executable by signed-in users).
**Slice 7 (staff reference fields) is built in the app** on November 12,
2026: the staff editor's Employment details section records national ID,
date of birth, hire date, working days and working hours, and the staff
directory shows each person's working days and hours. Migration
`20261111170000_staff_reference_details.sql` adds the admin-only
`staff_details` table and extends the staff account RPCs; it passes the SQL
suites locally and was **applied to the linked project by hand** (SQL editor)
on November 12, 2026, with its version recorded in the migration history,
then verified: the table has row-level security with its one admin read
policy, the detail writer is not callable by clients, and both staff account
functions save details. **Slice 8 (rendered workflow review) ran** on
November 12, 2026 against the linked project with a fictional patient: every
invoice, payment, refund, void and correction path was exercised from the
app on desktop and phone, the reports were checked against those writes, and
six issues were fixed; staff employment details were saved, reloaded and
cleared live as the super admin. Printing remains to be checked in a
regular browser; see [the review results](billing-review-results.md).

Slice 6 behavior worth knowing:

- Money is dated by when it changed hands (receipt received time, refund
  recording time) and belongs to the branch of that receipt or refund.
  Voided documents are left out of every total and listed under Cancelled
  in Payments & refunds on the day they were cancelled.
- Revenue is built from the stored line allocations. A line's paid money is
  split equally among its doctors to the piaster, so Revenue's By doctor
  table (including its "No doctor" row) always adds up to the money paid.
  With all doctors the app reads `invoice_report` kinds `revenue` and
  `doctors` together; with one doctor, kind `doctor`.
- A refund can move paid money between lines of the invoice as well as
  hand money back. Each refund row is split: the money handed back keeps its
  cash or Visa method, and money that only moved appears as "Refund
  adjustment" (migration `20261113175332`). The figure and column are shown
  only when such money exists.
- Services counts invoices **dated** in the period (by the invoice's branch)
  and shows what has been paid on them to date; Balances due ignores the period
  and is always as of now.
- Reports cover at most 366 days and list at most 5,000 detail rows; totals
  always include every row and the screen says when rows are capped.
- Print contains the totals and the tables as shown. There is no CSV export:
  front-desk staff print, and fixed print templates will be added later.
- Receptionists with a branch see only their branch's reports and do not
  get a branch filter. Their invoices, payments and refunds are recorded at
  their own branch, shown as plain text instead of a selector. Super admins
  and receptionists without a branch keep the selectors.
- A failed report shows its error with Retry instead of retrying silently.

Doctor sessions report (added November 13, 2026, migration
`20261113100000_doctor_session_report.sql`, applied to the linked project):

- A seventh Billing tab counts the sessions each doctor did in a period, by
  type (PT sessions, assessments, reassessments), for working out doctor pay.
  It is built from appointments, not from invoices or collected money.
- Only checked-in appointments count. Cancelled ones never count. Past
  appointments still marked as scheduled are listed under "Not checked in
  yet" and flagged in the totals so reception can resolve them before pay is
  worked out.
- A session with two doctors counts once for each of them; the screen says
  so and each session lists who it was shared with. Spinal traction is done
  without a doctor and is never counted, including older appointments that
  still have one attached.
- The branch is the patient's branch, as on the schedule screens.
- All doctors: one row per doctor that expands to their sessions. Printing
  gives the summary, the unchecked appointments, then each doctor's sessions
  on a page of their own, ready to hand out. One doctor: their figures and
  session list.
- There are no pay rates yet. When the clinic sets them, pay is the rate per
  type times these counts; rates need their own permissions and change
  history (see AGENTS.md technical debt).

Slice 5 behavior worth knowing:

- Session balances are read-only in the app. They change only through
  invoices, refunds, voids and package visits. The database guard
  `guard_patient_balance_write` still lets a receptionist or super admin
  change a balance with a direct API call; tightening it is a separate change
  because invoice commands write balances under the caller's identity.
- `billing_patient_has_invoices` keeps its name (the empty-patient preflight
  calls it) and now checks invoices only.

Slice 4 behavior worth knowing:

- Every command sends the invoice version it was prepared from. A form or
  dialog opened before another change stays rejected (`stale`) until reopened.
- The refund form caps sessions to cancel at the patient's unused balance and
  shows the payback the database will derive; it asks for the payback method
  only when money is actually handed back.
- A correction is pre-filled from the original, but lines take **current
  catalog prices** (the database only issues at catalog prices) and services
  that are no longer sold are left out and named in a warning. The corrected
  total must cover money already received.
- A later active refund locks earlier receipts and refunds; their Correct and
  Void menu items stay listed, disabled, with "Void the later refund first".
- Client behavior is tested with repository fakes; the commands themselves are
  covered by the slice 1 SQL tests (reports: `test/invoice_reports.sql`).
  Slice 8 exercised the writes from the app against the linked project.

This plan replaces the legacy `payment_records` system and the
[self-pay billing pilot](billing-pilot.md) workflow. The pilot's numbering
series, durable mutation receipts, line allocations, permission checks, and PDF
output are reused where they fit. Drafts, the single invoice doctor, the
examining consultant, separate return documents, insurance fields, and the pilot
screens are replaced. All financial data is dummy data and may be wiped. The app
and every printed document remain English only.

## Scope

| Client requirement | Plan |
| --- | --- |
| 1. Patient information | Keep the permanent file number and personal details. Remove insurance fields. Keep referral source as free text. |
| 2. Services and prices | Rebuild the admin service catalog with the service model below. |
| 3. Staff directory | Add national ID, birth date, hire date, working days, and working hours. These fields are for reference only and do not restrict bookings. |
| 4. | Skipped by the client. |
| 5. Invoice and receipts | New invoice, receipt, void, and correction workflow on the patient Payments tab. |
| 6. Return invoice | Replaced by **Refund**. The app does not use the word "return". |
| 7. Insurance | Not implemented. |
| 8. Reports | Billing tab reports, excluding insurance reports. |

## Concepts

Staff-facing wording (November 12, 2026): the app says **Cancel** for a void
and **Edit** for a correction, and cancelled documents print with a
CANCELLED watermark. The database and code keep the void/correct names.
Cancelling a paid invoice (November 13, 2026): Cancel invoice asks "Was this
money given back to the patient?" **No, entered by mistake** cancels the
invoice and its payments together in one step (`invoice_void_all`). **Yes**
opens the refund form, because money that left the drawer is a refund. An
invoice with an active refund still has to have the refund cancelled first.

Services taken off the catalog show as **Removed**. The service form has one
**Remove service** action: `remove_service` deletes a service no invoice has
used and hides (sets inactive) one that invoices list. A removed service
offers **Restore service**. Migration `20261113090000` was applied to the linked
project by hand (SQL editor) on November 13, 2026.

| Document | Purpose | Staff action |
| --- | --- | --- |
| Invoice | Services charged, quantities, line doctors, invoice discount, and invoice date. Immutable after creation. | New invoice |
| Receipt | Money received against one invoice by cash or Visa. One invoice can have many receipts. | Record payment |
| Void | Cancels a mistake. It stays visible with actor, time, and reason, and is excluded from every total. Numbers are never reused. | Cancel |
| Correction | Voids the invoice or receipt and creates a prefilled replacement linked to the original. This is the only editing path. | Edit |
| Refund | A patient-requested reduction in invoice value. Unused sessions are cancelled and money is paid back immediately when needed. | Refund |

### Refund calculation

Staff choose the invoice line, the number of unused sessions to cancel, a
manually agreed **refund value**, the payback method (cash or Visa), and a reason.

- New invoice value = previous invoice value - refund value
- Money paid back = max(0, net collected - new invoice value)
- Remaining balance = new invoice value - net collected after payback

| Example: 6 PT sessions for EGP 3,000, 2 used | Input | Result |
| --- | --- | --- |
| Paid 3,000; clinic returns 1,800 | 4 sessions, refund value 1,800 | Pay back 1,800. Balance 0. |
| Paid 1,000; patient owes nothing more | 4 sessions, refund value 2,000 | Pay back 0. Balance 0. |
| Paid 1,000; patient still owes 200 | 4 sessions, refund value 1,800 | Pay back 0. Balance 200. |

Rules:

- Refunds belong to the invoice and its lines, not to receipts.
- Only unused sessions can be cancelled. Future booked sessions that would use
  those sessions must be cancelled first.
- A refund can be voided as a mistake. Voiding restores its sessions and money.
- Staff cannot void a receipt when that would leave net collected below the
  amount already paid back. They must void the refund first.

## Agreed business rules

- **Services** are either single sessions of a type, or packages of N sessions
  of one type. Packages never combine session types. Fields: name, type
  (PT session, traction, initial assessment, reassessment, other), sessions per
  unit, price, active, and doctor attribution enabled.
- **Package balance:** creating an invoice immediately adds the full session
  count to the patient's PT or traction balance. Patients may use the sessions
  before paying. Refunds and voids remove sessions. Packages never expire.
- **Doctors:** each invoice line has zero or more doctors. Every doctor is
  available, and the line uses the shared doctor selector. New lines prefill the
  previously selected doctors. The consultant field is removed.
- **Doctor earnings** are calculated on **money actually collected**. The
  receipt amount, minus money paid back by refunds, is allocated
  proportionally to invoice lines by net amount. Each line's share is split
  equally among its doctors. Lines without doctors count only toward clinic
  revenue. Refunds that only cancel unpaid debt do not change earnings.
- **Discount** applies to the whole invoice as a percentage or fixed amount. It
  is allocated proportionally to lines. A 100% discount records free sessions.
  Later goodwill reductions use Refund.
- **Dates:** the invoice date can be selected for today or a past date, never
  the future. The real entry time is also stored. Receipts and refunds always
  use the actual recording time so the daily cash report matches the drawer.
- **Voids** exclude a document from totals for its original date and appear in
  the void log on the void date. A later active refund blocks voiding or
  correcting earlier receipts and refunds on that invoice; void the refund
  first. An invoice can be voided on its own only with no active receipts or refunds
(`invoice_void_all` cancels it together with its receipts when there are no
refunds) and
  while the patient's shared session balance still holds its sessions unused
  and unbooked (sessions are pooled per patient, not tracked per invoice).
- **Corrections:** correcting a receipt voids it and records the replacement
  with the original received time. Correcting an invoice creates the
  replacement, moves its active receipts with their received times, and voids
  the original. The replacement total must cover the money already received,
  and invoices with active refunds cannot be corrected.
- **Receipts and refunds carry their own branch**, which is where money
  changed hands. Daily totals use the receipt's received time.
- **Numbering** remains independent for each branch and document type.
- **Printing** uses a clean A4 layout with placeholders for clinic details until
  the client template arrives. Tax Authority e-receipts are out of scope.

## Permissions

| Capability | Receptionist | Payment receptionist | Super admin | Doctor |
| --- | --- | --- | --- | --- |
| View invoices, receipts, and balances | Yes | Yes | Yes | No |
| Create invoices and record receipts | Yes | Yes | Yes | No |
| Select the invoice date | Yes | Yes | Yes | No |
| Apply a discount, including 100% | No | Yes | Yes | No |
| Void, correct, or refund | No | Yes | Yes | No |
| Billing tab reports | No | Yes | Yes | No |
| Service catalog | No | Yes | Yes | No |

The database enforces each rule inside its checked RPC. The app also hides
actions that the current user cannot perform.

## Screens

**Patient > Payments tab**

- Summary: balance due, net collected, and remaining PT and traction sessions.
  The primary action is **New invoice**.
- Invoice list with number, date, services, total, paid, due, and status:
  Paid, Partially paid, Unpaid, Refunded, or Voided.
- New invoice: date, branch, service lines with quantity and doctors, discount
  for permitted roles, and totals. An optional **Collect payment now** section
  accepts cash, Visa, or both, creating one receipt per method.
- Invoice detail: a side panel on wide windows and a full screen on narrow ones.
  It shows lines and doctors, totals, and a timeline of receipts, refunds, and
  voids. Actions are Record payment, Print, and permitted Refund, Void, and
  Correct actions.

**Billing tab (reports only)**

The tab shares a toolbar for date range presets, branch, and doctor. Wide
windows show tables. Narrow windows show lists. Each report has a totals bar and
A4 printing.

1. **Payments & refunds:** every receipt and every refund paid back, with Cash,
   Visa and Total after paybacks (each showing received and paid back),
   totals by receptionist, and cancelled documents.
2. **Revenue:** what the money paid for. With all doctors: a By doctor table
   (cash, Visa, total, and "No doctor") above every payment line: date,
   patient and ID, service, doctors, method, price and paid. With one doctor
   (picker or tapping their row): their lines with price, paid and their
   share; split lines say so.
3. **Doctor sessions:** checked-in sessions per doctor and type for doctor pay,
   with each doctor's session list and the appointments not checked in yet.
4. **Services:** quantity, total price, paid and balance due for each service, with
   each invoice behind it.
5. **Balances due:** patient and ID, due since, open invoices and balance due.

Design follows [DESIGN.md](../DESIGN.md) and is reviewed in rendered desktop,
mobile, light, and dark states before release.

## Data changes

Slice 1 built these as new tables beside the pilot, so the deployed pilot keeps
working until slice 5 removes it: `service_catalog`, `invoices`,
`invoice_lines`, `invoice_line_doctors`, `invoice_receipts`, `invoice_refunds`,
`invoice_refund_lines`, `invoice_allocations` and `invoice_number_series`. See
[database schema](database-schema.md#invoices-v2) for the commands and rules.

- Services: add type, sessions per unit, and doctor attribution. Drop package
  linkage, validity, and insurance columns.
- Invoices: remove draft state, invoice doctor, and consultant fields. Add
  discount type and value, void fields, and replacement links.
- Add a line-doctor table with doctor name snapshots.
- Receipts and refunds: add void fields and replacement links. Refunds store
  refund value, payback amount and method, reason, and cancelled sessions by line.
- Store proportional line allocations for every receipt and refund.
- Update patient session balances inside the same transaction as invoices,
  refunds, and voids.
- Let all active receptionists read billing data and call the issue commands.
  Restrict discount, void, correct, refund, and report commands to payment
  receptionists and super admins.
- Add staff national ID, birth date, hire date, working days, and working hours.
- Remove `payment_records` and its triggers and RPCs, legacy payment sheets and
  ledger, pilot drafts, return and register screens, the manual package balance
  dialog, the old admin Reports screen and queries, and patient insurance fields.
- Update `supabase/full_schema.sql`, [database schema](database-schema.md),
  [billing pilot](billing-pilot.md), and AGENTS.md technical debt together.

## Test data

[`supabase/seed_invoice_demo.sql`](../supabase/seed_invoice_demo.sql) and then
[`supabase/seed_invoice_demo_events.sql`](../supabase/seed_invoice_demo_events.sql)
do this through the real commands. Both are destructive and must be run by the
database owner only after confirming the target project.

After confirming the target project, wipe financial data and reset session
balances. Seed about 10 services: single PT, single traction, assessment,
reassessment, and 6- and 12-session packages of each session type. Add about
60 days of activity across both branches and several doctors, including partial
payments, cash and Visa splits, free sessions, discounts, refunds with and
without payback, voided receipts, a corrected invoice, and outstanding balances.

## Delivery slices

1. Schema, checked RPCs, SQL tests, wipe, and seed.
2. Service catalog.
3. Payments tab, invoice list, and new invoice with immediate collection.
4. Invoice detail, receipts, refunds, voids, corrections, and A4 printing.
5. Removal of legacy payments, balance dialog, old reports, and insurance fields.
6. Billing tab reports and CSV export.
7. Staff reference fields.
8. Rendered workflow review with seed data on desktop and mobile, in light and
   dark themes, followed by `flutter analyze` and `flutter test`.

## Pending input

The client's A4 document template. It does not block implementation.
