# Program editing access

## Audit

The November 3 workflow review identified these problems before implementation:

- Edit program details scrolled away while the app bar remained available.
- The fixed program overflow contained only Delete, despite users expecting
  record actions there.
- Conditions and clinical findings had no editing action beside their content.
- Documents were nested inside findings and vanished when there were no files.
- Every edit opened at the start of the form, making users search a second time.
- Nested clinical finding boxes added visual weight without supporting a task.

## Adopted behavior

- The fixed app bar exposes a labeled Edit action for active senior doctors and
  super admins. Wider windows label it Edit Program; compact actions use Edit.
  The smallest windows shorten the title to Program. The tooltip names Edit
  program details.
- The program menu also offers Edit program details, followed by Export PDF and
  a separated Delete Program action. Read-only users retain Export PDF access.
  The treatment plan keeps its separate, explicitly scoped menu.
- Conditions and findings have a quiet Edit action in their section headings.
  Documents is a separate section with Add Document when empty and Manage when
  populated. All three sections share one surface with flat heading rules.
- Section shortcuts use the existing full editor with a URL section parameter:
  conditions, findings or documents. Reloading the URL preserves the destination;
  missing or unknown values open the normal conditions-first editor.
- The editor reveals the selected section without opening the keyboard. Its
  Documents section is separate from clinical text and explicitly handles
  loading, retryable failure, empty and populated results.
- Save and Cancel remain persistent. Returning to the program retains its list
  position. Failed saves keep the draft and show an inline error beside Retry
  save, without an overlapping error toast. Permission/preflight failures still
  receive explicit feedback.
- Existing role checks, atomic program saves, staged document removals,
  compensating upload cleanup and cache invalidations remain in use.

The implementation uses shared RecordSection, RecordSurface, RecordAsync and
FormSection components, existing theme colors, AppSizes and AppTextStyles.
Record menus opt into a divider before destructive actions; other menus retain
their existing grouping.

## Validation

`flutter analyze` reports no issues. 64 targeted checks passed across program actions, section navigation, edit URL
restoration, document states and removal drafts, media viewing, treatment-plan
details/building, and the rendered editing flow. They include keyboard activation
of the fixed Edit action from a scrolled record on phone and desktop, preserving
scroll position on Cancel and Save, failed-save retry, and rejected read-only
submissions.

Rendered review used real Flutter widgets and the bundled fonts with fictional
records at 320, 390, 768 and 1280 logical pixels in light and dark themes, plus
360 pixels with 1.5x text. The four captured stages are the initial program,
scrolled documents, document editor, and program menu. Captures remain outside
the repository; `test/previews/program_edit_access_render_test.dart` supports the
existing `UI_POLISH_CAPTURE` define.

No production Supabase mutations or physical-device interactions were exercised.
