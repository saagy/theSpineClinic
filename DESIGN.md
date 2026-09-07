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
  primary is `#2563EB`. The former teal design reference is obsolete.
- Plus Jakarta Sans typography is selected by `AppTextStyles`. Existing fonts
  and token values can be reassessed during the visual pilot.
- `AppShell` currently switches between bottom navigation and a navigation rail
  at 600 logical pixels. This is existing behavior, not a fixed future breakpoint.
- Shared widgets include patient rows, search, filters, buttons, avatars, sheets,
  and async-state views. Their presence does not establish their UX suitability.
- Existing rounded cards, pill buttons, and accent avatars are implementation
  details, not a requirement to reproduce them throughout the overhaul.

## Product Experience

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

### Accessibility and Tokens

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
1. Patients directory redesign established the clean modern 2026 SaaS aesthetic (hairline dividers, monogram badges, Lucide icons, high density, and clean table/list responsive layouts).
2. Schedule screens (Receptionist & Doctor) implemented:
   - Modern medical agenda & timeline, strictly chronological by scheduled time.
   - High-density 2-line agenda rows (`AppointmentAgendaRow`, minHeight 58px mobile, 62px desktop) with hairline dividers.
   - Restrained status indicators: compact tonal "Check In" button for scheduled items, subtle green "Checked In" badge, muted cancelled styling.
   - 3-dot menu sheet (`AppointmentRowActionsSheet`) for secondary actions (details, edit, cancel, restore).
   - Minimal header with branch selector and primary "+ New Appointment" CTA; modernized 7-day week strip with dot indicators and sleek day pills.
   - Role-aware density: doctor names omitted on doctor's own schedule.
