# Spine Clinic App — Screen Inventory

> **How to use this file:**
> - Check off screens as they are built `[x]`
> - Each screen entry is the contract given to the agent — copy the block directly into your prompt
> - Never ask the agent to build two screens in one prompt
> - All screens use shared widgets from `lib/shared/widgets/`
> - All screens handle three states unless marked otherwise: loading, error, empty

---

## Access Legend

| Symbol | Meaning |
|--------|---------|
| 👑 | Super Admin only |
| 🧑‍💼 | Receptionist + Super Admin |
| 🩺 | Doctor only |
| 🌐 | Public (no login required) |

---

## Table of Contents

1. [Public / Auth](#1-public--auth)
2. [Shared — All Authenticated Roles](#2-shared--all-authenticated-roles)
3. [Receptionist + Admin](#3-receptionist--admin)
4. [Doctor](#4-doctor)
5. [Admin Only](#5-admin-only)

---

## 1. Public / Auth

---

### 🌐 [x] DoctorRegisterScreen
**Location:** `lib/features/auth/presentation/doctor_register_screen.dart`

**Purpose:**
A public-facing screen where a new doctor submits a registration application.
No login required. On submit, creates a Supabase Auth user AND a Staff row
with `role = 'doctor'` and `is_active = false`. The account is inactive until
an admin approves it.

**UI Elements:**
- App logo / clinic name header
- Full name field
- Email field
- Phone number field
- Password field
- Confirm password field
- Submit button (with loading state)
- "Already have an account? Log in" link → LoginScreen

**Actions:**
- Submit → validate all fields → create Supabase Auth user →
  insert Staff row (is_active: false, role: 'doctor') →
  show success message: "Your application has been submitted.
  You will be notified once it is reviewed." →
  navigate back to LoginScreen
- Log in link → LoginScreen

**States:**
- Default: empty form
- Loading: submit button shows spinner, all fields disabled
- Error: inline field validation errors + server error banner
- Success: full-screen confirmation message, no form

**Validation Rules:**
- Full name: required, min 3 characters
- Email: required, valid email format, must be unique
- Phone: required, numeric
- Password: required, min 8 characters
- Confirm password: must match password

**Notes:**
- Password is set here and used later when admin activates the account
- Do NOT log the user in after registration — account is pending
- Do NOT send any email or notification (no email service configured yet)

---

### 🌐 [x] LoginScreen
**Location:** `lib/features/auth/presentation/login_screen.dart`

**Purpose:**
Single login screen for all roles. After successful login, fetches the
Staff row for the authenticated user and routes based on role.
If `is_active = false`, sign out immediately and show rejection message.

**UI Elements:**
- App logo / clinic name header
- Email field
- Password field
- Login button (with loading state)
- "Register as a doctor" link → DoctorRegisterScreen

**Actions:**
- Login → Supabase Auth signIn → fetch Staff row by user_id →
  check is_active → if false: sign out + show "Your account is not
  yet active. Please wait for admin approval." →
  if true: store in currentUserProvider → route by role:
    super_admin   → HomeScreen (admin shell)
    receptionist  → HomeScreen (receptionist shell)
    doctor        → MyScheduleScreen

**States:**
- Default: empty form
- Loading: button spinner, fields disabled
- Error: error banner below form (wrong credentials, account inactive, etc.)

---

## 2. Shared — All Authenticated Roles

---

### [x] PatientDetailScreen
**Location:** `lib/features/patient/presentation/patient_detail_screen.dart`

**Purpose:**
Central screen for viewing everything about a patient. Tabbed layout.
Accessed from search results, appointment lists, and patient lists.
Role determines which tabs and actions are visible.

**UI Elements:**
- Top header: patient full name, clinic badge (Tagamoa / Masr Elgedida),
  package balance chip (shows balance, highlighted red if 0 or negative)
- 5 tabs: Info, Appointments, Medical Records, Payments, Documents

**Tab 1 — Info:**
- Full name, phone, DOB, gender, blood type, program, clinic
- Assigned doctors list (chips with doctor names)
- Edit button (🧑‍💼 👑 only) → EditPatientScreen
- Add/remove assigned doctor buttons (🧑‍💼 👑 only)

**Tab 2 — Appointments:**
- Chronological list of all appointments
- Each row: date/time, type badge, status badge, doctor name(s)
- Replacement indicator if any doctor on appointment is_replacement = true
- Tap row → AppointmentDetailScreen
- Add appointment FAB (🧑‍💼 👑 only) → NewAppointmentScreen

**Tab 3 — Medical Records:**
- List of completed visits with notes
- Each row: date, doctor name, short note preview
- Tap row → VisitDetailScreen
- Empty state: "No visit notes recorded yet"

**Tab 4 — Payments:**
- List of PaymentRecord rows, newest first
- Each row: date, reason, amount
- Total paid summary at top
- Add payment button (🧑‍💼 👑 only) → RecordPaymentScreen
- Edit package balance button (🧑‍💼 👑 only) → inline edit dialog

**Tab 5 — Documents:**
- Grid or list of uploaded files
- Each item: file name, upload date, download/view button
- Upload button (🧑‍💼 👑 only)
- Empty state: "No documents uploaded yet"

**Actions:**
- Edit patient (🧑‍💼 👑) → EditPatientScreen
- Add appointment (🧑‍💼 👑) → NewAppointmentScreen pre-filled with patient
- Record payment (🧑‍💼 👑) → RecordPaymentScreen pre-filled with patient
- Edit package balance (🧑‍💼 👑) → ConfirmationDialog with numeric input
- Upload document (🧑‍💼 👑) → FilePicker → upload to Supabase Storage
- View document → open file URL

**States:**
- Loading: skeleton loader for each tab
- Error: ErrorView with retry per tab
- Empty per tab: individual empty state messages

---

### [x] AppointmentDetailScreen
**Location:** `lib/features/appointment/presentation/appointment_detail_screen.dart`

**Purpose:**
Full detail view for a single appointment. Actions shown depend on role
and current appointment status.

**UI Elements:**
- Patient name + link to PatientDetailScreen
- Date and time
- Type badge (Session / Gehaz Shad Fakarat)
- Status badge (Scheduled / Checked In / Completed / Cancelled / No Show)
- Use package indicator (Yes / No)
- Doctors section:
    Active doctors list (name, replacement indicator if covering)
    Inactive doctors list collapsed under "Original doctors" (audit trail)
- Notes field (read-only for receptionist/admin, editable for 🩺)
- Action buttons (see below)

**Actions by role and status:**

| Action | Role | Visible when status is |
|--------|------|------------------------|
| Check In | 🧑‍💼 👑 | scheduled |
| Mark No Show | 🧑‍💼 👑 | scheduled |
| Cancel | 🧑‍💼 👑 | scheduled, checked_in |
| Mark Complete | 🩺 | checked_in |
| Add / Edit Notes | 🩺 | checked_in, completed |
| Swap Doctor | 🧑‍💼 👑 | scheduled, checked_in |

- Check In → ConfirmationDialog → update status to checked_in →
  if use_package: deduct 1 from package_balance (via trigger)
- Cancel → ConfirmationDialog → update status to cancelled
- Mark Complete → update status to completed
- Swap Doctor → SwapDoctorDialog (inline, not a new screen)
- Add/Edit Notes → inline editable text field, save button

**States:**
- Loading: full screen loader
- Error: ErrorView
- Loaded: full detail view

---

### [ ] VisitDetailScreen
**Location:** `lib/features/medical_records/presentation/visit_detail_screen.dart`

**Purpose:**
Read-only view of a completed visit's notes and details.
Accessed from PatientDetailScreen → Medical Records tab.

**UI Elements:**
- Patient name
- Date and time of visit
- Doctor(s) who attended
- Visit notes (full text)
- Appointment type and status badges

**Actions:**
- None for receptionist/admin (read-only)
- Edit notes (🩺) → only if this is the doctor's own appointment

**States:**
- Loading, Error, Loaded only (no empty state — screen only opened with data)

---

## 3. Receptionist + Admin

---

### 🧑‍💼 👑 [x] HomeScreen
**Location:** `lib/features/appointment/presentation/home_screen.dart`

**Purpose:**
Landing screen after login for receptionist and admin. Shows today's
full appointment schedule sorted by time. Primary action hub.

**UI Elements:**
- Date header: "Today, [Day] [Date]"
- Appointment count summary: "X appointments today"
- Appointment list, sorted by scheduled_at ascending
- Each row:
    Time, patient name, doctor name(s), type badge, status badge
    Inline Check In button if status = scheduled
- FAB: + New Appointment → NewAppointmentScreen
- Search icon in AppBar → PatientSearchScreen

**Actions:**
- Tap appointment row → AppointmentDetailScreen
- Inline check in button → ConfirmationDialog → check in
- FAB → NewAppointmentScreen
- Search icon → PatientSearchScreen

**States:**
- Loading: list skeleton
- Empty: "No appointments scheduled for today"
- Error: ErrorView with retry

---

### 🧑‍💼 👑 [x] PatientSearchScreen
**Location:** `lib/features/patient/presentation/patient_search_screen.dart`

**Purpose:**
Search for any patient by name or phone number.
Entry point to all patient-related actions.

**UI Elements:**
- Search bar (auto-focused on open, debounced 300ms)
- Filter chip: clinic (All / Tagamoa / Masr Elgedida)
- Results list: patient name, phone, clinic badge, package balance chip
- FAB: + New Patient → NewPatientScreen

**Actions:**
- Type in search → debounced query → show results
- Tap result → PatientDetailScreen
- FAB → NewPatientScreen
- Clear search → return to empty/default state

**States:**
- Default (no query): show recent patients or prompt to search
- Loading: list skeleton while querying
- No results: "No patients found for '[query]'"
- Error: ErrorView with retry

---

### 🧑‍💼 👑 [x] NewPatientScreen
**Location:** `lib/features/patient/presentation/new_patient_screen.dart`

**Purpose:**
Register a new patient with all required info and assign doctors.

**UI Elements:**
- Full name field
- Phone number field
- Date of birth picker
- Gender selector (Male / Female)
- Blood type field (optional, free text or dropdown)
- Program field (free text)
- Clinic selector (Tagamoa / Masr Elgedida)
- Assign doctors section:
    Multi-select from active doctors list
    At least one doctor required
    Shows selected doctors as removable chips
- Upload documents section (optional at creation):
    File picker button
    List of selected files before upload
- Save button

**Actions:**
- Save → validate → create Patient → create PatientDoctor rows →
  upload documents if any → navigate to PatientDetailScreen for new patient
- Cancel → ConfirmationDialog if form has data → pop

**States:**
- Default: empty form
- Loading: save button spinner, form disabled
- Error: inline field errors + server error banner
- Doctors list loading: small spinner in doctors section

**Validation:**
- Full name: required
- Phone: required, numeric
- Clinic: required
- At least one doctor assigned: required

---

### 🧑‍💼 👑 [x] EditPatientScreen
**Location:** `lib/features/patient/presentation/edit_patient_screen.dart`

**Purpose:**
Edit an existing patient's information. Same form as NewPatientScreen
but pre-filled. Opened from PatientDetailScreen → Info tab.

**UI Elements:**
- Same fields as NewPatientScreen, all pre-filled
- Save changes button
- Cancel button

**Actions:**
- Save → validate → update Patient row → update PatientDoctor rows
  (add new, remove deselected) → pop back to PatientDetailScreen
- Cancel → ConfirmationDialog if changes detected → pop

**Notes:**
- Changing assigned doctors here does NOT affect existing appointments
  (AppointmentDoctor rows are independent)
- Show a subtle info note: "Changing assigned doctors will not affect
  existing appointments"

---

### 🧑‍💼 👑 [x] NewAppointmentScreen
**Location:** `lib/features/appointment/presentation/new_appointment_screen.dart`

**Purpose:**
Book one or multiple appointments for a patient. Supports single booking
and recurring booking (multiple dates generated from a pattern).

**UI Elements:**
- Patient selector (search, pre-filled if opened from PatientDetailScreen)
- Appointment type selector (Session / Gehaz Shad Fakarat)
- Doctor selector:
    Multi-select, max 2
    Only shows doctors assigned to the selected patient
    Disabled until patient is selected
- Use package Switch toggle (default: on)
- Live Ledger Preview Card:
    * Displays 4 metrics: Current Balance, Upcoming Booked, Net Available Balance, and Current Order Count.
    * Shifts color themes dynamically from success (green) to warning (crimson) on deficits.
- Single / Recurring toggle:

    If Single:
      Date picker
      Time picker

    If Recurring:
      Day-of-week multi-select (Sat / Sun / Mon / Tue / Wed / Thu / Fri)
      Time picker (same time for all)
      Number of sessions input (numeric)
      Preview section: "This will create X appointments:"
        scrollable list of generated dates
        dates that conflict with existing appointments highlighted in red
        (conflict = same patient, same doctor, overlapping time)

- Confirm button

**Actions:**
- Select patient → load their assigned doctors into doctor selector
- Toggle recurring → show/hide recurring fields
- Change days / session count → regenerate preview dates
- Confirm (single) → create 1 Appointment + AppointmentDoctor rows → pop
- Confirm (recurring) → create N Appointments + AppointmentDoctor rows
  for each → show success: "X appointments created" → pop
- Cancel → ConfirmationDialog if form has data → pop
- Live Ledger update → recalculates balance and leftover slots reactively as form values change.

**States:**
- Default: empty form
- Loading doctors: spinner in doctor selector
- Loading confirm: button spinner, form disabled
- Error: server error banner
- Conflict warning: highlighted dates in preview (warning, not a blocker —
  receptionist can still confirm)
- Deficit Lock: crimson style diagnostics card, primary Confirm button disabled.

**Validation:**
- Patient: required
- Type: required
- At least 1 doctor: required
- Date/time: required for single
- Days + session count: required for recurring, session count min 1
- Package balance validation: locks submit if proposed count exceeds net available balance when package booking is selected.

---

### 🧑‍💼 👑 [ ] RecordPaymentScreen
**Location:** `lib/features/payments/presentation/record_payment_screen.dart`

**Purpose:**
Record a payment made by a patient. Pure record — no balance tracking.

**UI Elements:**
- Patient display (name, non-editable if pre-filled from PatientDetailScreen)
- Amount field (numeric, decimal allowed)
- Reason section:
    Quick-select chips: "Package" / "Session" / "Gehaz" / "Other"
    If "Package" selected:
      Package selector dropdown (from ClinicSettings.packages)
      Amount auto-fills from selected package price (editable)
    If "Other" selected:
      Free text field for custom reason
- Save button

**Actions:**
- Select package → auto-fill amount field
- Save → validate → insert PaymentRecord row → pop back

**States:**
- Default: empty form (amount + reason)
- Loading packages: spinner in package selector
- Loading save: button spinner
- Error: server error banner

**Validation:**
- Amount: required, must be > 0
- Reason: required (chip selection or free text)

---

### 🧑‍💼 👑 [ ] ManageReplacementScreen
**Location:** `lib/features/replacements/presentation/manage_replacement_screen.dart`

**Purpose:**
Create a doctor replacement for a specific date. After creating the
DoctorReplacement record, immediately shows the affected appointments
checklist for optional bulk swapping.

**UI Elements:**
- Step 1 — Create Replacement:
    Absent doctor selector (dropdown of active doctors)
    Covering doctor selector (dropdown of active doctors, excludes absent)
    Date picker (default: today)
    Confirm replacement button

- Step 2 — Affected Appointments (shown after Step 1 confirms):
    Header: "Dr. [Absent] has X appointments on [date]"
    Checklist of affected appointments:
      Each row: time, patient name, current doctors
      Checkbox to select for swap
    "Select all" toggle
    "Apply to selected" button
    "Skip, I'll handle manually" button

**Actions:**
- Confirm replacement → check for existing replacement on that date
  for that doctor → if exists: ConfirmationDialog "A replacement already
  exists for Dr. X on this date. Replace it?" → create/update
  DoctorReplacement row → load affected appointments → show Step 2
- Apply to selected → for each selected appointment:
    set current doctor's AppointmentDoctor row is_active = false
    insert new AppointmentDoctor row for covering doctor
    (is_replacement: true, replaced_doctor_id: absent doctor) → show
    success count → pop
- Skip → pop immediately

**States:**
- Step 1 default: empty selectors
- Step 1 loading: button spinner
- Step 2 loading appointments: list skeleton
- Step 2 empty: "No appointments found for Dr. X on this date" +
  Skip button still shown
- Error: error banner at current step

---

## 4. Doctor

---

### 🩺 [ ] MyScheduleScreen
**Location:** `lib/features/appointment/presentation/my_schedule_screen.dart`

**Purpose:**
Landing screen after login for doctors. Shows their own appointments
filtered to active AppointmentDoctor rows only.

**UI Elements:**
- Toggle: Today / This Week
- Today view: list of appointments sorted by time
- Week view: 7-day scrollable list grouped by date
- Each appointment row:
    Time, patient name, type badge, status badge
    "Covering [Dr. X]" label if is_replacement = true for this doctor
- No FAB (doctors cannot create appointments)

**Actions:**
- Tap appointment → AppointmentDetailScreen
- Toggle Today / This Week → switch view

**States:**
- Loading: list skeleton
- Empty today: "No appointments scheduled for today"
- Empty week: "No appointments this week"
- Error: ErrorView with retry

---

### 🩺 [ ] MyPatientsScreen
**Location:** `lib/features/patient/presentation/my_patients_screen.dart`

**Purpose:**
List of all patients assigned to the logged-in doctor via PatientDoctor.
Does not include replacement patients (those are separate).

**UI Elements:**
- Search bar (debounced, searches name and phone)
- Filter chip: clinic (All / Tagamoa / Masr Elgedida)
- Patient list: name, phone, clinic badge
- Count summary: "X patients"

**Actions:**
- Search → filter list
- Tap patient → PatientDetailScreen (doctor view — no edit actions)

**States:**
- Loading: list skeleton
- Empty (no patients assigned): "No patients assigned to you yet"
- No search results: "No patients found for '[query]'"
- Error: ErrorView with retry

---

### 🩺 [ ] ReplacementPatientsScreen
**Location:** `lib/features/replacements/presentation/replacement_patients_screen.dart`

**Purpose:**
List of patients the doctor can access today because of an active
DoctorReplacement record where covering_doctor_id = current doctor
and replacement_date = today.

**UI Elements:**
- Header banner: "You are covering for [Dr. X] today"
  (one banner per active replacement if covering multiple doctors)
- Patient list: name, phone, clinic badge,
  "Covering [Dr. X]" label per patient
- Search bar

**Actions:**
- Search → filter list
- Tap patient → PatientDetailScreen (same doctor view as MyPatientsScreen)

**States:**
- Loading: list skeleton
- Empty: "No replacement patients assigned to you today"
- Error: ErrorView with retry

**Notes:**
- If no DoctorReplacement exists for today for this doctor,
  show empty state immediately (no loading needed)

---

### 🩺 [ ] InitiateReplacementScreen
**Location:** `lib/features/replacements/presentation/initiate_replacement_screen.dart`

**Purpose:**
Allows a doctor to assign a covering doctor for themselves on a specific date.
Doctor can only initiate replacements for themselves (absent_doctor = self).

**UI Elements:**
- Absent doctor: pre-filled with current doctor (non-editable, display only)
- Covering doctor selector (dropdown of all active doctors except self)
- Date picker (default: tomorrow)
- Confirm button

**Actions:**
- Confirm → check for existing replacement → if exists: ConfirmationDialog
  "You already have a replacement on this date. Replace it?" →
  create/update DoctorReplacement → show success message →
  navigate to affected appointments checklist
  (same Step 2 UI as ManageReplacementScreen, reuse the widget)

**States:**
- Default: self pre-filled, covering and date empty
- Loading: button spinner
- Error: error banner

---

### 🩺 [ ] AddVisitNotesScreen
**Location:** `lib/features/medical_records/presentation/add_visit_notes_screen.dart`

**Purpose:**
Doctor adds or edits notes for a specific appointment.
Only accessible when appointment status is checked_in or completed.
Only the doctor assigned to (or covering) the appointment can edit.

**UI Elements:**
- Patient name (non-editable header)
- Date and time (non-editable header)
- Notes text area (large, multiline)
- Save Notes button
- Mark as Complete button (only if status = checked_in)

**Actions:**
- Save Notes → update appointment.notes field → show success snackbar
- Mark as Complete → ConfirmationDialog → update status to completed →
  pop back to AppointmentDetailScreen

**States:**
- Loading: full screen loader
- Loaded: form pre-filled with existing notes if any
- Saving: button spinner
- Error: error banner

**Notes:**
- Saving notes and marking complete are two separate actions
- Saving notes does NOT change the appointment status
- Can save notes multiple times (updates the same field)

---

## 5. Admin Only

---

### 👑 [ ] AdminHubScreen
**Location:** `lib/features/admin/presentation/admin_hub_screen.dart`

**Purpose:**
  Landing screen for the Admin tab in the bottom navigation.
  A simple grid of cards linking to all admin-only destinations.
  Exists because admin has more destinations than fit in bottom nav tabs.

**UI Elements:**
  - 4 tappable cards in a 2x2 grid:
      Doctor Applications  → DoctorApplicationsScreen
      Staff Management     → StaffListScreen
      Clinic Settings      → ClinicSettingsScreen
      Reports              → ReportsScreen
  - Each card: icon, title, subtitle describing what it does

**Actions:**
  - Tap any card → navigate to that screen

**States:**
  - No loading, error, or empty states needed
  - Static screen, no data fetching

---

### 👑 [ ] DoctorApplicationsScreen
**Location:** `lib/features/admin/presentation/doctor_applications_screen.dart`

**Purpose:**
List of all pending doctor registrations (Staff rows where
role = 'doctor' AND is_active = false). Admin reviews and
approves or rejects each application.

**UI Elements:**
- Tab bar: Pending / All Applications
- Pending tab: list of unapproved doctor applications
- All tab: list including approved doctors (is_active: true)
  and rejected (deleted, so won't appear — pending + approved only)
- Each pending row:
    Doctor name, email, phone, registration date
    Approve button (green)
    Reject button (red)
- Each approved row:
    Doctor name, email, phone, approved indicator
    (read-only, no actions)

**Actions:**
- Approve → ConfirmationDialog "Approve Dr. [Name]? They will be able
  to log in immediately." → set Staff.is_active = true → move row
  to approved tab
- Reject → ConfirmationDialog "Reject and delete this application?
  This cannot be undone." → delete Staff row →
  delete Supabase Auth user → remove from list

**States:**
- Loading: list skeleton
- Empty pending: "No pending applications"
- Empty all: "No doctor accounts found"
- Error: ErrorView with retry

**Notes:**
- Approving sets is_active = true on the existing Staff row
- No password is set or changed — doctor already set their password
  during registration and can log in immediately after approval
- Rejecting permanently deletes both the Staff row and the
  Supabase Auth user (use Supabase admin client for auth deletion)

---

### 👑 [ ] StaffListScreen
**Location:** `lib/features/staff/presentation/staff_list_screen.dart`

**Purpose:**
View and manage all active staff members (receptionists and admins).
Does not include doctors — those are managed in DoctorApplicationsScreen.

**UI Elements:**
- Filter chips: All / Super Admin / Receptionist
- Staff list: name, email, role badge, is_active status
- Each row: tap → StaffDetailScreen
- FAB: + Add Staff → StaffFormScreen

**Actions:**
- Tap row → StaffDetailScreen
- FAB → StaffFormScreen (new staff)

**States:**
- Loading: list skeleton
- Empty: "No staff members found"
- Error: ErrorView with retry

---

### 👑 [ ] StaffFormScreen
**Location:** `lib/features/staff/presentation/staff_form_screen.dart`

**Purpose:**
Add a new staff member or edit an existing one.
Used for receptionists and admins only (not doctors).

**UI Elements:**
- Full name field
- Email field
- Role selector (Receptionist / Super Admin)
- Password field (only shown when creating new staff)
- Confirm password field (only shown when creating new staff)
- Is Active toggle (only shown when editing)
- Save button

**Actions:**
- Save (new) → validate → create Supabase Auth user →
  insert Staff row (is_active: true) → pop back to StaffListScreen
- Save (edit) → validate → update Staff row → pop back
- Deactivate toggle → ConfirmationDialog "Deactivate [Name]?
  They will no longer be able to log in." → update is_active

**States:**
- Default: empty (new) or pre-filled (edit)
- Loading: button spinner
- Error: inline field errors + server error banner

**Validation:**
- Full name: required
- Email: required, valid format, unique
- Role: required
- Password: required for new, min 8 characters
- Confirm password: must match

---

### 👑 [ ] ClinicSettingsScreen
**Location:** `lib/features/admin/presentation/clinic_settings_screen.dart`

**Purpose:**
Manage the clinic's session packages (name, session count, price).
Packages are stored as JSONB in ClinicSettings table (single row).

**UI Elements:**
- Packages section:
    List of current packages:
      Each row: name, session count, price, edit button, delete button
    Add package button → inline form or bottom sheet:
      Package name field
      Session count field (integer)
      Price field (numeric)
      Save package button

**Actions:**
- Add package → validate → append to packages JSONB array → save
- Edit package → open inline form pre-filled → validate → update array → save
- Delete package → ConfirmationDialog "Delete [Package Name]?
  This will not affect existing payment records." → remove from array → save
- All saves update the single ClinicSettings row

**States:**
- Loading: list skeleton
- Empty packages: "No packages configured yet. Add your first package."
- Saving: button spinner
- Error: error banner

**Notes:**
- Package deletion does not affect PaymentRecord rows since
  reason is stored as free text, not a foreign key
- There is only ever one row in ClinicSettings

---

### 👑 [ ] ReportsScreen
**Location:** `lib/features/admin/presentation/reports_screen.dart`

**Purpose:**
High-level clinic statistics. Numbers only for now — no charts yet.

**UI Elements:**
- Filter: All Clinics / Tagamoa / Masr Elgedida
- Date range selector: Today / This Week / This Month / Custom range
- Stats grid:
    Total patients registered
    New patients in period
    Total appointments in period
    Appointments by status (scheduled / completed / cancelled / no_show)
    Appointments by type (session / gehaz)
    Appointments per doctor (list: doctor name → count)
- Refresh button

**Actions:**
- Change filter or date range → reload all stats
- Refresh → reload

**States:**
- Loading: skeleton numbers (grey placeholder boxes)
- Loaded: stats grid
- Error: ErrorView with retry

---

## Shared Dialogs & Overlays
*(These are not screens — they are reusable widgets built in shared/widgets/)*

| Widget | Purpose |
|--------|---------|
| `ConfirmationDialog` | Generic "are you sure?" dialog with confirm/cancel |
| `LoadingOverlay` | Full-screen loading overlay for async operations |
| `ErrorView` | Error state with message and retry button |
| `EmptyState` | Empty list/data state with icon and message |
| `AppBadge` | Polymorphic colored badge (replaces StatusBadge, TypeBadge, ClinicBadge) |
| `AppChip` | Entity token with optional delete button (replaces ReplacementChip) |

> [!NOTE]
> - **SwapDoctorDialog** is built inline during [AppointmentDetailScreen](#-appointmentdetailscreen).
> - **PackageBalanceEditDialog** is built inline during [PatientDetailScreen](#-patientdetailscreen).
>
> These are feature-specific and will be extracted to shared/widgets only if reused across more than one screen.

---

## Build Order

```
Phase 3 — Core Layer
  [x]  AppException, Failure types, Result<T>
  [x]  SupabaseService wrapper
  [x]  AppColors, AppSizes, AppTextStyles
  [x]  AppStrings
  [x]  formatDate, formatCurrency, formatPhone

Phase 3 — Shared Widgets
  [x]  AppButton
  [x]  AppTextField
  [x]  AppSearchBar
  [x]  LoadingOverlay
  [x]  ErrorView
  [x]  AppSnackbar
  [x]  AppBadge
  [x]  AppChip
  [x]  SectionCard
  [x]  DataListTile
  [x]  ConfirmationDialog
  [x]  EmptyState
  [x]  InfoRow
  [x]  AppBottomSheet

Phase 4 — Navigation
  [x]  go_router setup with all routes defined upfront
  [x]  currentUserProvider + role-based redirect logic
  [x]  AppBottomNav
  [x]  AppShell

Phase 5 — Auth
  [x]  Auth repository
  [x]  LoginScreen
  [x]  DoctorRegisterScreen

Phase 6 — Patients
  [x]  PatientSearchScreen
  [x]  PatientDetailScreen (tabs scaffold first, fill tabs one by one)
  [x]  NewPatientScreen
  [x]  EditPatientScreen

Phase 7 — Appointments
  [x]  HomeScreen
  [x]  NewAppointmentScreen
  [x]  AppointmentDetailScreen

Phase 8 — Medical Records
  [ ]  AddVisitNotesScreen
  [ ]  VisitDetailScreen

Phase 9 — Payments
  [ ]  RecordPaymentScreen

Phase 10 — Replacements
  [ ]  ManageReplacementScreen
  [ ]  InitiateReplacementScreen
  [ ]  ReplacementPatientsScreen

Phase 11 — Doctor
  [ ]  MyScheduleScreen
  [ ]  MyPatientsScreen

Phase 12 — Admin
  [ ]  AdminHubScreen
  [ ]  DoctorApplicationsScreen
  [ ]  StaffListScreen
  [ ]  StaffFormScreen
  [ ]  ClinicSettingsScreen
  [ ]  ReportsScreen

Polish
  [ ]  All empty states reviewed
  [ ]  All error states reviewed
  [ ]  All role guards audited on every action button
```

---

*Last updated: Phase 3 Shared Widgets and Phase 4 Navigation Widgets complete*
*Next: Routing (go_router, currentUserProvider) & Phase 5 Auth*
