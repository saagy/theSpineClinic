# Self-pay billing pilot

Run `flutter run -d web-server --web-hostname=127.0.0.1 --web-port=8765`
and open the URL Flutter prints. A receptionist with payment access opens
**Billing** between **Patients** and **Profile**. Admins open it from
**Admin → Billing**, then use the service catalog icon to add services and
prices. Use a test patient for issued invoices, receipts, and refunds.

Migrations `20261110010000` through `20261110080000` were applied to the linked
live Supabase project on November 10, 2026. Other environments need those
migrations before using Billing. To run against an older schema, launch with
`--dart-define=BILLING_PILOT=false`.

| Capability | Super admin | Payment receptionist | Other staff |
| --- | --- | --- | --- |
| View and export billing | Yes | Yes | No |
| Draft, issue, collect, return, refund | Yes | Yes | No |
| Add, change, or archive services | Yes | No | No |

## Desk workflow

1. Add active services and prices in the catalog. An empty service picker
   links admins to the catalog and directs receptionists to an admin.
2. Start a new invoice. Choose the patient by name, either phone number, or
   permanent ID number. The directory loads 25 records per page. Choose the
   branch, doctor, and service date. The optional examining role uses the
   active Senior Doctor designation.
3. Add service quantities, enter one percentage discount, and save the draft.
   The detail screen presents the final amounts for review before issuance.
4. Record the money received with its cash or Visa method. Each installment
   creates a distinct receipt. Use Print / PDF on the invoice or transaction.
5. Issue a return with quantities and a reason. The return reduces outstanding
   debt first. Record any money actually paid back as a separate refund.

An invoice for EGP 1,000 with EGP 600 collected and an EGP 500 return has
no outstanding balance and EGP 100 available to refund. The refund is a
separate dated transaction. Payments are recorded manually.
The pilot screens and printed documents use English.

The register filters by branch, status, and date. The date range uses service
date for invoices and clinic-local transaction date for collections. The
collections export includes receipts and refunds as separate positive amounts
with a document type. Export either register as UTF-8 CSV. Use narrower filters
if the export exceeds 10,000 records.

## Behavior at failure boundaries

- A changed quote requires refreshing prices and reviewing the draft again.
- A stale write leaves the current document intact. Refresh and review before
  submitting another action.
- A network failure leaves a persistent request ID. The check-save action
  retrieves the committed document or closes the unresolved request before
  staff can submit a replacement. The device stores the request ID and a
  digest rather than the financial payload.
- An issued invoice and its numbered documents are historical records. A
  printing error can be retried from the detail screen.
- Currency is EGP. Patient ID numbers are clinic-wide and may have gaps. Invoice,
  receipt, return, and refund sequences are independent in each branch.

The pilot uses a separate register from legacy payments. Staging acceptance
should confirm the printed branding and document conventions before production
use. Packages, insurer claims, and the client report suite have separate
follow-up milestones.

## Original requirements status

| Area | Available now | Remaining |
| --- | --- | --- |
| Patient registration | Permanent ID number, optional address, birth date, nationality, gender, second phone, insurance membership and expiry, referral source. New profiles start with Egyptian nationality. | Link insurance company selection to the insurer catalog when that is available |
| Services and prices | Admin service catalog with prices and archiving | Package sales and session ledger integration |
| Staff directory | Existing staff and doctor list with name and phone | National ID, birth and hire dates, working days and hours, booking cues |
| Invoicing and collection | Self-pay invoices, quantities, discounts, doctor and optional examining senior doctor, cash/Visa installment receipts, balances, PDFs | Insurance company, approval number, patient/insurer split and deferred insurer settlement |
| Returns and refunds | Quantity-based returns, required reason, debt reduction and separate refund | Package and insurance return rules |
| Insurers | Self-pay workflow available | Companies, contracts, price overrides, patient share, insurer statements and settlements |
| Reports | Filtered invoice and collection registers with CSV export and per-invoice outstanding amounts | Daily/monthly collections report, selected doctor revenue, center revenue, combined doctor totals, patient outstanding report, insurer invoices, referrals, service quantities and revenue |

Requirement 4 was explicitly skipped. The self-pay register and PDFs are
available in the deployed pilot. Confirm client document conventions and the
remaining financial policies as the subsequent slices are built.

## Verification

Run `test/billing_workflow.sql` and `test/billing_allocations.sql` on a disposable
database with the full schema.
Run the rendered workflow checks with
`flutter test test/previews/billing_pilot_render_test.dart`.
Use `UI_POLISH_CAPTURE` as a Dart define to save the preview renders locally.

