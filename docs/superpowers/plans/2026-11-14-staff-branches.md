# Staff branches and appointment branch Implementation Plan

> Executed natively in the session that wrote it (the user asked to write the
> design and implement it). Steps use checkbox syntax for tracking.

**Goal:** Staff belong to several branches with a per-branch weekly schedule;
appointments record their branch; pickers, filters, warnings, a read-only
staff profile and head-receptionist access build on that. Also folds the
patient personal details into the patient record.

**Architecture:** One migration adds `staff_branches`, `staff_shifts`,
`appointments.branch` and `appointment_branch_changes`, rewrites the staff
account and booking functions, and moves the Doctor sessions report to the
appointment branch. Flutter gains `StaffShift`, branch lists on `Staff`, a
staff profile screen, a schedule editor, a branch-aware `DoctorPickerSheet`
and a booking warning.

**Tech Stack:** Flutter 3.44 / Riverpod generator / Supabase PostgreSQL;
SQL tests run in PGlite via `test/review_database.mjs`.

**Specs:** `docs/superpowers/specs/2026-11-14-staff-branches-design.md`,
`docs/superpowers/specs/2026-11-14-patient-record-overview-design.md`

## Global Constraints

- AGENTS.md rules: files ≤ ~200 lines, `Result<T>` repositories, Riverpod
  annotations, `keepAlive` mutation controllers, `copyWith` mutations,
  `AppStrings`/`AppSizes`/theme tokens only, four UI states, shared
  `RecordMenuSelect`/`RecordActionMenu` instead of raw menus, grants on every
  new table, multi-table writes in one RPC, `flutter analyze` clean.
- Clinic week starts on Saturday; ISO weekdays 1 = Monday … 7 = Sunday.
- Branches never block patient/appointment access; schedules never block
  bookings.

## Review Focus

- Receptionist whose active branch is removed from their assignments: active
  branch moves to the first remaining one (SQL test).
- Overlapping shifts on one weekday are rejected; back-to-back shifts
  (14:00 end, 14:00 start) are allowed (SQL test).
- Old clients booking without `p_branch` still get the patient's branch
  (SQL test).
- Changing a checked-in appointment's branch is denied for receptionists and
  allowed and logged for super admins (SQL test).
- Doctors with no assignments or no shifts never disappear from pickers and
  never warn (Dart test).

---

### Task 1: Database migration and SQL tests

**Files:** create `supabase/migrations/20261114150000_staff_branches.sql`,
`test/staff_branches.sql`; modify `test/review_database.mjs`,
`supabase/full_schema.sql`, `docs/database-schema.md`.

**Produces:** tables above; `update_staff_account(profile)` accepts
`branches` (text[] of branch values) and `shifts`
(`[{branch, weekday, starts_at, ends_at}]`); `create_staff_account(...,
new_details)` reads `branches`/`shifts` from `new_details`;
`book_recurring_appointments(..., p_branch clinic_location DEFAULT NULL)`;
`update_appointment_details(..., p_branch clinic_location DEFAULT NULL)`;
`staff_upcoming_at_branch(p_staff uuid, p_branch clinic_location) → integer`.

- [ ] Write `test/staff_branches.sql` covering: assignment backfill, admin
  save of branches and shifts, overlap rejection, shift outside assignment
  rejected, active branch moved on removal, receptionist self branch guard,
  head-receptionist detail read (shared branch yes, other branch no),
  booking with and without `p_branch`, branch change rules and log, Doctor
  sessions report by appointment branch.
- [ ] Run it against `--migrations`; expect failure before the migration.
- [ ] Write the migration; run the full SQL suite on both setup paths.

### Task 2: Staff domain and repository

**Files:** create `lib/features/staff/domain/staff_shift.dart`; modify
`staff.dart` (add `branches`), staff queries, `staff_details.dart` (drop
schedule fields), write queries, providers.

**Produces:** `StaffShift({branch, weekday, startMinutes, endMinutes})`,
`Staff.branches: List<ClinicLocation>`, `staffShiftsProvider →
Map<String, List<StaffShift>>`, `StaffDetails.updatedAt/updatedByName`.

### Task 3: Staff editor, profile and access

**Files:** create `staff_profile_screen.dart` + widgets,
`staff_schedule_field.dart`, `staff_branches_field.dart`; modify router,
directory tile, receptionist navigation, `staff_details_providers.dart`.

### Task 4: Appointment branch, pickers, filters, warnings

**Files:** modify `Appointment` model, booking repository/mutations,
today/all queries, `DoctorPickerSheet`, `DoctorSelectField`, booking
workboard, edit appointment form, appointment detail header, receptionist
branch switcher, billing branch choices, patient list branch default.

**Produces:** `bookingScheduleWarning(doctor, shifts, branch, slot) →
String?` (pure, unit-tested).

### Task 5: Patient record cleanup

**Files:** `workspace_header.dart`, `patient_summary_sidebar.dart`,
`workspace_info.dart`, `workspace_overview.dart`, `workspace_follow_up.dart`,
`patient_detail_screen.dart`.

### Task 6: Verify

`flutter analyze`, `flutter test`, SQL suites, rendered desktop and phone
review in the browser preview, docs updated (AGENTS.md debt items,
`docs/database-schema.md`, `docs/testing.md`).
