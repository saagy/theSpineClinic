# Profile editing

## Scope and audit

Staff edit their own name, email and optional phone, and may change their own
password. All active roles have the same self-service permissions. The user
selected a dedicated page with a separate password step on November 2, 2026.

The previous sheet was rendered at 390 and 1440 logical pixels before replacement.
The audit found:

- A desktop editor remained anchored to the bottom of a dimmed screen.
- Contact and password fields competed in one undifferentiated form.
- Password fields appeared even when the user only needed to update their name.
- A non-scrolling column could run out of space above the keyboard.
- Save followed every field; there was no explicit Cancel action.
- Dismissal could discard edits, including during an in-flight save.
- Errors appeared only in a transient snackbar.
- Inputs lacked autofill and next/done keyboard actions.
- Widgets called the repository directly instead of using a mutation controller.

## Direction contract

THESIS: Profile editing is a focused account task with separate password editing.

OWN-WORLD: Inherit clinical blue, Plus Jakarta Sans, quiet bordered form sections,
theme surfaces, and shared form controls with compact corners.

STORY: Review personal details, change the relevant fields, and save or cancel.
Security opens a separate step without discarding the contact draft.

FIRST VIEWPORT: A back/title bar, bounded personal-details form, separate security
row, and persistent Save/Cancel footer. Phones stack fields; wider forms pair
email and phone. Errors remain with the draft.

FORM: Local extension of the established form system; no concept seed required.
Native route transitions carry navigation; no decorative motion.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance

## Adopted implementation

Receptionist, doctor and administrator actions open the same `/profile/edit`
route. Personal details contains name, email and optional phone; the Security row
opens `/profile/edit/password` while preserving the contact draft.

`FormPageBody` bounds content at 720 logical pixels. Email and phone pair at
480 pixels of available field-group width when text scale is at most 1.3; they
stack otherwise. The persistent Save/Cancel footer uses compact aligned actions
from 600 pixels of content width. `AppTextField` supplies labeled, theme-aware
inputs, autofill hints and next/done keyboard actions.

The existing database trigger keeps staff email and sign-in email in sync.
Password editing uses its own authenticated repository `Result<void>` operation;
the combined optional-password profile save has been retired. Contact saves use
the current user's freshest branch and permission fields. The keep-alive Riverpod
mutation controller verifies active self-service permission before either write.
Unsaved edits require a discard decision; pending saves block duplicate actions
and back navigation. Initial load, retryable error, missing-session and populated
states are explicit. Validation and save failures keep entered values; background
session refresh preserves the editor route.

Successful contact saves explicitly navigate to the role's profile destination
(`/doctor/profile`, `/receptionist/profile`, or the administrator hub), where
`currentUserProvider` reloads the saved details. They must not just pop the editor:
the router's session-refresh listener can restore that popped route and recreate
its form with cached, unedited values even though the database write succeeded.
Password saves still pop back to the preserved contact draft. Regression tests
exercise the real app router for every role with immediate and delayed reloads,
check the updated profile details, and reopen the editor to verify saved values.

## Validation and limits

Save-navigation regression: the real-router test reproduced the reopened editor
before the fix. All 31 targeted profile, password, controller, repository and
auth-redirect tests pass with the explicit profile destination.

November 2, 2026 finish review: **ship**. The independent reviewer opened all
16 production-widget captures and found no material fixes.

- `flutter analyze` completed with zero issues after the final logic changes.
- Riverpod code was regenerated. The targeted suites passed all 62 tests:
  `flutter test test/features/auth test/widgets/operation_feedback_test.dart test/previews/ui_polish_forms_test.dart test/previews/profile_editor_render_test.dart`.
- Fictional-data captures cover profile and password forms at 390, 840 and
  1440 by 900 logical pixels in light and dark themes. Additional captures cover
  320 by 740 at 2x text scale, including a simulated 280-pixel keyboard, save
  failure and discard confirmation.
- Captures remain outside the repository in the session visualization directory
  `C:/Users/Elite-Store/.codex/visualizations/2026/11/02/01a19dcf-b04b-7751-96c4-e888addb8482/profile-editor`.
  No raster assets ship with this change.

These are widget/test-double checks, not a device or emulator session. Live
account writes and native password-manager behavior were not tested. An HTML/CSS
detector does not apply to this native Dart surface and was not run.
