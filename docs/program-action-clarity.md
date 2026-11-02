# Program action clarity

## Audit and scope

The user identified ambiguity in program/treatment-plan actions and requested
desktop/mobile support plus a Programs-subtab three-dot menu in place of the
navigation chevron. The user explicitly retained the treatment-plan menu. The
November 2 follow-up reserves overflow for permitted mutations and uses the
existing record-menu treatment for program status.

- Identical overflow menus represented program deletion, program status and plan actions.
- Active meant both program lifecycle and the selected plan.
- The global pencil did not explain that it edits program conditions/findings.
- New Plan Version opened a blank plan, selected as active by default.
- Activating a saved plan did not explain which current plan it replaces.
- Previous Plan Versions implied immutable history despite editable saved plans.
- Inline heading/action rows crowded small windows and enlarged text.
- Read-only users opened a three-dot menu containing only View Details, duplicating
  the row's navigation action.
- Permitted users could not change status from the program row.
- The status picker used a default text-only checked popup rather than the styled
  icon-led record menus used for other card actions.

## Implemented behavior

- Program status has a named dropdown beside the program context. It uses shared
  `RecordActionMenu` styling, a disabled checked current value, and icon-led
  Complete/Archive/Reactivate actions. Read-only users see a labeled status. The
  control and Edit program details wrap on small windows.
- Current treatment plan names the selected plan and retains its three-dot menu:
  Create new treatment plan, Edit this plan, Delete this plan.
- Creating from the current plan copies its modalities, regions, durations and
  notes into a distinct record. Saving cannot overwrite the source ID. Editing
  retains the existing record ID and explains that it updates the saved record.
- The form explains the selection consequence and uses Save and use plan versus
  Save plan. Selecting a plan does not change program status.
- Other saved plans remain editable. Use this plan confirms the new and previous
  plan names. Cancelling makes no repository call. This is not immutable history.
- Programs-subtab rows remain tappable. Active senior doctors and super admins get
  Change status, Edit program details and Delete Program. Change status opens the
  same styled status choices at the record action button. Other users get a
  keyboard-accessible navigation chevron with a minimum 44px target.
- Status selections recheck `currentUserProvider` and pending mutations before
  calling the existing controller. Success refreshes the list and details without
  changing the treatment plan. Completed/archived programs move into the existing
  collapsed history section. Deletion retains confirmation and refreshes.
- Confirmation dialogs use native keyboard-focusable controls with wrapping
  actions. Program controls use existing AppSizes, AppTextStyles and theme tokens.

## Validation

`flutter analyze` reports no issues. All 45 targeted tests pass across
`program_actions_ux_test.dart`, `treatment_plan_detail_ui_test.dart`,
`treatment_plan_builder_ui_test.dart`, `program_ui_test.dart` and
`program_actions_render_test.dart`, plus `agenda_menu_actions_test.dart` and
`context_menus_interaction_test.dart`. The Impeccable detector reports no findings
for the changed widgets.

Validation uses real Flutter widgets with fictional repository fixtures, not
production patient records. Tests cover status/plan independence, copied-plan
creation versus editing, named switch confirmation/cancellation, keyboard
activation through both menus, read-only doctor/receptionist chevrons, and
Programs-tab navigation. They also check saving an unselected copy, status and
deletion refreshing the Programs tab, and the current status being disabled.

Rendered checks cover 320, 390, 768 and 1280 logical-pixel widths in light and dark
themes, plus long plan names at 360 pixels with 1.5x text scaling. Captures stay
outside the repository. List menus and status choices are additionally captured
at 320/1280 pixels in both themes, with read-only chevrons at 390 pixels and
enlarged status choices at 360 pixels. The affected-regions heading wraps with enlarged
text, and the plan switch has its own Material surface for visible interaction.

Live Supabase mutations and physical-device interactions are not exercised by
these fixture-based checks.

## Other menu usage audit

Source inspection found no other action popup using the status picker's former
unstyled `CheckedPopupMenuItem` implementation. The appointment, treatment-plan,
note, payment, document, due-patient and doctor-replacement menus already customize
their popup surfaces and action rows.

| Remaining variation | Location and scope |
| --- | --- |
| Text-only choices in a styled popup | `receptionist_branch_dropdown.dart`; custom surface/border/type, unlike the former default status popup. |
| Partially styled legacy delete popup | `patient_profile.dart`; no callers of `PatientProfile` remain in the app. The current patient workspace uses `WorkspacePatientMenu`. |
| Native text-only form selections | Registration branch (`AppDropdown`), patient create/edit clinic fields, receptionist profile branch, and staff role/branch fields. Staff and profile selectors already apply some popup styling. These are form selections, not record action menus. |
| Native legacy filter selections | `patient_list_filters.dart` has no callers; `reports_filter_bar.dart` belongs to the independent legacy reports screen. The body-region filter has its own themed icon-led dropdown. |

Only the requested program menus changed in this pass; the inventory above is
source-based, without a rendered audit of each unrelated form/filter popup.
