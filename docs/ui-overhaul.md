# UI Overhaul Plan

## Status

Initial screenshot/code audit, 2026-09-06. The first Patients concepts were
rejected as too dull; no redesigned Flutter screen has been implemented or
visually accepted. The user authorizes complete
replacement of unsuitable layouts and components. [DESIGN.md](../DESIGN.md)
defines working principles; [PRODUCT.md](../PRODUCT.md) defines the users.

## Screen Order

This is the initial order based on workflow coverage and shared patterns, not
measured usage analytics. Adjust it if staff observation reveals a stronger need.
Navigation and shared tokens are designed with the first screen, not as a long
standalone design-system project.

| Order | Surface | Why now | Scope |
| --- | --- | --- | --- |
| 1 | Patients + shared application shell | Clear pilot for navigation, record scanning, controls, and mobile/desktop density | Reception/admin directory, then role-scoped My Patients; search, branch, filters, sorting, count, add action, detail entry |
| 2 | Receptionist appointments + doctor schedule | Core work queues stress-test dates, status, density, and role differences | Selected day, date navigation, search, status actions, cancelled visibility; then Booking and All views |
| 3 | Patient details + appointment details | Connect the main screens into usable end-to-end workflows | Identity, overview, history, balances, clinical/document sections, permitted actions, return context |
| 4 | Patient and appointment create/edit flows | Complete the common actions reached from the main screens | Field grouping, patient/doctor selection, validation, submission, cancellation, success feedback |
| 5 | Clinical programs + treatment-plan editor | Complex form structure needs more than a cosmetic refresh | Program overview, treatment selection/configuration, exercise/region labels, notes, review/save |
| 6 | Payments + admin analytics/reports | Apply the established system to financial tasks and comparisons | Payment entry, balances, report filters, dates, branch context, readable data |
| 7 | Staff, profiles, authentication, remaining surfaces | Finish consistency after the main workflow patterns are proven | Staff tasks, account actions, login/registration, document viewers and residual states |

Patient balances and payment summaries are included in phase 3; deeper payment
entry/report design follows in phase 6. Treatment selection is audited now but
implemented after the main list/detail/form patterns have been tested.
Keep each phase to reviewable slices rather than rewriting all screens at once.

## Entry Points in the Current Code

- Shell: `lib/shared/widgets/app_shell.dart`, `app_nav_bar.dart`, `app_nav_rail.dart`.
- Patients: `lib/features/patient/presentation/patient_list_screen.dart`,
  `my_patients_screen.dart`; shared `lib/shared/widgets/patient_list_tile.dart`.
- Schedules: `lib/features/appointment/presentation/receptionist_appointments_screen.dart`,
  `doctor_schedule_screen.dart`; workboard/tab widgets beneath `presentation/widgets/`.
- Details: `lib/features/patient/presentation/patient_detail_screen.dart`,
  `lib/features/appointment/presentation/appointment_detail_screen.dart`.
- Clinical: `lib/features/medical_records/presentation/screens/program_detail_screen.dart`,
  `lib/features/medical_records/presentation/widgets/treatment_plan_builder_sheet.dart`.
- Admin: `lib/features/admin/presentation/analytics_screen.dart`, `reports_screen.dart`,
  `admin_hub_screen.dart`; payment entry under `features/payments/presentation/`.

These identify existing surfaces, not a requirement to preserve their widget trees.

## Initial Audit: Observed Problems

Evidence: the four user-supplied screenshots and selected shared/screen source.
These are visual/code findings, not a completed usability study. Inspect each
screen live and extend this audit before changing that screen.

### Patients

- Search, branch controls, sorting/filtering, and count occupy separate bands,
  giving secondary controls substantial space before the records.
- Repeated saturated avatars compete with patient identity and actionable content.
- Borders, shadows, padding, and separate cards repeat without adding useful grouping.
- Desktop rows stretch across the viewport with branch labels far from identity.
- Branch labels repeat even in a branch-filtered view; assess whether they add context.
- PatientListTile can shrink names to fit, making identity typography inconsistent.
- The floating add action visually overlaps the list in the mobile screenshot;
  verify end-of-list clearance and choose action placement deliberately.
- Screen purpose relies heavily on navigation/search; establish clear page context.

### Schedules

- Branch/date, tabs, search, utilities, month controls, week strip, and counts
  compete for attention before the daily work list.
- Repeated green surfaces, borders, and status labels dominate the sample queue.
- Date counts such as "49" need an understandable meaning; inspect their semantics.
- Repeated appointment times and identities need a deliberate scanning hierarchy.
- Icon-only utilities require clear labels/tooltips and accessible names; verify
  their actual behavior rather than inferring it from the screenshot.
- Assess Schedule, Booking, and All against their distinct tasks before retaining,
  renaming, or rearranging those navigation choices.

### Treatment Plan

- The modality chip cloud occupies much of the form before configuration begins.
- Multiple bordered/tinted nesting levels make the form structure visually heavy.
- "Target Region" labels "Plank"; the shared field label does not fit exercises.
- The desktop presentation retains a sheet drag handle and large bottom action;
  evaluate a dedicated editor or dialog layout for this task.
- Content continues beneath the visible footer area; verify scrolling, keyboard
  visibility, and access to the final fields before calling it a clipping defect.

## First Pilot: Patients and Shell

Start with three to five relevant product references. Identify what each offers
for typography, color, navigation, record scanning, or interaction, then establish
one coherent visual direction. The rejected prototypes do not constrain it.

Develop mobile and desktop pilots with fictional patient records, including long
names, short/empty names, multiple branches, and empty/filtered results. Evaluate
dedicated record navigation versus an adjacent desktop preview against actual
staff tasks and available space.

Show the shell, title/count, primary action, grouped controls, record treatment,
and selected/focus states. Do not make alternatives differ only in color.
Reassess typography, density, shape, and palette together; the current theme is
not a constraint on the new direction.

Use visual feedback to choose/refine the pilot; agents can produce the options.
The user is not expected to provide Figma files or prescribe spacing values.
After the pilot, apply the emerging patterns to a busy schedule before promoting
them into the shared system across all remaining screens.

## Acceptance for Each Implemented Slice

- Inventory current tasks and permitted actions first. Track where each remains
  accessible after redesign; UI removal must not silently remove capabilities.
- Inspect rendered mobile, intermediate, and desktop widths, light/dark themes,
  and increased text scale. Include long content, keyboard, and narrow windows.
- Exercise loading, failure/retry, empty, filtered-empty, and populated states.
- Run a real task through its outcome: find/open/return to patient; select a day
  and update an appointment; submit a form and recover from a validation failure.
- Verify relevant branch/date/filter context, scroll position, back navigation,
  keyboard focus, touch access, and floating/sticky element clearance.
- Preserve currentUserProvider permission checks, repository boundaries, async
  resilience, atomic mutation contracts, and provider lifecycle rules.
- Keep appointment status refresh callbacks intact through every list/card layer;
  verify the source queue and patient balances refresh after a successful change.
- Run flutter analyze with zero warnings/errors and relevant existing or targeted
  regression tests. Static analysis supplements rendered/interaction review.
- Keep disposable previews and captures outside the repository unless explicitly
  requested. Use fictional data and document unresolved issues.
  Record actual checks, not assumed passes; update DESIGN.md with adopted patterns.
