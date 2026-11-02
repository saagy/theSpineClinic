# Staff editor

## Audit before implementation

The administrator edits staff contact details, role, role-specific capabilities,
account access and optionally credentials. Creation uses the same form system.
Existing role restrictions, senior status, payment permission, deactivation
warnings and atomic saves must remain supported.

- Account enabled uses a switch although its effect waits for Save.
- Password editing is exposed as a checkbox rather than a named task.
- Generic Identity/Access/Account headings provide weak task hierarchy.
- Floating labels and password fields differ from the new profile editor.
- Contact fields remain one long column on wide windows.
- Permission switches inherit excessive input decoration and lack a common row.
- Self-account restrictions are disabled controls without an explanation.
- Cancel and Back can silently discard edits.
- Failures use transient snackbars and can expose internal error messages.
- A failed appointment-count query is treated as zero before deactivation.
- Deactivation queries run directly from the widget instead of a controller.
- Most deactivations have no explicit consequence review before committing.

## Direction contract

THESIS: Staff editing is a coherent administrative form with explicit account
actions; actions are never disguised as booleans.

OWN-WORLD: Inherit the profile editor's clinical blue, Plus Jakarta Sans,
external labels, compact controls, bounded sections and persistent footer.

STORY: Edit personal details and clinic permissions; stage access or password
changes deliberately; review and save the complete edit together.

FIRST VIEWPORT: A back/title bar and bounded personal-details section followed
by clinic access and account security. Wide contact fields pair; narrow or
enlarged text stacks. Save/Cancel remain reachable above the keyboard.

FORM: Local extension of the established form system; no concept seed required.
Use ordinary native control and disclosure transitions.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance

## Adopted implementation

The editor uses Personal details, Clinic access and Security sections in the
existing `FormPageBody`/`FormSection` system. The form remains bounded at 720 logical
pixels. Standard and FormBuilder fields share `appInputDecoration` and
`LabeledFormField`: external labels, compact 6-pixel control corners, theme-aware
focus/error/disabled states, autofill and next/done keyboard actions.

`FormFieldPair` pairs email/phone and role/branch at 480 pixels of available group
width with text scale at most 1.3; otherwise they stack. One `Flex` preserves field
state, focus and selection across resizing and role changes. `FormActionRow`
aligns explanation and action from 600 pixels of content width at the same text
scale limit; narrower or enlarged-text layouts stack them. Touch targets remain
at least 44 logical pixels through `AppSizes`.

Account access shows saved or draft status with an explicit Activate on save or
Deactivate on save action and Undo access change. It is never an immediate switch.
Change password opens an inline administrative task; Cancel password change clears
its fields without losing contact drafts. These edits retain the existing combined
atomic administrator RPC. Own-profile password editing remains a separate route
because it is a self-service task. Creation uses the same sections and controls.

Role, branch, Senior Doctor and payment permission capabilities remain available.
Staged permissions use plain, unboxed checkboxes with explanations. Own-role and
own-account-access restrictions are explained and protected in both UI and
controller. The keep-alive Riverpod mutation controller checks the active
administrator through `currentUserProvider`; state mutations use `copyWith`.
Deactivation requires a named consequence review, including upcoming appointment
counts for doctors. A failed count query stops the save and keeps the draft.

Save/Cancel remain visible. Dirty forms require a discard decision; pending work
blocks duplicate submits and navigation. Localized inline validation and save
errors retain entered values. Corrected fields revalidate on interaction, and
changing a password revalidates a previously edited or invalid confirmation.
No database/schema or deployment change is part of this editor follow-up.

## Validation and limits

November 2, 2026 finish review: **ship**. The first review found stale corrected-field
validation and a faint enabled role hint. Both were fixed and the reviewer verified
the corrections, with no remaining material finding within this scope. The enabled
role hint measured 4.76:1 on the light surface; disabled treatment is separate.

- Final `flutter analyze`: zero issues. Riverpod code was regenerated before the
  final widget-only corrections.
- `flutter test test/features/auth test/previews/staff_editor_render_test.dart`:
  69 passed. The separate `staff create form` selection in
  `test/previews/staff_workspace_render_test.dart` passed 2 tests. These 71 checks
  are disjoint; earlier broad runs and reruns are not added to this total.
- The independent reviewer inspected all 30 production-widget captures using
  fictional data: 24 edit captures include light/dark 390/840/1440 layouts,
  expanded passwords, self/inactive/receptionist variants, deactivation failure
  and review, and 320×740 at 2× text with a simulated 280-pixel keyboard. Six
  additional creation/role/senior captures cover 390/1440×1000 layouts.
- Captures stay outside the repository at
  `C:/Users/Elite-Store/.codex/visualizations/2026/11/02/01a19dcf-b04b-7751-96c4-e888addb8482/staff-editor`.
  No raster assets ship with this change.

These checks use widget fixtures and test doubles. No emulator/device session,
native password-manager check or live account mutation was performed. No HTML/CSS
detector ran for this native Dart surface. The review covers this local editor
extension and does not establish whole-app UI quality.
