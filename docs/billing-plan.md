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
payment for any receptionist (discounts for payment staff only). Invoice rows
are not yet tappable; slice 4 adds the detail view. Slices 4-8 are not started.

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

| Document | Purpose | Staff action |
| --- | --- | --- |
| Invoice | Services charged, quantities, line doctors, invoice discount, and invoice date. Immutable after creation. | New invoice |
| Receipt | Money received against one invoice by cash or Visa. One invoice can have many receipts. | Record payment |
| Void | Cancels a mistake. It stays visible with actor, time, and reason, and is excluded from every total. Numbers are never reused. | Void |
| Correction | Voids the invoice or receipt and creates a prefilled replacement linked to the original. This is the only editing path. | Correct |
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
  first. An invoice can be voided only with no active receipts or refunds and
  while its remaining sessions are unused and unbooked.
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
windows show tables. Narrow windows show lists. Each report has a totals bar,
CSV export, and A4 printing.

1. **Daily money in/out:** receipts and refunds paid back by cash and Visa, net
   expected cash and Visa, totals by receptionist, and voided documents.
2. **Revenue:** today, this month, or a custom range. One row per collected
   service allocation: date, patient, file number, service, price, collected
   amount, doctors, and method.
3. **Doctor revenue:** one doctor over a range: date, patient, file number,
   service, price, and doctor share.
4. **Doctors summary:** collected total, cash, and Visa for each doctor.
5. **Outstanding balances:** patient, file number, open invoices, amount due,
   and oldest unpaid date.
6. **Services:** count, billed, and collected for each service, with detail rows.

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
