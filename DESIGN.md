# Design Guidance

## Status and Scope

The UI overhaul was authorized on 2026-09-06. This document defines its working
principles; it does not claim redesigned screens have shipped. The screen order
and audit backlog live in [docs/ui-overhaul.md](docs/ui-overhaul.md).
The product context is [PRODUCT.md](PRODUCT.md); engineering constraints are in
[AGENTS.md](AGENTS.md).

The user welcomes complete replacement of unsuitable screen layouts and visual
components. Preserve supported tasks, role restrictions, reliable mutations,
and data integrity. Reusing an existing widget is a choice based on suitability.

## Implemented Baseline

- Material 3, with light and dark themes in `lib/core/constants/app_theme.dart`.
- Clinical-blue palettes in `lib/core/constants/app_palette.dart`; the light
  primary is `#2B4D73`. The former teal design reference is obsolete.
- The dark theme now uses a charcoal canvas, lighter content surfaces, quiet
  blue-gray borders, and soft blue action color with dark text on filled controls.
  Status colors are muted while retaining their meanings. See the
  [dark-theme audit and validation](docs/dark-theme-polish.md).
- Plus Jakarta Sans typography is selected by `AppTextStyles`. Existing fonts
  and token values can be reassessed during the visual pilot.
- `AppShell` currently switches between bottom navigation and a navigation rail
  at 600 logical pixels. This is existing behavior, not a fixed future breakpoint.
- Shared widgets include patient rows, search, filters, buttons, avatars, sheets,
  and async-state views. Their presence does not establish their UX suitability.
- Existing rounded cards, pill buttons, and accent avatars are implementation
  details, not a requirement to reproduce them throughout the overhaul.

## Product Experience

Billing pilot uses aligned financial registers at wide widths and patient-led
rows on compact or enlarged-text layouts. The invoice editor keeps amounts in
a separate summary on wide windows and below the service lines on phones.
Patient identity, invoice total, outstanding debt, and refundable amounts
have distinct labels. Transaction history keeps receipts, returns, and refunds
separate, with printing on the corresponding document. See
[Billing pilot](docs/billing-pilot.md) for the desk workflow.

Patient rows put the permanent ID on a quiet line below the name. Optional
demographics, referral, and insurance membership live in patient details.
The billing directory uses the shared search field and bottom sheet, with
explicit page controls and patient ID and branch beneath the name.

Staff use the app at a reception desk and on phones during clinic work. The
interface should make finding a record, recognizing its state, and taking the
next permitted action quick and unambiguous. Use a calm visual treatment with
enough density for repeated daily work.

### Hierarchy and Information

- Give each screen a clear purpose, title/context, and primary action.
- Patient identity and task-relevant information lead; decoration and redundant
  metadata should not compete with them. Keep names readable and handle long text.
- Use aligned columns for comparable data when space permits; use readable rows
  on narrow windows. Do not stretch mobile cards to fill a desktop viewport.
- Use cards for meaningful groups. Rows, separators, tables, and unboxed sections
  are valid alternatives. Avoid nested containers that add no useful grouping.
- Use accent for actions and selection; communicate status with text or icons as
  well as color. Repeated status treatment should not overwhelm the work queue.
- Use one coherent type scale and tokenized spacing hierarchy. Related controls
  can sit closer together than separate sections. Readability outranks decoration.

### Responsive Structure and Interaction

- Screen app bars match the page canvas in light and dark mode, including
  while scrolling. Use the shared record menu for popup actions and compact
  selections. The selected option has a checkmark.
- Billing is a primary destination for receptionists with payment access on
  both the bottom navigation bar and the side rail. Admins open Billing from
  the Admin hub.

- Design mobile and desktop views together. Adapt to the available window space,
  including narrow desktop windows, and support intermediate widths.
- Choose navigation and action placement for the available space. Large windows
  may use toolbars, columns, and detail panels; narrow windows may use stacked
  content, bottom navigation, or dedicated detail routes.
- Group frequent search/filter controls; disclose secondary controls progressively.
  Keep active filter state and its clear/reset action understandable.
- Choose inline editing, a dialog, a sheet, or a dedicated page based on task
  complexity and available space. Complex forms need room for review and editing.
- Keep identity and relevant context visible during actions. Preserve applicable
  branch, selected date, search, and list position across detail/back navigation.
- Use task-specific labels: an exercise selector should say "Exercise", even if
  its stored field is called `target_region`. UI text still comes from AppStrings.
- Make focus, hover, pressed, disabled, submission, and failure states clear.
  Essential actions must work without hover; guard against duplicate submissions.
- Motion communicates state and respects reduced-motion preferences. It must not
  delay routine actions or hide content behind decorative entrance sequences.
- Patient record sections use a short, top-aligned fade from skeleton to loaded
  content. Late fields such as staff names keep their leading edge fixed while
  fading in place. Appointment details use the same restrained motion and show
  skeletons rather than generic text while related records resolve. Late linked
  sessions enter with a short fade and height adjustment.

### Accessibility and Tokens

- Document uploads explicitly opt into a slim native linear activity track with short
  status text, preserving the current form and scroll position. Ordinary saves use
  button-local activity. Authentication uses a labeled pending button without a
  blocking panel; remaining blocking mutations use a compact contextual spinner.
  Unfinished files
  keep visible recovery actions. The track uses estimated nonnumeric fill while
  the request is pending; only the real result completes the operation. Reduced
  motion uses discrete fill updates. Program form removals hide immediately as
  unsaved edits: Save commits them with program changes, Cancel discards them,
  and failed saves retain the draft. Explicit document-list deletion remains a
  separate confirmed action. Picker close buttons keep 44px targets and stable previews.
  See [save feedback](docs/save-feedback.md) for scope and the session-limited
  recovery boundary.

- Use theme color schemes/extensions, AppTextStyles, AppSizes, and AppStrings.
  Add semantic tokens when a new reusable role is needed; avoid inline exceptions.
- Keep touch targets at least 44 logical pixels, separate destructive actions,
  support keyboard traversal and activation, and provide meaningful semantics.
- Check normal text contrast at 4.5:1 and large text at 3:1; verify light and dark
  modes, text scaling, validation messages, and long content.
- Explicitly design loading, error/retry, empty, filtered-empty, and populated
  views. Preserve context during refresh; distinguish no results from failure.

## Design Decisions and Validation

1. Audit the current screen and list its tasks, information, actions, and problems.
2. Gather a small set of relevant product references and identify the specific
   visual and interaction qualities to adopt. Use them to develop Patients pilots
   on mobile and desktop with representative fictional data.
3. Recommend a direction and obtain visual feedback before applying it broadly.
   The user does not need to supply finished designs or exact token values.
4. Implement and inspect the pilot at mobile, intermediate, and desktop widths.
   Exercise real interactions and non-happy-path states; a mockup is insufficient.
5. Test the emerging system on schedules before treating it as established.
6. Record adopted typography, density, shape, navigation, and component decisions
   here with links to implementation. Keep disposable previews and captures
   outside the repository unless explicitly requested. Keep proposals
   distinct from implemented behavior; do not call unreviewed work approved.

Current decision status:
Program detail separates the program's lifecycle from its selected treatment plan.
The program header uses a labeled status dropdown. Program editing stays in the
fixed app bar, with contextual Edit actions beside conditions and clinical
findings, plus a separate Documents section. These shortcuts open the existing
editor at the corresponding section and preserve the program's scroll position
on return. The program overflow also exposes Edit and Export PDF above separated
deletion. See [program editing access](docs/program-edit-access.md).
The current treatment plan retains its scoped three-dot menu. New plans copy current treatments into a new
record; edits update the selected record. Other saved plans use a named switch
confirmation. Permitted Programs-tab users get Change status, Edit and Delete;
read-only users get a navigation chevron. Both status entry points use the shared
icon-led record menu. See [program action clarity](docs/program-action-clarity.md).

The September 13 shipping-polish directions were explicitly selected by the user
and implemented. See [the audit and validation](docs/shipping-ui-polish.md).
The user selected the density correction: all appointment actions are in the
three-dot menu, led by Check in / Undo check-in / Restore as appropriate. Outside
status is passive (clock / green check / cancelled symbol); compact rows keep
identity and type together without an extra action line. Wide rows retain aligned
columns and passive status labels. Appointment names fit between 14 and 13 logical pixels before wrapping in full; enlarged accessibility text is never reduced. Types wrap instead of clipping.
Patient tabs use the slate scaffold with separate overview group surfaces.
Create/edit forms use semantic sections, responsive columns and persistent actions.
November 2 staff cleanup inherits clinical blue and Plus Jakarta Sans: flat rows,
quiet initials, status text, compact confirmed review actions and a labeled Add.
Staff forms extend bounded sections with external labels, persistent Save/Cancel and explicit account/password tasks. See [staff editor decisions](docs/staff-editor-flow.md).
Profile editing extends this form system with separate password navigation, preserved contact drafts, guarded actions and contact fields that stack for enlarged text. See [adopted flow and validation](docs/profile-edit-flow.md).
Shared filter frames, sort options and doctor selection now serve Patients,
Schedule, appointments, doctor history and staff with separate feature state.
Older patient-note/appointment sheets remain. See [scope and rendered validation](docs/staff-ui-cleanup.md).

Appointment creation now preselects the patient's assigned doctors once on patient
selection and preserves that selection across appointment type changes. Assessment
types show a review reminder; the doctor picker labels senior doctors. Package
billing retains its prior session choice when staff switch to an assessment and
back. Check-in uses the same status controller and actionable balance error in
agenda and detail views.

The final patient-workspace pass treats program document folders as flat rows with
the same hairline separators as standalone documents. Folder names appear only
after the related program data resolves; note author placeholders hold a fixed
leading position. Booking uses quiet underlined queue tabs and matching flat rows
for due patients and scheduled appointments. Due-patient actions stay at least
44 logical pixels and move below the identity when a narrow layout or enlarged
text needs the space. Initial record, result-list, and form loading use shaped
placeholders; progress indicators remain for local actions and file viewing.

0. Patient detail now implements the [patient workspace direction](docs/patient-workspace-direction.md)
   with a corrective pass after the first pilot was rejected. It uses the current
   palette, Plus Jakarta Sans, text tabs, flat sections with heading rules,
   compact fact grids and 8px control corners. The September 13 correction
   uses the slate scaffold behind the app bar, tabs and list content, with white
   bordered overview groups and a desktop summary rail. Medical history uses the same flat heading rule as patient
   facts; document folders are rows within one group, without nested cards.
   Compact primary actions use a surface background, blue icon and outline
   with a 44px minimum target. Native text tabs animate their indicator and
   horizontal reveal without scrolling the outer page. Doctors see active programs and
   medical history first, with no outstanding balances. Reception sees
   warning-colored outstanding balances and basic details. Both see upcoming
   visits. Overview is a single full-width reading column so unrelated sections
   never form uneven paired cards. Patient/attending-staff initials avatars are
   reused from Patients; phone stays in Patient Details. History is one list with
   contextual date/time within each appointment row. Program folders open the
   existing gallery; private image previews use authenticated repository bytes.
   Program detail is treatment-first, and medical-history/treatment-plan editors
   use a bounded form with a persistent Save/Cancel footer. Payment mutations
   retain the existing capability checks.
   Payment history keeps aligned amount and action columns when space permits.
   Narrow rows give the full reason its own line, then show amount, due, metadata,
   and a separate Collect Due action. Summary figures stack at very small widths
   or with enlarged text; light and dark surfaces use the same structure.
   Target-region selection uses a compact themed field that opens the same
   searchable selection step within the existing editor at every window size.
   Back returns to the unchanged form; selecting returns with the chosen region.
   The list fills the remaining sheet height with a visible scrollbar, and search
   does not automatically open the keyboard. The active selection stays visible and
   marked by the theme's selected state; every option keeps a 44px target.
1. Patients directory redesign established the clean modern 2026 SaaS aesthetic (hairline dividers, monogram badges, Lucide icons, high density, and clean table/list responsive layouts).
2. Schedule screens (Receptionist & Doctor) implemented:
   - Modern medical agenda & timeline, strictly chronological by scheduled time.
   - High-density 2-line agenda rows (`AppointmentAgendaRow`, minHeight 58px mobile, 62px desktop) with hairline dividers.
   - Restrained status indicators: neutral scheduled clock, solid green checked-in check, muted cancelled styling. All actions live in the three-dot menu.
   - 3-dot menu sheet (`AppointmentRowActionsSheet`) for secondary actions (details, edit, cancel, restore).
   - Minimal header with branch selector and primary "+ New Appointment" CTA; modernized 7-day week strip with dot indicators and sleek day pills.
   - Role-aware density: doctor names omitted on doctor's own schedule.
