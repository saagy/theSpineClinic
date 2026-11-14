# Staff branches, per-branch schedules and appointment branches

Date: 2026-11-14. Status: approved in conversation (the user asked to write it
and implement it).

## Why

Doctors and other staff often split their week between branches (for example
Sat/Mon/Wed at Tagamoa, Sun/Tue/Thu at Madinaty). The app models one branch
per receptionist, none for doctors, and one weekly schedule per person with no
branch. Appointments have no branch of their own: they borrow the patient's
branch, so transferring a patient silently moves their past sessions to
another branch in the Doctor sessions report. Staff employment details are
editable only by the super admin and are never shown read-only anywhere; the
head receptionist acts as a branch manager and needs to see them.

## Goals

- One account per person. A person is **assigned** to one or more branches
  and has a **weekly schedule per branch** (one or more shifts per day, each
  at one branch).
- Every appointment records the branch where it happens.
- Booking pickers list the active branch's doctors first; booking a doctor
  outside their schedule at that branch shows a warning that never blocks.
- Filters over past data can still reach anyone (transferred and former
  staff stay selectable).
- A read-only staff profile. The super admin edits; the head receptionist
  (receptionist with "Can manage payments") reads profiles, including
  employment details, of staff who share a branch with them.
- Branches are a default view, never a wall, for patients and appointments.

## Non-goals and anti-goals

- No time off, swaps or one-off schedule exceptions (warnings may be wrong on
  those days; that is acceptable because they never block).
- No hard branch restriction on patient or appointment access.
- Never two accounts for one person.
- Never block a booking because of a schedule.
- No pay rates (separate technical-debt item).

## Approaches considered

1. **Two accounts per doctor.** Rejected: splits pay reports, patient
   assignments and notes across two identities; the unique national ID and
   email make it unworkable.
2. **Branch list only, keep one schedule.** Cheap but cannot say where a
   doctor is on a given day, so warnings would be wrong for split weeks.
3. **Assignments plus per-branch shifts (chosen).** The industry pattern
   (Cliniko, Jane, Deputy): membership and schedule are separate, history is
   read from the data itself.

## Data model

- `staff_branches(staff_id, branch, created_at, created_by)`, primary key
  `(staff_id, branch)`. Readable by every active staff member (pickers need
  it). Written only by the staff account functions.
- `staff_shifts(id, staff_id, branch, weekday 1–7, starts_at, ends_at)`;
  `ends_at > starts_at`; `(staff_id, branch)` must be an assignment (removing
  an assignment removes its shifts). Shifts of one person on one weekday may
  not overlap (checked in the save function). Readable by every active staff
  member: hours are needed for booking warnings and are not sensitive.
- `staff_details` loses `working_days`, `work_starts_at`, `work_ends_at`.
  Live data on 2026-11-14 has one doctor with days and hours and no branch,
  so there is nowhere to attach them; they are dropped (the doctor's days must
  be re-entered with a branch). No other schedules exist.
- `staff.branch` keeps its meaning for receptionists: the branch they are
  working at right now (the "active branch"). It must be one of their
  assignments when they have any. Saving assignments that exclude it moves it
  to the first remaining assignment. It is cleared for other roles.
- Initial assignments: every staff member with a non-null `staff.branch`
  (receptionists and a few doctors on live data) is assigned to that branch.
- `appointments.branch clinic_location NOT NULL`, backfilled from the
  patient's branch. A `BEFORE INSERT` trigger fills it from the patient when a
  caller sends none, so cached older clients keep working during rollout.
- `appointment_branch_changes(id, appointment_id, from_branch, to_branch,
  changed_by, changed_at)`: written by a trigger whenever an appointment's
  branch changes.

## Rules

- **Booking** sends the active branch (`p_branch`) through
  `execute_clinic_mutation` → `book_recurring_appointments`. (Bundled
  companion assessments were removed from the app on 2026-11-14; the database
  still gives an unused companion the same branch.)
- **Changing an appointment's branch** goes through
  `update_appointment_details(..., p_branch)`. Allowed while the appointment
  is `scheduled`; afterwards only super admins. A trigger enforces this on any
  update path and logs the change.
- **Doctor sessions report** filters by the appointment's branch.
- **Schedule, booking and appointment filter queries** filter by
  `appointments.branch` instead of the patient's branch.
- **Due-patients queue** stays on the patient's registered branch.
- **Head receptionist read access**: a new `staff_details` policy lets an
  active receptionist with `can_manage_payments` read rows of staff who share
  at least one assigned branch with them. Writes stay super-admin only.
- **Receptionist branch switcher** offers only their assignments (all
  branches if they have none). A receptionist cannot set their own active
  branch outside their assignments (database guard).

## Screens

- **Staff profile** (new, `/staff/:id`): header (name, role, consultant /
  payments badges, inactive state), contact, branches and weekly schedule
  (grouped by day in clinic-week order, Saturday first), employment details
  (national ID masked to its last four digits with a Show control, date of
  birth with age, hire date with tenure), and "Updated by … on …". Super
  admins get Edit. Desktop: two columns; phone: one column. Loading, error,
  empty and data states.
- **Staff directory** opens the profile instead of the editor. Head
  receptionists reach the directory from their navigation (read-only: no Add,
  no Applications tab).
- **Staff editor**: the receptionist-only Branch dropdown and the Working days
  / hours fields are replaced by a **Branches** multi-select (all roles except
  super admin) and a **Weekly schedule** editor: one row per weekday, each
  with zero or more shifts (branch + start + end), add/remove controls.
  Removing a doctor's branch that has upcoming scheduled appointments there
  asks for confirmation and names how many.
- **Doctor pickers** (`DoctorPickerSheet`) take an optional branch: doctors
  assigned there first under the branch name; the rest under "Other doctors".
  For booking, the other group is collapsed behind "Show doctors from other
  branches". Doctors with no assignments appear in the first group until
  assigned, so nobody disappears during rollout.
- **Booking warning**: when a picked doctor has shifts but none covering the
  chosen day and time at the booking branch, show an inline warning naming
  where they are that day (or "not scheduled on Monday"). Doctors with no
  shifts never warn.
- **Booking a patient registered at another branch** shows "Registered at
  Madinaty" next to the patient.
- **Appointment detail** shows the branch; **edit appointment** has a branch
  field (scheduled appointments; any status for super admins).
- **Doctor schedule/history** shows the branch on each appointment.
- **Patient lists for consultants** default to "My branches" (their
  assigned branches) with "All branches" and each branch one tap away.
  Ordinary doctors already see only their assigned patients, so their
  filters are unchanged.
- **Billing**: receptionists keep billing and reporting for their working
  branch; they switch it from their profile among their own branches.
  Invoices are issued at the working branch.

## Status

Implemented on 2026-11-14 with migration `20261114150000_staff_branches.sql`.
The migration passes both SQL setup paths locally. It was **applied to the
linked project by hand** (SQL editor, in one transaction) on 2026-11-14 with
its version recorded in the migration history, then verified: 8 staff
assigned to their former branch, all 1,118 appointments given their
patient's branch, no non-receptionist keeping a branch, the old schedule
columns gone, the new booking and edit signatures in place, appointment
triggers enabled, the four new policies present, the branch writer not
callable by clients. The updated app needs this migration (appointment
queries filter on `appointments.branch`).

## Left to the builder

Token names, exact copy (in `AppStrings`), widget decomposition under the
200-line rule, and test layout. Follow AGENTS.md (Result<T>, Riverpod
annotations, keepAlive mutation controllers, copyWith, RPCs for multi-table
writes, grants on new tables, docs in sync).
