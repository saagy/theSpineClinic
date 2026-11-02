# Staff workspace cleanup — November 2, 2026

## Audit before implementation

- Directory cards waste vertical space and scatter comparable role/status data.
- Saturated avatars and stacked badges compete with staff names.
- Contact strings joined with pipes are difficult to scan and wrap poorly.
- Role grouping overrides the requested global name/newest sort.
- Floating Add obscures the final rows; it has no visible action label.
- Pending applications repeat their status and use oversized red/green actions.
- Forms stretch to desktop width, use heavy section cards and scroll Save away.
- Role dropdowns inherit that excessive width; controls lack a bounded measure.
- Staff tabs are stretched across the window and use an alarm-colored count.
- Staff/history filters wrap appointment-specific state; patients duplicate sheet
  header/footer, container and doctor picker code. Shared presentation can drift.
- Analytics has an isolated routed implementation plus separate legacy reports.

## Scope

Inherit Patients/Schedule typography, clinical blue, flat rows and separators.
Preserve permissions, confirmations, filter drafts, validation and refresh.
Use one shared filter frame/body; keep domain-specific result types and state.
Remove the routed Analytics implementation; preserve independent legacy reports
and all database structures. Redirect its old URL to Admin.

## Implemented decisions

- Staff directory and pending applications use flat separated rows, quiet initials,
  readable contact lines and status text. Wide rows align role/status columns;
  narrow or enlarged-text layouts wrap details and place review actions below.
- Global name/newest sorting is no longer overridden by role grouping. A labeled
  Add button sits in the toolbar. Pending counts use the text tabs; compact
  Approve/Reject actions retain their confirmation dialogs and role checks.
- Staff forms use `FormPageBody` and `FormSection`, bounded by the existing
  `AppSizes.formLayoutMaxWidth` (720 logical pixels). Save/Cancel stay visible;
  pending saves disable fields/navigation and guard duplicate submissions.
- `FilterSheetFrame`/`FilterSheetBody`, `FilterSortOption`, and the shared
  `FilterDoctorView`/`FilterDoctorField`/`FilterDoctorOption` provide the applicable
  presentation pieces for Patients, Schedule, appointments, doctor history and
  staff. Feature-specific drafts, state and result types remain separate.
  `UnifiedFilterSheet` remains in older patient-note and appointment components.
- The isolated Analytics UI, providers, repository/query/DTO code and tests were
  removed, along with its navigation item. `/admin/reports` redirects to Admin.
  Independent legacy `ReportsScreen`, admin report queries and database structures
  remain. Super admin defaults to All Appointments with Appts/Patients/Admin tabs.

## Validation and limits

- `flutter analyze`: zero issues. Full `flutter test`: 438 passed. The latest
  staff interaction file separately passed 3 tests, including duplicate-submit
  protection and success navigation; 2 overlap the full run, while the added test
  landed after that run started. These counts are not additive.
- 15 render/interaction tests cover staff and pending views at 390/800/1440 in
  light/dark themes, forms and role menus at 390/1440, shared filters, and a
  320-wide layout at 2× text. An independent reviewer inspected 23 screenshots
  and returned a ship disposition with no material findings within this scope.
- 27 focused preexisting regressions and the actual-router legacy deep-link test
  passed; these are included in the full-suite count.
- Tests use fictional fixtures. No live database or staff mutations and no
  live-browser QA were performed. No HTML/CSS detector ran for this native
  Flutter implementation; this review does not establish whole-app UI quality.

Screenshots stay outside the repository at
`C:/Users/Elite-Store/.codex/visualizations/2026/11/02/01a19c8e-f2e9-74b0-bca1-ebb0982f1ce1/staff`.

## Senior doctor management follow-up

Audit: Add/Edit Staff omitted senior status, profile writes dropped it, and the
directory labeled every doctor identically. The Doctor access section now offers
a Senior Doctor permission checkbox with the existing capability explanation.
Admins can create, promote and demote doctors; changing to a non-doctor role
clears senior status.
Directory rows identify Senior Doctor, and doctor-picker caches refresh on saves.
Creation and profile/password updates use atomic admin-only RPCs added by migration
`20261102010000_staff_seniority_management.sql`; deployed November 2, 2026.

Follow-up verification: 11 targeted Flutter tests passed, including senior payloads,
form controls, existing senior permissions and save recovery. Mobile/desktop form
renders passed. SQL creation, promotion/demotion, role changes, unauthorized calls
and password rollback passed against both the schema snapshot and migration chain
in disposable PostgreSQL. Flutter analysis is clean. The live migration is applied.

Deployment: applied only the senior-management migration to linked project
`ujketpugttdqpcixrnga` using an isolated directory populated from remote history.
Post-deployment dry run reports up to date. Both new RPCs reject anonymous
requests with HTTP 401 / SQLSTATE 42501. No tables, columns or existing account
records were changed. This deployment covered the database functions; Firebase
Hosting was not republished.

## Staff editor follow-up

The [staff editor follow-up](staff-editor-flow.md) replaces staged account switches
and password checkboxes with explicit tasks, aligns fields with the profile editor,
and retains the senior/payment permissions and existing atomic RPCs. Its finish
review, 30 rendered captures and final checks are recorded separately from the
workspace and senior-management validation above. This follow-up has no database
or deployment change.
