# Patient record: fold personal details into the record

Date: 2026-11-14. Status: approved in conversation.

## Why

Address, nationality, gender, date of birth, second phone and referral source
were added as a "Personal details" card at the top of the Overview tab. It
reads as bolted on: identity facts sit below the fold, contact facts are split
between the sidebar and the card, the primary phone appears twice, and the
next-visit block is a card inside a card.

## Design

- **Identity in the header** (patient banner pattern): under the name, beside
  the ID and branch, show sex, age and date of birth (`Male · 38 yrs · 12 Nov
  1988`), only the parts that are known.
- **Contact block in the sidebar**: primary phone, second phone (both open
  the call/WhatsApp sheet) and address. The duplicate "Phone" metadata row is
  removed.
- **Registration rows**: Registered, Last visit, Referral source,
  Nationality.
- **Overview** loses the Personal details card; it keeps what is due, the
  next visit, programs and medical history.
- **Next visit** is no longer a card inside a card; a past date reads as
  overdue.
- **One Edit entry**: the sidebar Edit button stays, the duplicate app-bar
  pencil goes (the patient menu keeps its actions).
- **Phones**: the narrow layout's info section carries the same contact and
  registration rows, placed right after the header instead of at the bottom.

## Approaches

Restyling the card in place was rejected: the problem is placement, not
looks. Moving every fact to where staff look for that kind of fact is the
standard patient-banner layout used by clinical systems.
