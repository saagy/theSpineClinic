# Billing reports redesign

November 13, 2026. Agreed with the user in conversation; replaces the seven
Billing tabs of slice 6 (see [the billing plan](billing-plan.md)).

## Why

Front-desk staff are not finance specialists, not very technical, and not
native English speakers. The Billing tab exists mainly to answer "what came
into and went out of the drawer", plus the client's report list (insurance
and referral reports are out of scope). Everything must be readable at a
glance and need no typing.

## Audit of the previous screen

1. Seven tabs; Revenue, Doctor revenue and Doctors summary were three cuts
   of the same collected money.
2. Doctor revenue opened on an empty "Choose a doctor" state.
3. Names did not say what the report answers ("Daily money", "Outstanding",
   "Doctor sessions" beside "Doctor revenue").
4. Finance jargon: Collected, Credited to doctors, No doctor credit,
   Allocations, Reallocated, Billed.
5. Tables needed about 990-1080 px for columns, so on common laptop widths
   every row fell back to the stacked layout and doctor names were buried
   in a long grey line.
6. Doctor revenue dropped the Price column the client asked for.
7. Daily money figures mixed net and gross amounts (Net cash, Net Visa,
   Received, Paid back) without saying how they relate.
8. The cancelled-documents and receptionist sections showed even when they
   added nothing.
9. Phones scrolled seven tabs sideways.

## Decisions

Five reports, each answering one question:

| Report | Question | Basis |
| --- | --- | --- |
| Payments & refunds | How much cash and Visa came in and went out, and who took it? | Receipt received time, refund recording time |
| Revenue | What did the money pay for, and which doctor brought it in? | Same money, split by invoice line |
| Doctor sessions | How many sessions did each doctor do, by type? | Checked-in appointments |
| Services | What was sold, and how much of it is paid? | Invoice date |
| Balances due | Who still owes money? | As of now |

Payments & refunds and Revenue stay separate on purpose: the first lists each
receipt once so the drawer can be checked receipt by receipt; the second
splits each receipt across services and doctors. Their totals match, and
Revenue's description says so.

- **Payments & refunds** leads with Cash, Visa and Total after refunds,
  each with a "Received · Refunded" line beneath. All payments and refunds
  lists every receipt and refund; By receptionist shows each person's net
  cash and Visa; Cancelled appears only when something was cancelled. For a
  single day, rows show the time only.
- **Revenue** replaces the three revenue tabs. With all doctors it shows a
  By doctor table (cash, Visa, total; lines without a doctor as "No doctor")
  above every payment line: date, patient and ID, service, doctors, method,
  price, paid. Choosing a doctor (picker or tapping their row) shows that
  doctor's lines with price, paid and their share; split lines say so. The
  app reads `invoice_report` kinds `revenue` + `doctors`, or `doctor`; no
  database change.
- Plain, standard words (revised with the user the same day, after a first
  pass was too simplified): Paid, Refunded, Total price (never a bare
  "Price"), Balance due, Open invoices, Due since, Received by, Quantity,
  Refund adjustment (a refund that moves paid money between services
  without handing any back), No doctor. "Patient ID" stays; "File no." is
  not used. [How billing works](billing-explained.md) explains each term.
- Table cells can carry a quiet second line (patient ID under the name, time
  under the date, number under the document kind), so the tables fit about
  900 px and keep the doctor in its own column.
- From 640 px the reports are tabs; below it a full-width Report menu with
  icons replaces sideways-scrolling tabs.
- The selected report and filters are kept while the app is open, so going
  back to Billing returns to the same report.
- Printing, paging, capped rows, error with Retry and empty states keep
  their slice 6 behavior.

## Live check (November 13, 2026)

Release web build against the linked project, signed in as a Tagamoa payment
receptionist, at phone width and 1366 px; read-only. This month at Tagamoa:

- Payments & refunds showed Cash 12,925 (received 14,925, refunded 2,000),
  Visa 13,375, Total 26,300, matching a direct query of active receipts and
  refunds.
- Revenue's total, Cash and Visa matched Payments & refunds; the By doctor
  rows added up to 26,300. Tapping Dr. Mona Mahmoud showed her share
  (11,408.15, equal to her By doctor row), Total price on every line and
  "Split between 2 doctors" on shared services.
- Doctor sessions, Services and Balances due rendered with live data.
- Fixed during the check: the empty state no longer suggests another branch
  to receptionists who have none; Received and Refunded sit on separate lines
  under each total; switching report opens the new report at its top.

Printing to a physical printer and the light/dark switch in a live session
were not exercised; dark mode was checked in rendered previews.
