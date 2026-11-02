# Program action clarity

## Audit and scope

The user identified ambiguity in program/treatment-plan actions and requested
desktop/mobile support plus a Programs-subtab three-dot menu in place of the
navigation chevron. The user explicitly retained the treatment-plan menu.

- Identical overflow menus represented program deletion, program status and plan actions.
- Active meant both program lifecycle and the selected plan.
- The global pencil did not explain that it edits program conditions/findings.
- New Plan Version opened a blank plan, selected as active by default.
- Activating a saved plan did not explain which current plan it replaces.
- Previous Plan Versions implied immutable history despite editable saved plans.
- Inline heading/action rows crowded small windows and enlarged text.

## Implemented behavior

- Program status has a named dropdown beside the program context, with a checked
  current value and explicit Complete/Archive/Reactivate labels. Read-only users
  see a labeled status. The control and Edit program details wrap on small windows.
- Current treatment plan names the selected plan and retains its three-dot menu:
  Create new treatment plan, Edit this plan, Delete this plan.
- Creating from the current plan copies its modalities, regions, durations and
  notes into a distinct record. Saving cannot overwrite the source ID. Editing
  retains the existing record ID and explains that it updates the saved record.
- The form explains the selection consequence and uses Save and use plan versus
  Save plan. Selecting a plan does not change program status.
- Other saved plans remain editable. Use this plan confirms the new and previous
  plan names. Cancelling makes no repository call. This is not immutable history.
- Programs-subtab rows remain tappable. Their shared three-dot menu offers View
  Details, Edit program details and Delete Program; mutation actions require an
  active senior doctor or super admin. Deletion retains confirmation and refreshes.
- Confirmation dialogs use native keyboard-focusable controls with wrapping
  actions. Program controls use existing AppSizes, AppTextStyles and theme tokens.

## Validation

`flutter analyze` reports no issues. All 31 targeted tests pass across
`program_actions_ux_test.dart`, `treatment_plan_detail_ui_test.dart`,
`treatment_plan_builder_ui_test.dart`, `program_ui_test.dart` and
`program_actions_render_test.dart`.

Validation uses real Flutter widgets with fictional repository fixtures, not
production patient records. Tests cover status/plan independence, copied-plan
creation versus editing, named switch confirmation/cancellation, keyboard
activation, role-aware menus and Programs-tab navigation.
It also checks saving an unselected copy and deletion refreshing the Programs tab.

Rendered checks cover 320, 390, 768 and 1280 logical-pixel widths in light and dark
themes, plus long plan names at 360 pixels with 1.5x text scaling. Captures stay
outside the repository. The affected-regions heading now wraps with enlarged
text, and the plan switch has its own Material surface for visible interaction.

Live Supabase mutations and physical-device interactions are not exercised by
these fixture-based checks.
