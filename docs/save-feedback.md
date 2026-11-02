# Save and upload feedback

## Scope and audit

The October 31 pass improves submission feedback while preserving database RPCs,
request receipts, storage finalization, and existing permission boundaries.
The user requested restrained indicators suitable for Flutter web.

The source audit found:

- Shared form footers displayed static Saving text throughout long operations.
- Form-level pointer blocking also prevented scrolling to review information.
- Patient creation and booking layered a blocking overlay over their save footer.
- Document entry points used unrelated local busy flags and spinner treatments.
- Upload failures disappeared into snackbars; picked bytes were lost on navigation.
- New-patient attachment counts counted active uploads rather than completed files.
- The overlay's Cancel & Go Back action only navigated; it never cancelled work.
- The first reduced-motion fallback showed only an empty pale track, making a
  working request look stalled. The user approved estimated visual progress.
- Saved program attachments waited for database deletion and storage cleanup
  before disappearing; failures on that form were not surfaced.
- Picker previews used positional identities and a very small remove target.
- The November 1 correction separates preview removal from persisted deletion:
  closing a program attachment must be an unsaved form edit until Save changes.
- A shared default unintentionally spread upload-style bars into authentication,
  staff forms, payment actions, patient deletion, appointment actions, ordinary
  form saves and the global loading wrapper. Login also displayed a second spinner.

## Adopted interaction

- Only queued document uploads opt into a native three-pixel linear indicator.
  It starts visibly filled and advances on a
  lightweight one-second timer, with a short smoothing animation confined to the
  bar. This is estimated activity: it approaches 94% and never declares success.
  There is no numeric percentage or invented SQL stage. Actual results govern
  completion, errors and upload counts; screen readers receive status text only.
- The form scrolls during submission while its inputs, focus, Save, Cancel and
  route popping are protected. Patient and booking forms use this footer without
  a second blocking overlay.
- Program failures remain in the footer with a retry label. Definitively rejected
  attachments direct staff to the saved patient record instead of repeating a
  permanently rejected request. Existing same-payload receipt reconciliation stays.
- Standalone document uploads use a patient-scoped keep-alive Riverpod controller.
  Documents displays the active filename and unfinished files with retry actions.
  Retry skips successful files. Unknown outcomes cannot be dismissed as rejected.
- Unfinished files from new-patient registration transfer to that patient's upload
  controller; registering the patient again is unnecessary. The form retains its
  per-file statuses and displays the actual number attached in the save footer.
- Successful uploads release retained bytes. Staff-session changes clear the
  in-memory queue and obsolete completions cannot repopulate it.
- Authentication uses a labeled pending submit button without a blocking overlay.
  Staff and payment forms also use their existing save button. Ordinary form
  footers display a spinner and Saving label in the button; no status panel or bar
  appears. Program/new-patient forms opt into a bar only with queued files;
  staged document removals alone use ordinary save feedback.
- Remaining blocking overlays (appointment updates, payment mutations, patient
  deletion and the optional global wrapper) use a compact spinner with contextual
  copy. Their delayed Go back action explicitly explains that navigation does not
  cancel a pending request. It is hidden when the route prohibits popping.
- Reduced-motion preferences use discrete fill updates without interpolation.
  Colors, type, spacing and dimensions use app tokens. Timers stop when busy
  feedback is removed; no polling or extra network requests are introduced.
- Program editors hide removed previews immediately through a form-scoped
  Riverpod draft. Shared document providers and storage remain untouched until
  Save changes. Cancel/back discard that draft; reopening shows the saved files.
  Failed saves retain the removal selection for retry, including across document
  refreshes. Staff identity/permission changes reset the draft.
- Explicit deletion from document lists remains an immediate confirmed action,
  with optimistic feedback and rollback on failure. It is separate from editing
  a program and does not require a later form save.
- Saved and pending picker previews retain stable identities on removal. Local
  image decoding is bounded to thumbnail width; remove buttons have native focus,
  pointer and keyboard behavior with a minimum 44-pixel touch target.

## Atomicity and recovery boundary

The program RPC commits program, conditions, treatment-plan edits and selected
document-row removals atomically before tracked R2 uploads. Removed document IDs
are included in the durable request fingerprint. The RPC checks patient/program
ownership, rejects removals during creation, and returns original/thumbnail paths
in its receipt so lost-response retries can repeat cleanup safely. Storage deletion
is best effort after confirmed database success. New uploads remain independently
recoverable through their existing protocol.

Apply `20261101010000_staged_program_document_removal.sql` before releasing the
updated client. The client requires explicit removal acknowledgement; an older
backend cannot silently report success for ignored removals. This task prepares
the migration and canonical schema; it does not apply them to the linked project.

Retained bytes survive navigation within the current application session. This
does not create durable background uploads: closing/reloading the browser still
requires selecting the original files again. Uploads continue to use existing
timeouts and permission checks; recovery reuses their existing receipt protocol.

## Validation

Focused controller, repository recovery and widget tests cover retry selection,
duplicate starts, session changes, scrolling, reduced motion and pending copy.
Deletion tests hold requests open to verify immediate removal, rollback,
concurrent rename/delete preservation, duplicate coalescing and stale refreshes.
Program editor interaction tests verify immediate preview hiding without writes,
Cancel/reopen, failed-save retention and successful retry at both widths.
`test/program_document_removal.sql` checks transaction rollback, permissions,
patient/program scope, receipt replay and cleanup paths against PostgreSQL.
Production feedback components are rendered at 360 and 1280 logical pixels in
light/dark themes, plus enlarged-text document recovery. Final command results
on October 31:

- `flutter analyze`: no issues.
- `flutter test`: all 392 tests passed.
- `flutter build web --release --no-wasm-dry-run`: succeeded.
- Rendered mobile/desktop feedback at initial and advancing fill, light/dark
  themes, enlarged-text recovery and program attachments were inspected.
  No production patient data or live backend writes were used.
- No deployment was performed.

November 1 correction validation:

- `flutter analyze`: no issues; `flutter test`: all 400 tests passed.
- `flutter build web --release --no-wasm-dry-run`: succeeded.
- Program edit tests at 360/1280 pixels cover staging without writes, refresh,
  Cancel/reopen, failed-save retention and successful retry. Draft tests cover
  isolated forms, profile refresh and permission/session changes.
- Intercepted HTTP tests verify a single save RPC, post-commit cleanup, suppressed
  cleanup failures, acknowledgement and lost-response recovery.
- The SQL regression script passed in isolated PostgreSQL (PGlite), using the
  actual relevant table/function definitions and the new migration. No linked
  database calls or production writes were made.

November 1 context-specific feedback correction:

- `flutter analyze`: no issues; `flutter test`: all 405 tests passed.
- `flutter build web --release --no-wasm-dry-run`: succeeded.
- Delayed-login tests at 360/1280 pixels in light/dark themes verify one labeled
  button indicator, disabled duplicate submission/tab switching, and preserved
  credentials with the button re-enabled after failure. Rendered layouts inspected.
- Shared feedback tests verify ordinary saves have no bar, uploads explicitly opt
  in, and slow blocking requests retain their navigation explanation.
- No deployment or live authentication/backend calls were performed.
