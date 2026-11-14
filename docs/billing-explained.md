# How billing works

A plain explanation of the clinic's billing, from the first invoice to the
reports, written for the people who run the clinic rather than for
developers. Every rule here is what the app and database actually do
(checked against the database code on November 13, 2026). The design
decisions behind them are in [the billing plan](billing-plan.md).

## 1. The four documents

Everything in billing is one of four documents. Each has its own number
series per branch: Tagamoa numbers start with **TG-**, Masr El Gedida with
**MG-**, Madinaty with **MD-**. Numbers are never reused, even when a document is cancelled.

| Document | What it records | Who can create it |
| --- | --- | --- |
| **Invoice** | What the patient is charged: services, quantities, doctors, discount, date. | Any receptionist |
| **Receipt** | Money the patient handed over, by cash or Visa, against one invoice. | Any receptionist |
| **Refund** | A patient-requested reduction of an invoice, with any money handed back. | Payment receptionists and the admin |
| **Cancellation** | Not a separate document: a cancelled invoice, receipt or refund stays visible, marked CANCELLED, with who, when and why. | Payment receptionists and the admin |

The key idea: **an invoice is a promise to pay; a receipt is money actually
received.** A patient can have an invoice and no receipt (they owe the
whole amount), or several receipts against one invoice (they pay in parts).

## 2. Services and prices

The service catalog (Billing > Services and prices) lists what the clinic
sells. Each service is either a single session or a package of N sessions of
one type: PT session, spinal traction, initial assessment, reassessment, or
other. A service also says whether doctors can be credited for it; traction
is done without a doctor and never credits one.

Prices are copied onto the invoice when it is made. Changing a price later
does not change old invoices.

## 3. Making an invoice

An invoice has:

- **A date.** Today or an earlier day, never a future one. The real time it
  was entered is also stored.
- **A branch.** Receptionists with a branch always invoice at their branch.
- **Lines.** Each line is a service and a quantity, at the catalog price.
- **Doctors on each line.** Zero, one or several doctors per line. This is
  how the clinic knows who brought in the money (section 8).
- **An optional discount** on the whole invoice, as a percentage or a fixed
  amount. Only payment receptionists and the admin can give one. A 100%
  discount records free sessions while still keeping a record.

**How a discount is spread.** The discount is shared between the lines in
proportion to their prices, so every line knows its own price after
discount. That figure is the **Total price** shown in the reports.

> Example. 6 PT sessions at 3,000 plus 6 traction sessions at 1,000 is
> 4,000. A 10% discount (400) is split 300 to PT and 100 to traction. PT
> now costs 2,700 and traction 900. The invoice total is 3,600.

**Sessions are added immediately.** As soon as the invoice is made, its PT
and traction sessions are added to the patient's balance, whether or not
anything is paid. The patient can start their sessions before paying.
Packages never expire.

**Sessions are used at check-in.** A package session is taken off the
balance when the appointment is checked in, not when it is booked. Booking
only checks that enough sessions are left for all the future package
appointments already booked.

## 4. Taking payments (receipts)

A receipt is money received against one invoice, by cash or Visa. If a
patient pays part cash and part Visa, that is two receipts. A receipt can
never be more than what is still due on the invoice, so an invoice is never
overpaid.

Each receipt is dated by **when the money was received** and belongs to the
**branch where it was received**. This is what makes the daily report match
the drawer.

**Where each payment goes.** A receipt is split across the invoice's lines
in proportion to what is still unpaid on each line. This decides which
services (and so which doctors) the money counts for.

> Continuing the example: PT costs 2,700 and traction 900, so unpaid
> amounts are 3 to 1. A 1,200 cash payment counts 900 for PT and 300 for
> traction. A second payment of 1,200 by Visa is split the same way. After
> both, PT has 1,800 paid and traction 600; the patient owes 1,200.

The split is worked out in whole piasters, so the parts always add up
exactly to the receipt.

## 5. Mistakes versus refunds

These are different things and the app keeps them apart.

**Cancel (a mistake).** Something was entered wrong: the wrong amount, the
wrong patient, a payment entered twice. Cancelling makes the document count
as if it never happened, in every total, including totals for past days. It
stays visible, marked cancelled, with who cancelled it, when and why, and it
is listed under Cancelled in Payments & refunds on the day it was cancelled.

**Refund (the patient's request).** The patient stops treatment, or the
clinic agrees to reduce the bill. A refund is a real event: it is dated when
it happens and may hand money back.

**Edit (correct a mistake).** Editing a receipt or invoice cancels the
original and creates a corrected copy linked to it, in one step. An edited
receipt keeps the original time the money was received, so the money stays
on the day it was really taken.

> Important: cancelling or editing an old receipt changes the totals of the
> day that receipt belonged to. A printed end-of-day report is a snapshot.
> If a past day is corrected, its report will no longer match the printout,
> and the cancelled document appears in today's Cancelled list as the trail.

**Cancelling a paid invoice.** The app asks whether the money was given back
to the patient:

- **No, it was entered by mistake:** the invoice and its receipts are
  cancelled together.
- **Yes:** that is a refund, because money left the drawer.

An invoice can only be cancelled while its sessions are unused. If the
patient has already used them, use a refund instead.

**Order matters.** Once a refund is recorded, the receipts and refunds
before it on that invoice are locked. To cancel or edit one of them, first
cancel the later refund. This keeps the money split between services
consistent.

## 6. Refunds in detail

Staff choose which line to refund, how many **unused** sessions to cancel,
the **refund value** agreed with the patient, a reason, and how any money was
handed back (cash or Visa).

The app then works out the rest:

- New invoice value = old value − refund value
- Money handed back = what the patient has paid − the new value, or zero if
  that is negative
- Balance due = new value − what the patient has paid after the payback

Sessions that are booked for the future cannot be cancelled; cancel those
appointments first.

> Example (continuing). The patient has paid 2,400 and used 2 PT sessions.
> They stop PT. Staff cancel the 4 unused PT sessions at the agreed value of
> 1,800 (4 × 450, the per-session price after discount).
>
> - New invoice value: 3,600 − 1,800 = **1,800**
> - Money handed back: 2,400 − 1,800 = **600 cash**
> - Balance due: 1,800 − (2,400 − 600) = **0**
> - The patient's PT balance drops by 4.

**What the refund does to the money split.** PT now costs 2,700 − 1,800 =
900, but 1,800 had been counted as paid for PT. The extra 900 comes off PT.
Of that 900, 600 is the cash handed back and the remaining 300 moves to
traction, which still had 300 unpaid. Only the money that no longer fits in
PT moves; traction keeps the 600 it already had. Revenue shows the refund as:

| Service | Amount | Shown as |
| --- | --- | --- |
| PT sessions (Dr. Sara, Dr. Omar) | − 600 | Cash (handed back) |
| PT sessions (Dr. Sara, Dr. Omar) | − 300 | Refund adjustment |
| Traction | + 300 | Refund adjustment |
| **Total** | **− 600** | the cash handed back |

The Cash rows of a refund always add up to the money handed back, and its
refund adjustment rows always add up to zero.

**A refund adjustment** is paid money that a refund moved from one service
to another, without any money leaving the drawer. When a refund hands
nothing back (the patient has not paid enough to be owed anything), all of
its rows are refund adjustments:

> 6 PT sessions at 3,000 (Dr. Sara) and traction at 1,200: invoice 4,200.
> The patient paid 2,100, counted as 1,500 for PT and 600 for traction.
> They stop PT and staff refund 4 sessions at 2,000. PT now costs 1,000,
> so 500 of the 1,500 counted for PT is extra. Nothing is handed back
> (2,100 is less than the new value of 2,200), so the 500 moves to traction.
> Revenue shows PT − 500 and traction + 500 as **Refund adjustment** rows.
> The patient still owes 100, all of it on traction.

Without these rows, Dr. Sara would keep credit for money that now pays for
traction. Clinic revenue does not change: the rows add up to zero.

A refund can itself be cancelled as a mistake. That restores the invoice
value, the money handed back and the sessions.

## 7. Invoice status

| Status | Meaning |
| --- | --- |
| Unpaid | Nothing paid yet. |
| Partly paid | Some paid, some still due. |
| Paid | Nothing due. |
| Refunded | A refund reduced the invoice. |
| Cancelled | Cancelled as a mistake; counts for nothing. |

**Balance due** = invoice value after refunds − (money received − money
handed back).

## 8. Doctor revenue

Doctor revenue is counted on **money actually paid**, not on what was
invoiced, and it is dated when the money was received. If a patient is
invoiced 3,000 in October and pays 1,000 in October and 2,000 in November,
the doctor is credited 1,000 in October and 2,000 in November.

A line's paid money is split **equally** between its doctors, to the piaster.
Any leftover piaster goes to one of them, so the doctors' shares always add
up exactly. Money on lines with no doctor (traction, for example) shows as
**No doctor**: it is clinic revenue only.

Doctor revenue is not doctor pay. Pay is worked out from the **Doctor
sessions** report, which counts checked-in appointments. Pay rates are not
set in the app yet.

## 9. The reports

All reports are in the Billing tab, for payment receptionists and the admin.
Receptionists with a branch only see their branch.

| Report | Answers | Dated by | One row per |
| --- | --- | --- | --- |
| **Payments & refunds** | What came into and went out of the drawer, and who took it? | When money changed hands | Receipt or refund |
| **Revenue** | What did that money pay for, and which doctor brought it in? | When money changed hands | Service line of a receipt or refund |
| **Doctor sessions** | How many sessions did each doctor do, by type? | Appointment time | Checked-in appointment |
| **Services** | What was sold, and how much of it is paid so far? | Invoice date | Invoice line |
| **Balances due** | Who owes money right now? | As of now | Patient |

**How they relate:**

- **Payments & refunds and Revenue are the same money**, cut two ways. For
  the same period and branch their totals are equal. Payments & refunds
  lists each receipt once, so the drawer can be checked receipt by receipt.
  Revenue splits each receipt across the services and doctors it paid for.
- **Services does not match them**, on purpose: it starts from invoices made
  in the period and shows what has been paid on those invoices up to now,
  whenever that money came in.
- **Doctor sessions has nothing to do with money.** It counts appointments
  checked in, for working out doctor pay.
- **Balances due ignores the period.** It is always today's picture.

**Payments & refunds figures:**

- **Cash** = cash received − cash refunded. This is what the drawer should
  hold from the day's business (plus any opening float).
- **Visa** = Visa received − Visa refunded. This should match the card
  machine's settlement for the day.
- **Total** = Cash + Visa.
- **By receptionist** shows the same per person, for shift handover.
- **Cancelled** lists documents cancelled that day. They are not in any total.

## 10. A suggested routine

These are standard front-desk controls; the app supports them today.

**End of each day, per branch**

1. Open Payments & refunds, Today, your branch. Print it.
2. Count the cash. It should equal the **Cash** figure (plus the float
   kept in the drawer, if any).
3. Compare **Visa** with the card machine's end-of-day slip.
4. Look at **Cancelled**. Each cancellation should have a sensible reason.
5. Sign the printout and keep it with the cash.

**End of each month**

1. **Doctor sessions**, Last month, All doctors: print. Each doctor's
   sessions print on their own page. Resolve "Not checked in yet" first.
2. **Revenue**, Last month: the By doctor table shows what each doctor
   brought in.
3. **Balances due**: follow up with patients who owe money.

## 11. What the app does not do (yet)

- **Opening float and cash count.** The app does not record the cash left in
  the drawer at the start of the day, or the count at the end. The daily
  report gives the expected figure; the count is done on paper.
- **Expenses.** Money taken out of the drawer for anything other than a
  refund (supplies, petty cash) is not recorded.
- **Doctor pay rates.** Sessions are counted, but rates per session type are
  not defined (see AGENTS.md technical debt).
- **Tax e-receipts.** Not needed, per the client.
- **Insurance.** Out of scope.
- **Visa refunds** are recorded as Visa; whether the card was actually
  credited is handled at the card machine.
