# Shipping UI polish — September 13

Scope: appointment rows, patient workspace surfaces, patient/appointment/program
create and edit, treatment target controls, doctor history and patient tab filters.
The user explicitly included staff-directory filters; other admin screens remain excluded.

## Audit before implementation

- Agenda: checked-in status is passive inside a tappable row, so taps navigate
  unexpectedly. Scheduled/checked-in icons look almost identical. Check-in is
  missing from the menu; patient navigation is missing. Several controls are
  below the 44px target. Row and menu duplicate repository mutation code and
  rollback is inconsistent. Preserve row navigation and status refresh callbacks.
- Patient details: its white scaffold conflicts with the surrounding app.
  Changing only the scaffold would strand white section bodies on gray. The user
  selected independent overview cards and unboxed tab lists.
- Patient forms: unrelated sections use identical heavy cards; labels float in
  outlines; save disappears below attachments; edit stretches on desktop.
  Creation and editing use different field styling and inconsistent copy.
- Appointment forms: patient identity is boxed twice and shows a truncated UUID;
  service choices have nested borders; date/time and repeated provider containers
  lack a clear section hierarchy. Preserve recurring, bundled, billing and doctor
  choices, and restrictions for checked-in appointments.
- Program form: oversized condition heading competes with the Add action;
  selected conditions become oversized chips. Repeated card shells add weight.
  Condition picker uses a card per checkbox and a large tinted filter.
- Treatment targets: nested rounded panel, floating label, unlabeled side/type
  segments, and tiny duration hit targets. Side and duration compete for narrow
  space. Preserve modality collapse/removal and existing region semantics.
- Doctor history: search, sort, and filter occupy separate bands; filter badge
  reports one regardless of count. Old sheet duplicates current components.
  Preserve four sort choices and date/type/branch filters. The old sheet treats
  dateTo as exclusive while the provider treats it as inclusive (extra day).
- Residual search: old patient tab wrappers and staff directory retained separate sort/filter bars.
  The user explicitly requested their replacement.

## References and direction

- [NN/G: user control and freedom](https://www.nngroup.com/articles/user-control-and-freedom/):
  predictable undo and action labels.
- [Carbon: filtering](https://carbondesignsystem.com/patterns/filtering/): grouped
  controls, applied-filter visibility and deliberate apply/reset.
- Existing Schedule/All filters and treatment-plan footer are the visual baseline.
  Retain clinical blue, Plus Jakarta Sans, flat rows and 8px control corners.

## Implemented decisions

- All appointment actions live in the three-dot menu, led by the relevant status
  action. Outside indicators are passive, with distinct clock / green check /
  cancelled symbols; their taps never navigate. A keep-alive Riverpod controller
  continues to check access, prevent duplicate requests and refresh affected caches.
  Compact rows use one row with stacked identity/type, allowing text to wrap.
  Wide rows retain aligned columns and passive status labels. The earlier outside
  Check in / Undo controls and separate mobile action line were superseded.
- Patient tabs use the standard scaffold. Overview groups have bordered surfaces;
  appointments, notes and documents have no giant white wrapper. Mobile pinned tabs
  absorb their scroll overlap so section headings and actions remain accessible.
- Patient, appointment and program create/edit forms share section cards,
  responsive columns and persistent Cancel/Save footers. Desktop actions have a
  bounded width. Existing validation, attachments, recurring/bundled booking and
  billing permissions remain wired. Bundled sessions default to Assessment.
- Treatment target rows use labels above fields, Left/Right/Bilateral segments,
  accessible duration steppers and 10/15/20/30-minute presets. Region changes clear
  inapplicable laterality. Modality selection/collapse/removal is preserved.
- Doctor history and staff filters use the existing appointment sheet's chrome
  with their own sort choices. History converts its inclusive end date to/from the
  sheet's exclusive boundary. Patient legacy tabs delegate to current workspace
  components. Appointment search matches type before pagination; note text search
  executes in the repository. Searches remain debounced.

## Validation

Production-widget captures cover 360px and 1280px workspace, patient create/edit,
appointment create and program create layouts. Images stay outside the repository.
Widget checks cover role visibility, long names/enlarged text, persistent actions,
status hit isolation, target duration interaction, filter apply/reset/dismiss,
recurring balance guards and bundled assessment controls. The earlier broad shipping pass completed 259 tests. The subsequent density
correction passed 57 targeted widget/regression checks; `flutter analyze --no-pub`
reports no issues. Riverpod/Freezed generation completed successfully. No live clinical data was changed
for visual testing; backend mutation testing is outside these isolated previews.

## Density correction audit (user-approved option 1)

The outside action consumes identity width, the separate action line lowers agenda
density, and green Undo communicates recovery instead of checked-in state. Replace
outside actions with passive status indicators and put the contextual status action
first in the menu on all widths. Restore one compact row with identity/type stacked;
allow long text to wrap without ellipses. Wide rows retain aligned columns. Status
and disabled-menu taps must not fall through to appointment navigation.
The recurrence picker forces seven fixed-width days into columns narrower than
308px. Use seven columns only when all touch targets fit, otherwise up to four
columns with wrapping; enlarge targets as text scales instead of clipping labels.

Density correction validation covers 320/360/430/650/1280px layouts at standard
and 1.8x text scale, all weekday touch targets and Friday toggling, passive-status
hit isolation, contextual menu ordering and refresh callbacks, booking guards and
patient workspace regressions. Standard compact rows are 60px high for ordinary
names; longer names grow naturally. Rendered phone/desktop pilots were inspected.


## In-place status follow-up

Audit: agenda mutations patched list state and then invoked redundant refresh
callbacks. Patient appointments invalidated the entire list provider, resetting
filters/pagination; All refreshed back to page one; booking replaced both panes
with loading states. All's patch also discarded doctor metadata. The status icon
swapped abruptly with a narrower spinner.

AgendaStatusController now owns agenda-row status synchronization. Agenda rows
have no page-refresh callback; legacy card callbacks remain unchanged. Booking
patches the selected row and quietly rechecks its due queue. All and patient
lists retain loaded records and filters, removing a changed record when it no
longer matches the selected status. Patient balance caches still revalidate.
The fixed-size passive indicator uses a 180ms fade/scale transition and disables
motion when requested by the system. No extra button or row height is added.


### Bounded name fitting

User follow-up: names that narrowly exceed the available width wrap unnecessarily.
Shared appointment rows now try 14, 13.5, then 13 logical pixels before wrapping
at the floor. Enlarged accessibility text keeps the normal style and wraps.
The implementation reuses the existing auto_size_text dependency; status/menu
hit targets and row columns remain fixed.


## Check-in and appointment-form follow-up (September 22)

Audit before editing:

- The appointment detail action replaced every failed status mutation with a
  generic snackbar. The active agenda menu already mapped repository errors to
  AppStrings, so the same insufficient-balance rejection appeared differently.
- The shared insufficient-balance message described the booking form's toggle,
  which is unavailable during check-in.
- New appointment type and bundle changes reapplied doctor defaults, clearing
  manually selected doctors. Returning from an assessment also left package
  billing off. An older assigned-doctor fetch could populate a newly selected
  patient's form.
- Doctor selection did not identify senior doctors, even though assessments
  commonly use them. The form needed a reminder to review this choice.

Decision and implementation: keep the database's atomic nonnegative check-in
guard. Package check-in consumes one PT or traction credit. If no credit remains,
staff can add sessions or edit a scheduled appointment to use a paid session.
The detail screen now uses the same `AgendaStatusController` as the active agenda
menu for role checks, status writes, cache synchronization, and mapped errors.
The detail controller only loads the record. The shared message is usable during
booking, editing, and check-in.
Assigned doctors are preselected when a patient is chosen and stay selected
through type and bundle changes; secondary assessment doctors remain an explicit
choice. The form retains the prior session billing choice when switching away
and back, rejects stale doctor fetches, and reminds staff to review assessment
doctors. Senior doctors are identified in the shared picker.

Adjacent audit: the older appointment actions sheet and receptionist cards have
no current call sites. The dormant grouped-card bulk mutation updates appointments
one by one and reports a generic failure; it needs an atomic RPC before reuse.
Active bundled booking also submits primary and secondary bookings separately,
with a possible partial outcome. Treat that as a separate transaction fix before
relying on bundled booking for routine production use.

Validation: `flutter analyze` reported no issues. The focused check-in, agenda
menu, and booking-form tests passed. Existing mobile and desktop form preview
tests passed; the 360px and 1280px captures were inspected. The fixture previews
do not include a selected patient, so doctor retention is covered by the widget
regression test rather than those screenshots.


Validation: Flutter analysis reports no issues. The full suite passed 281 tests;
the remaining name-fit assertion was corrected to accept either permitted
reduced size under inherited font metrics, and both focused name tests passed.
Mobile and desktop production-row captures were inspected. Status tests cover
loaded-page retention, doctor metadata, patient status filters, booking pane
retention, passive hit targets and reduced-motion transitions.

## Patient detail and booking polish (September 22)

Audit: the Documents folder had a white surface and a bottom gap unlike the
document rows, leaving no shared hairline separator. Its group provider rendered
with documents before program metadata resolved, briefly showing “Program”. The
note author header animated between differently sized loading and loaded children.
Booking mixed card-like due rows with flat schedule rows, compressed names and due
dates into very small single-line text, used 30px quick actions, and replaced its
mobile tabs with a skeleton during refresh. Full-page form and result-list spinners
also felt disconnected from the content they preceded.

Implementation: document folders now use the row surface and separator rhythm.
The group provider waits for both source providers; retry refreshes documents and
programs. Notes keep the badge width fixed and swap the author placeholder in
place. Booking's due queue uses flat separated rows, readable metadata, 44px
actions, responsive action placement, and stable underlined count tabs. Initial
form, visit-detail, and patient-search loading uses shaped placeholders. Small
progress indicators remain for local mutations, pagination, and file operations.

Validation: `flutter analyze --no-pub` reported no issues. The document-group
timing and note-position tests passed. Booking widget tests and rendered previews
passed at 320, 360, and 1280px with normal and 1.6x text. Patient Documents and
Notes were rendered at 360 and 1280px; Booking was also reviewed in light and
dark themes. Fixture previews use fictional data and
do not verify a live backend mutation. The full Flutter suite passed 298 tests;
the legacy document-grid fixtures now provide the program lookup required by
the grouped loading state.
