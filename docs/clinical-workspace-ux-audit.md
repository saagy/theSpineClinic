# Patient and clinical workflow UX audit — September 9

## Pre-implementation findings
1. Tab label, repeated section title, primary action and filter form four vertical layers on phones.
2. Equal overview columns pair unrelated amounts of content and leave large empty areas.
3. Header phone is unwanted; contact capability must remain in Patient Details.
4. Program details put multiple rounded containers inside a split page, diluting treatment priority.
5. Findings hide document request failures as if there are no attachments.
6. Medical-history switches use oversized cards; Save scrolls out of reach.
7. Treatment-plan basics, notes and large modality containers delay access to configuration.
8. Program mutations rely on downstream permissions and expose deletion as a top-level action.
9. Some editor labels and disclosure rows can overflow enlarged text or miss minimum touch targets.

## Direction
Use one compact toolbar per tab, single full-width overview sections with compact facts,
treatment-first program detail, and consistent bounded-width editors with fixed Save footers.
Preserve all clinical fields, version history, attachments, authorization and refresh behavior.
Audit is based on source, user-provided examples and interaction/widget tests; no browsing or screenshots.

## Post-implementation audit

The dominant hierarchy risks were addressed in code:

- Each patient tab now has one compact action row. Add, filter and sort controls
  no longer create stacked bands that push the records below the fold.
- Overview is one reading column with compact fact grids. This removes the
  uneven paired sections and keeps clinical priorities in a predictable order.
- The header keeps identity quiet and moves the phone to Patient Details.
  Doctors never receive finance sections; reception retains prominent due
  balances and payment permissions.
- Program detail is treatment-first, followed by regions and findings. Program
  deletion is an icon menu action with empty/permission guards.
- Medical-history and treatment-plan editors use bounded forms, validation and a
  persistent Save/Cancel footer, so the commit action stays available while the
  keyboard or long content is open.
- Findings surface attachment errors with retry, and program image documents
  remain grouped into the existing gallery. Appointment history is one full
  list with contextual dates and shared Schedule rows.

Validation completed with `flutter analyze` (zero issues) and the full Flutter
test suite. This audit is code and interaction-test based per the user's
instruction; a final visual pass can still tune exact spacing after the client
reviews the deployed build.
