# AGENT_CONTEXT.md
# Spine Clinic App — Master Architecture Contract
# Paste this entire file at the start of every agent conversation.

---

## 1. Stack & Versions

| Layer | Package | Version |
|-------|---------|---------|
| Framework | Flutter stable | Dart SDK ^3.6.0 |
| State Management | flutter_riverpod | ^3.3.1 |
| State Generation | riverpod_annotation + riverpod_generator | ^4.0.2 / ^4.0.3 |
| Backend | supabase_flutter | ^2.8.0 |
| Routing | go_router | ^14.0.0 |
| Models | freezed_annotation + freezed | ^3.0.0-dev.1 |
| Serialization | json_serializable | ^6.9.0 |
| Forms | flutter_form_builder + form_builder_validators | latest |
| Files | file_picker | latest |
| i18n | intl | latest |

---

## 2. Folder Structure

Every file must live inside this exact structure. Never create folders
outside it. Never place business logic in presentation. Never place
Supabase calls in widgets.

```
lib/
├── core/
│   ├── constants/       # AppColors, AppSizes, AppStrings, AppTextStyles
│   ├── errors/          # AppException, Failure types, Result<T>
│   ├── network/         # Supabase client singleton, SupabaseService
│   └── utils/           # formatDate, formatCurrency, formatPhone
├── shared/
│   └── widgets/         # AppButton, AppTextField, AppSearchBar,
│                        # LoadingOverlay, ErrorView, EmptyState,
│                        # ConfirmationDialog, AppBadge, AppChip,
│                        # SectionCard, DataListTile, InfoRow,
│                        # AppBottomSheet, AppBottomNav, AppShell
└── features/
    ├── auth/
    ├── patient/
    ├── appointment/
    ├── medical_records/
    ├── payments/
    ├── replacements/
    ├── staff/
    └── admin/
        ├── data/         # DTOs, repository implementations
        ├── domain/       # Freezed models, repository interfaces
        └── presentation/ # Screens, providers, notifiers
```

---

## 3. Full Data Schema

These are the exact tables, fields, and types in Supabase.
Every Freezed model must map to this schema precisely.

### staff
```
id                uuid          PK, default gen_random_uuid()
user_id           uuid          unique, references auth.users(id) on delete cascade, nullable
full_name         text          not null
email             text          unique, not null
phone             text          nullable
role              user_role     enum: 'super_admin' | 'receptionist' | 'doctor'
is_active         boolean       default true
created_at        timestamptz   default now()
```

### patients
```
id                uuid          PK, default gen_random_uuid()
full_name         text          not null
phone_number      text          not null
program           text          nullable
clinic            clinic_location enum: 'tagamoa' | 'masr_elgedida', not null
package_balance   integer       default 0 (can go negative, no constraint)
created_by        uuid          references staff(id) on delete set null, nullable
created_at        timestamptz   default now()
```

### patient_doctors  (many-to-many junction)
```
patient_id        uuid          references patients(id) on delete cascade
doctor_id         uuid          references staff(id) on delete cascade
assigned_at       timestamptz   default now()
PK: (patient_id, doctor_id)
```

### patient_documents
```
id                uuid          PK, default gen_random_uuid()
patient_id        uuid          references patients(id) on delete cascade
file_url          text          not null (Supabase Storage URL)
file_name         text          not null
uploaded_by       uuid          references staff(id) on delete set null, nullable
uploaded_at       timestamptz   default now()
```

### appointments
```
id                uuid          PK, default gen_random_uuid()
patient_id        uuid          references patients(id) on delete cascade
type              appointment_type enum: 'session' | 'gehaz_shad_fakarat'
scheduled_at      timestamptz   default now()
status            appointment_status enum: 'scheduled' | 'checked_in' | 'completed'
                                | 'cancelled' | 'no_show', default 'scheduled'
use_package       boolean       default true
notes             text          nullable
created_by        uuid          references staff(id) on delete set null, nullable
created_at        timestamptz   default now()

NOTE: No doctor_id on this table.
      Doctors are linked via appointment_doctors table only.
```

### appointment_doctors
```
id                uuid          PK, default gen_random_uuid()
appointment_id    uuid          references appointments(id) on delete cascade
doctor_id         uuid          references staff(id) on delete restrict
is_replacement    boolean       default false
replaced_doctor_id uuid         references staff(id) on delete set null, nullable
                                (null when is_replacement = false)
                                (set to absent doctor when is_replacement = true)
is_active         boolean       default true
                                (false = swapped out, kept for audit trail)
added_by          uuid          references staff(id) on delete set null, nullable
added_at          timestamptz   default now()

CONSTRAINT: Partial unique index (NOT inline unique constraint):
  CREATE UNIQUE INDEX unique_active_appointment_doctor
  ON appointment_doctors (appointment_id, doctor_id)
  WHERE (is_active = true);
```

### doctor_replacements
```
id                uuid          PK, default gen_random_uuid()
absent_doctor_id  uuid          references staff(id) on delete cascade
covering_doctor_id uuid         references staff(id) on delete cascade
replacement_date  date          not null
initiated_by      uuid          references staff(id) on delete set null, nullable
created_at        timestamptz   default now()

CONSTRAINT: UNIQUE (absent_doctor_id, replacement_date)
```

### payment_records
```
id                uuid          PK, default gen_random_uuid()
patient_id        uuid          references patients(id) on delete cascade
amount            numeric       not null
reason            text          not null (free text, e.g. 'Package', 'Session')
recorded_by       uuid          references staff(id) on delete set null, nullable
recorded_at       timestamptz   default now()
```

### clinic_settings  (single row)
```
id                uuid          PK, default gen_random_uuid()
packages          jsonb         not null, default '[]'::jsonb
                                format: [{name, session_count, price}, ...]
updated_by        uuid          references staff(id) on delete set null, nullable
updated_at        timestamptz   default now()
```

---

## 4. Permission Access Matrix

| Action | Super Admin | Receptionist | Doctor |
|--------|-------------|--------------|--------|
| Register patients | ✅ | ✅ | ❌ |
| View all patients | ✅ | ✅ | ❌ |
| View assigned patients | ✅ | ✅ | ✅ (own + replacements today) |
| Edit patient info | ✅ | ✅ | ❌ |
| Upload patient documents | ✅ | ✅ | ❌ |
| Edit package balance | ✅ | ✅ | ❌ |
| Book appointments | ✅ | ✅ | ❌ |
| Cancel appointments | ✅ | ✅ | ❌ |
| Check in patient | ✅ | ✅ | ❌ |
| Mark appointment complete | ✅ | ❌ | own only |
| Add visit notes | ✅ | ❌ | own + replacement |
| View payment records | ✅ | ✅ | ❌ (completely blocked) |
| Record payments | ✅ | ✅ | ❌ |
| Initiate replacement | ✅ | ✅ (manual override) | own only |
| Approve/reject doctors | ✅ | ❌ | ❌ |
| Manage staff accounts | ✅ | ❌ | ❌ |
| Configure clinic settings | ✅ | ❌ | ❌ |
| View reports | ✅ | ❌ | ❌ |

---

## 5. Appointment Doctor Rules

These rules govern the most complex part of the app.
The agent must follow these exactly.

1. `appointment_doctors` is the source of truth for who attends a session.
   Never use `patient_doctors` to infer who attends an appointment.

2. When booking, pre-fill doctor selector with the patient's assigned
   doctors from `patient_doctors`. Receptionist picks 1 or 2 explicitly.
   Never auto-assign.

3. Maximum 2 active `appointment_doctors` rows per appointment.
   Enforced in the repository layer, not the database.

4. Field semantics:
   - is_replacement = false → this is the originally booked doctor
   - is_replacement = true  → this doctor is covering someone else
   - replaced_doctor_id     → who they are covering (null if not replacement)
   - is_active = true       → this doctor is actively attending
   - is_active = false      → swapped out, kept for audit trail only

5. NEVER delete appointment_doctors rows. Only set is_active = false.

6. Doctor schedule queries must filter:
   WHERE doctor_id = current_doctor_id AND is_active = true

7. The partial unique index allows chain replacements:
   Hassan → Khaled → Mona is valid because old rows become is_active=false
   and fall out of the unique index scope.

8. is_active=false rows are shown only in audit/history views.
   Never show them in active schedule or appointment lists.

9. When displaying an appointment's doctors:
   Active doctors:   show normally, add "Covering Dr. X" label if is_replacement=true
   Inactive doctors: collapse under "Original doctors" section, read-only

---

## 6. Replacement Flow Rules

DoctorReplacement and AppointmentDoctor serve different purposes.
The agent must never conflate them.

DoctorReplacement  = ACCESS CONTROL ONLY.
                     Gives the covering doctor READ access to the absent
                     doctor's patients on that specific date via RLS.
                     Does NOT automatically modify any appointment rows.

AppointmentDoctor  = ATTENDANCE RECORD per appointment.
                     Must be manually updated by receptionist after a
                     replacement is created, via the bulk swap checklist UI.

Flow:
  Step 1: Create DoctorReplacement record (access granted immediately)
  Step 2: UI shows checklist of absent doctor's appointments that day
  Step 3: Receptionist selects which appointments to swap
  Step 4: For each selected appointment:
            - Set original doctor's AppointmentDoctor.is_active = false
            - Insert new AppointmentDoctor row for covering doctor
              (is_replacement: true, replaced_doctor_id: absent doctor id)
  Step 5: Receptionist can skip Step 2-4 and handle manually later

Creating a DoctorReplacement NEVER auto-modifies AppointmentDoctor rows.
This is intentional to handle partial-day replacements, patient refusals,
and late record entries safely.

---

## 7. Package Balance Rules

- package_balance lives on the patients row as an integer
- It can go negative — no floor constraint
- Deduction and refund are handled by a Postgres trigger (not Flutter code):
    - **Deduction (-1)**: Fires when appointment status changes TO 'checked_in' OR 'completed' from a 'scheduled' state, AND use_package = true.
    - **Refund (+1)**: Fires when appointment status changes TO 'cancelled' from a 'checked_in' or 'completed' state, AND the old use_package was true.
- Flutter does NOT manually deduct or refund balance — trust the trigger entirely
- Receptionist can manually edit balance via PackageBalanceEditDialog
  (direct update to patients.package_balance)
- The UI shows a warning indicator when balance is 0 or negative

---

## 8. Doctor Registration & Approval Flow

- Doctor registers on public DoctorRegisterScreen (no auth required)
  Fields: full_name, email, phone, password, confirm_password
- On submit: create Supabase Auth user + Staff row (is_active: false, role: 'doctor')
- Doctor is NOT logged in after registration — show success message only
- Admin approves: set Staff.is_active = true → doctor can log in immediately
  with the password they set during registration
- Admin rejects: delete Staff row + delete Supabase Auth user permanently
  (use Supabase admin client for auth user deletion)
- No email notifications (email service not configured)
- On login: if Staff.is_active = false → sign out immediately, show
  "Your account is pending admin approval."

---

## 9. Clinic Scope Rules

- clinic on patients is a LABEL only: 'tagamoa' | 'masr_elgedida'
- Does NOT affect RLS or data access for any role in the current version
- Receptionists and admins see ALL patients regardless of clinic
- Doctors see their assigned patients regardless of clinic
- Reports can filter by clinic for stat breakdowns
- This may become an access-control field in a future version
  DO NOT hardcode assumptions that it will always be a label

---

## 10. RLS Policies (Verified SQL)

### Staff resolution function
```sql
CREATE OR REPLACE FUNCTION public.get_auth_staff_profile()
 RETURNS TABLE(staff_id uuid, staff_role user_role, staff_active boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT id, role, is_active 
    FROM public.staff 
    WHERE user_id = auth.uid() 
    LIMIT 1;
END;
$function$;
```

### Patient select policies
```sql
-- Super Admins and Receptionists have full access to patients (ALL)
CREATE POLICY "Super Admins and Receptionists have full access to patients" ON public.patients
FOR ALL TO authenticated USING (
  EXISTS (
    SELECT 1 FROM public.get_auth_staff_profile()
    WHERE staff_role IN ('super_admin'::user_role, 'receptionist'::user_role)
    AND staff_active = true
  )
);

-- Doctors can view assigned or replacement patients only (SELECT)
CREATE POLICY "Doctors can view assigned or replacement patients only" ON public.patients
FOR SELECT TO authenticated USING (
  (EXISTS (
    SELECT 1 FROM public.get_auth_staff_profile()
    WHERE staff_role = 'doctor'::user_role
    AND staff_active = true
  )) AND (
    id IN (
      SELECT pd.patient_id FROM public.patient_doctors pd
      WHERE pd.doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile())
    ) OR id IN (
      SELECT pd.patient_id
      FROM public.patient_doctors pd
      JOIN public.doctor_replacements dr ON dr.absent_doctor_id = pd.doctor_id
      WHERE dr.covering_doctor_id = (SELECT staff_id FROM public.get_auth_staff_profile())
      AND dr.replacement_date = CURRENT_DATE
    )
  )
);

-- Super Admins and Receptionists can delete patients (DELETE)
CREATE POLICY "Super Admins and Receptionists can delete patients" ON public.patients
FOR DELETE TO authenticated USING (
  EXISTS (
    SELECT 1 FROM public.get_auth_staff_profile()
    WHERE staff_role IN ('super_admin'::user_role, 'receptionist'::user_role)
    AND staff_active = true
  )
);
```

### Staff policies
```sql
-- Allow users to view their own profile (SELECT)
CREATE POLICY "Allow users to view their own profile" ON public.staff
FOR SELECT TO authenticated
USING (user_id = auth.uid());

-- Allow users to insert their own profile (INSERT)
CREATE POLICY "Allow users to insert their own profile" ON public.staff 
FOR INSERT TO authenticated 
WITH CHECK (
  user_id = auth.uid() 
  AND is_active = false 
  AND role = 'doctor'::user_role
);
```

### Partial unique index (not a constraint)
```sql
CREATE UNIQUE INDEX unique_active_appointment_doctor
ON public.appointment_doctors (appointment_id, doctor_id)
WHERE (is_active = true);
```

### Package balance trigger
```sql
CREATE OR REPLACE FUNCTION public.handle_package_deduction()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Case A: Appointment updates to checked_in or completed from a scheduled state
    IF (TG_OP = 'UPDATE') AND (OLD.status = 'scheduled') AND (NEW.status IN ('checked_in', 'completed')) AND (NEW.use_package = true) THEN
        UPDATE public.patients 
        SET package_balance = package_balance - 1 
        WHERE id = NEW.patient_id;
        
    -- Case B: Receptionist cancels an already checked_in/completed session (Refund Balance)
    ELSIF (TG_OP = 'UPDATE') AND (OLD.status IN ('checked_in', 'completed')) AND (NEW.status = 'cancelled') AND (OLD.use_package = true) THEN
        UPDATE public.patients 
        SET package_balance = package_balance + 1 
        WHERE id = NEW.patient_id;
    END IF;
    
    RETURN NEW;
END;
$function$;

CREATE TRIGGER trigger_appointment_package_deduction
  AFTER UPDATE OF status ON public.appointments
  FOR EACH ROW
  EXECUTE FUNCTION handle_package_deduction();
```

---

## 11. The 10 Inviolable Code Rules

1. No file longer than 200 lines. Split it immediately if it grows past that.
2. No Supabase calls inside widgets. All data access in repository classes only.
3. All state via Riverpod. Never use setState except trivial local UI animations.
4. Every async repository function returns Result<T> not raw Future<T>.
5. No dynamic types. No var where type is ambiguous. Zero use of 'dynamic'.
6. Every user action that writes data must check role from currentUserProvider.
7. No hardcoded strings. All text via AppStrings constants class.
8. No hardcoded colors or sizes. All via AppColors and AppSizes constants.
9. Every screen must handle four states: loading, error, empty, and data.
10. Run flutter analyze and confirm zero errors before marking any task done.
11. Phone-only app. No hover states, no MouseRegion widgets, no desktop/web interaction patterns. Touch only.

---

## 12. Data Flow Contract

Every feature must follow this exact flow. No shortcuts.

```
Widget (trigger action)
  ↓
Riverpod Provider / Notifier (holds state, calls repository)
  ↓
Repository Interface (domain layer, defines the contract)
  ↓
Repository Implementation (data layer, calls SupabaseService)
  ↓
SupabaseService (core/network, wraps Supabase client)
  ↓
Supabase (database + RLS enforces access)
```

Going upward on a response:
```
Supabase (returns raw data or error)
  ↓
SupabaseService (normalizes error into AppException)
  ↓
Repository Implementation (maps raw data to Freezed domain model)
  ↓
Repository returns Result<T> (success or Failure)
  ↓
Riverpod Provider (exposes AsyncValue<T> to UI)
  ↓
Widget (renders loading / error / empty / data state)
```

---

## 13. Screen Inventory Reference

Full screen list, per-screen UI contracts, action definitions,
and numbered build order are documented in SCREENS.md.
Always check SCREENS.md before building any presentation layer file.
Never build a screen that is not listed in SCREENS.md.

## 14. Shared Widgets Inventory

SHARED WIDGETS — FINAL LIST

Core UI Primitives:
  AppButton          — primary/secondary/danger variants, isLoading state
  AppTextField       — focus tracking, validation error state
  AppSearchBar       — inline search with debounce and clear button
  LoadingOverlay     — full-screen blocking overlay for async operations
  ErrorView          — displays AppException message with retry callback
  AppSnackbar        — global helper function (not a widget) for
                       success/error/info snackbars

Badges & Layout Atoms:
  AppBadge           — polymorphic colored label (replaces StatusBadge,
                       TypeBadge, ClinicBadge — driven by color + text params)
  AppChip            — entity token with optional trailing delete button
                       (replaces ReplacementChip, DoctorChip)
  SectionCard        — flat surface card with title and content slot
  DataListTile       — high-density list item with leading/middle/trailing
                       slots (covers patient rows, appointment rows, staff rows)
  ConfirmationDialog — reusable confirm/cancel dialog for destructive actions
  EmptyState         — centered icon + message for empty list/data states
  InfoRow            — label + value row for detail screens
  AppBottomSheet     — styled bottom sheet wrapper

Navigation & Shell:
  AppBottomNav       — role-based bottom navigation bar
  AppShell           — root scaffold: AppBar + body + AppBottomNav

---

## 15. Standard Prompt Template

Use this template for every task given to the agent.
Replace bracketed sections with the specific task details.

========================================================================
[PASTE ENTIRE AGENT_CONTEXT.MD ABOVE THIS LINE]
========================================================================

CURRENT TASK: Build [target class name and file path]

SPECIFIC REQUIREMENTS:
- [requirement 1]
- [requirement 2]

STATES TO HANDLE:
- Loading: use LoadingOverlay or skeleton
- Error: use ErrorView with retry
- Empty: use EmptyState widget
- Data: [describe what data state looks like]

ROLE RESTRICTIONS:
- [which buttons/sections are hidden for which roles]

BEFORE WRITING ANY CODE, RESPOND WITH:
1. Files you will create or modify (exact paths)
2. Data flow: Widget → Provider → Repository → Supabase
3. Any edge cases or architectural concerns

Then write the code.
========================================================================
