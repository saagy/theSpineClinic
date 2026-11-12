# Billing workflow review (billing plan slice 8)

November 12, 2026. Local release web build (`flutter build web --release`)
served at `localhost:8000` and connected to the linked "the spine" project,
which holds the demo invoice seed. Signed in as the payment receptionist in
the in-app browser. The user approved test writes on one fictional patient,
**Billing Review Test (ID 110)**, created for this review. Credentials are not
recorded here.

## Writes exercised against the live project

| Step | Result |
| --- | --- |
| Register the fictional patient with an assigned doctor | Saved; doctor shown as attending staff. |
| New invoice: 6 PT sessions + initial assessment, 1,000 cash + 500 Visa | TG-00107 issued with receipts TG-00113/114; assigned doctor pre-filled on both lines; 6 PT sessions added to the balance; 1,500 due. |
| Record payment above the due (2,000) | Rejected inline: "Enter 1,500 EGP or less". |
| Record payment 500 cash | Receipt TG-00115; page behind the panel refreshed. |
| Refund 4 sessions, value 1,500, with 500 paid back | Form required a payback method and reason; refund TG-00006 recorded; invoice value 1,500, due 0, PT balance 6 → 2. |
| Correct or void an earlier receipt after the refund | Both listed and disabled with "Void the later refund first". |
| Void the refund | Value, paid amount and the 4 sessions restored. |
| Correct the invoice, dropping the assessment | TG-00108 replaces TG-00107; the three receipts moved with their original received times (TG-00116–118); PT balance unchanged at 6. |
| Void receipt TG-00118 | Paid 1,500, due 900; shown voided with who, when and why. |
| Record the last 900 by Visa with a double click (phone width) | Exactly one receipt (TG-00119); invoice Paid. |
| Empty new invoice (phone width) | "Add at least one service." inline; nothing saved. |

Database checks after the writes: TG-00107 is voided with nothing collected;
TG-00108's line allocations add up to its collected money; the patient's PT
balance matches the remaining sessions.

## Reports read against live data

- Daily money (today and last month): receipts and paybacks, receptionist
  totals and the void log all matched the writes above. Displayed times
  matched the database's Cairo time.
- Doctors summary for last month totals 94,465 EGP, equal to Daily money's
  99,115 received minus 4,650 paid back.
- Doctor revenue for the assigned doctor today: 2,400 EGP, all of TG-00108's
  collected money; the voided invoice is excluded.
- Services and Outstanding rendered with live data; report rows open the
  invoice panel in place.

Desktop (1440×900, light) and phone (390×844, light and dark) were both
reviewed; the dark theme was set from Profile and restored to light after.

## Staff employment details (super admin)

Signed in as the super admin. On an existing doctor's record, working days
Saturday–Thursday, hours 9:00 AM–6:00 PM and a hire date were saved; the
`staff_details` row matched, `updated_by` named the admin, and the directory
showed `Sat–Thu · 9:00 AM – 6:00 PM`. Reopening loaded the saved values with
Save disabled until a change. Clearing every field saved empty values and
removed the directory line, leaving the record as it was before the test.
Discarding an unsaved edit changed nothing.

## Fixed during the review

- **Summary kept in view on wide forms.** The new-invoice, refund and
  correction forms' live summary scrolled out of view while editing lower
  sections. `FormPageBody` now takes an `aside`: from 900 px of content the
  form scrolls in its own column and the summary stays beside it; narrower
  windows place it after the form (`shared/widgets/form_page_scroll_area.dart`).
- **Voided refunds** showed two lines both labelled "Reason:". The second now
  reads "Void reason:" (receipts too).
- **Refund reason hint** claimed the reason appears in the void log; it now
  says it is shown on the refund and its printed copy.
- **Overview due banner** used title case ("Total Outstanding"); it now reads
  "Amount due", matching the Payments tab.
- **Working hours message** appeared as soon as a start time was chosen, and
  under both fields when one was cleared. It now shows only under the empty
  field of the pair, and for a start time alone only when saving.
- **Time picker AM/PM** used a pink tint generated from the seed color. The
  theme's tertiary colors now come from the clinical palette (this also
  turns the doctor-row badge from purple to the palette blue).

## Not verified here

- **Printing.** The in-app browser ignores the print request (no dialog, no
  console error). PDF generation is covered by widget tests; printing needs a
  check in a regular browser.
- **CSV export download** was not triggered (it saves a file to the device).
- Not part of billing but noticed: the patient registration form's optional
  Personal details use a different field style from the section above, and
  its clinic selector is a plain Material dropdown rather than the shared
  record menu.

`flutter analyze`: no issues. `flutter test`: 617 passed.
