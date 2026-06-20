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
session_balance   integer       default 0 (PT sessions; may go negative)
traction_balance  integer       default 0 (traction sessions; may go negative)
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
type              appointment_type enum:
                                |- 'normal_pt_session'         (PT session)
                                |- 'spinal_traction_session'   (traction session)
                                |- 'initial_assessment'        (senior doctor, no deduction)
                                |- 'reassessment'              (senior doctor, no deduction)
                                |- (legacy 'check_up' values migrated to 'reassessment')
scheduled_at      timestamptz   default now()
status            appointment_status enum: 'scheduled' | 'checked_in' | 'completed'
                                | 'cancelled' | 'no_show', default 'scheduled'
use_package       boolean       default true
created_by        uuid          references staff(id) on delete set null, nullable
created_at        timestamptz   default now()

NOTE: No doctor_id on this table.
      Doctors are linked via appointment_doctors table only.

NOTE: Each appointment has exactly ONE type. A visit that comprises
      multiple modalities (e.g. Reassessment + PT) is recorded as
      multiple appointments on the same date with different types.
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
id                uuid              PK, default gen_random_uuid()
patient_id        uuid              references patients(id) on delete cascade
amount            numeric           not null
reason            text              not null
                                        Free text. Recommended values per type of sale:
                                        - 'Package (<name>)' for combined / single-kind packages
                                        - 'PT Session', 'Spinal Traction Session',
                                          'Initial Assessment', 'Reassessment'
recorded_by       uuid              references staff(id) on delete set null, nullable
recorded_at       timestamptz       default now()
session_balance_added  integer      default 0 (PT sessions credited when sold as a package)
traction_balance_added integer      default 0 (traction sessions credited when sold as a package)
```

### patient_notes
```
id                uuid          PK, default gen_random_uuid()
patient_id        uuid          references patients(id) on delete cascade
appointment_id    uuid          references appointments(id) on delete set null, nullable
created_by        uuid          references staff(id) on delete restrict
note_text         text          not null
created_at        timestamptz   default now()
updated_at        timestamptz   default now()
```

### clinic_settings  (single row)
```
id                uuid          PK, default gen_random_uuid()
packages          jsonb         not null, default '[]'::jsonb
                                format:
                                [
                                  {
                                    "name": "Gold Combo",
                                    "kind": "session" | "traction" | "combined",
                                    "session_count": 8,     // PT sessions (for session/combined)
                                    "tractions_count": 4,   // traction sessions (for traction/combined)
                                    "price": 4800
                                  }
                                ]
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
| Edit patient info | ✅ | ✅ | ✅ (assigned/covering only) |
| Upload patient documents | ✅ | ✅ | ❌ |
| Edit package balance | ✅ | ✅ | ❌ |
| Book appointments | ✅ | ✅ | ❌ |
| Cancel appointments | ✅ | ✅ | ❌ |
| Check in patient | ✅ | ✅ | ❌ |
| Mark appointment complete | ✅ | ❌ | own only |
| Add patient & visit notes | ✅ | ✅ | ✅ (any with view access) |
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

- Two package balances live as integer columns on the patients row:
    - `session_balance`   — counts PT sessions (debits on each completed 'normal_pt_session')
    - `traction_balance`  — counts traction sessions (debits on each completed 'spinal_traction_session')
- Both columns can go negative — no floor constraint
- Deduction and refund are handled by a Postgres trigger (not Flutter code):
    - **Deduction (-1)**: Fires when appointment status changes TO 'checked_in' OR 'completed' from a 'scheduled' state, AND use_package = true. Only fires for `normal_pt_session` and `spinal_traction_session` appointment types. Chooses bucket by type.
    - **Refund (+1)**: Fires when appointment status changes TO 'cancelled' from a 'checked_in' or 'completed' state, AND the old use_package was true. Same per-type routing.
- Assessments (`initial_assessment`, `reassessment`) **never deduct** any balance — they are billed independently.
- Flutter does NOT manually deduct or refund balance — trust the trigger entirely
- Receptionist can manually edit BOTH balances via PackageBalanceEditDialog
  (single update to patients row over `session_balance` + `traction_balance`)
- The UI shows a warning indicator per bucket when that bucket is ≤ 0
- When a clinic package is sold, `recordPaymentController.submitPayment(...)` accepts
  `sessionBalanceAdded` and `tractionBalanceAdded` parameters. It writes the
  payment_records row with both values AND atomically increments both patient
  balances via a follow-up `updatePatient()` call. The trigger is NOT used for
  package sales — patient balances go UP on sale, not down.

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
DECLARE
  bucket text;
BEGIN
  -- Map appointment type to balance bucket. Assessments never decrement.
  IF NEW.type = 'normal_pt_session'::public.appointment_type THEN
    bucket := 'session_balance';
  ELSIF NEW.type = 'spinal_traction_session'::public.appointment_type THEN
    bucket := 'traction_balance';
  ELSE
    RETURN NEW; -- initial_assessment / reassessment: no auto-deduction
  END IF;

  -- Deduct (-1) on scheduled → checked_in/completed (when use_package = true)
  IF TG_OP = 'UPDATE' AND OLD.status = 'scheduled'
     AND NEW.status IN ('checked_in', 'completed')
     AND NEW.use_package = true THEN
    EXECUTE format(
      'UPDATE public.patients SET %I = %I - 1 WHERE id = $1', bucket, bucket)
      USING NEW.patient_id;

  -- Refund (+1) when cancelling after check-in/completion
  ELSIF TG_OP = 'UPDATE' AND OLD.status IN ('checked_in', 'completed')
     AND NEW.status = 'cancelled'
     AND OLD.use_package = true THEN
    EXECUTE format(
      'UPDATE public.patients SET %I = %I + 1 WHERE id = $1', bucket, bucket)
      USING NEW.patient_id;
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

## Inviolable Code & UI Rules

1. **Strict File Length Limit:** No file longer than 200 lines. Split components or files immediately if they grow past this threshold.
2. **Encapsulated Data Access:** No Supabase or database engine calls directly inside widgets. All data access must reside exclusively inside repository classes.
3. **Unified State Management:** Manage all application state via Riverpod. Never use `setState` except for trivial, localized UI micro-animations.
4. **Type-Safe Async Architecture:** Every asynchronous repository function must return a `Result<T>` wrapper rather than a raw `Future<T>`.
5. **Strict Static Typing:** No dynamic types. Never use `var` where the type is ambiguous. Zero usage of the `dynamic` keyword.
6. **Role-Based Security Verification:** Every user action that writes or modifies data must explicitly verify roles and permissions via the `currentUserProvider`.
7. **Zero Hardcoded Strings:** All localized text, labels, and system messages must be sourced via the `AppStrings` constants class.
8. **Semantic Size Mapping:** No hardcoded layout sizing parameters. Dimensions must map completely to layout configurations inside the `AppSizes` token file.
9. **Mandatory UI States:** Every functional screen layout must explicitly handle and display four foundational structural states: `loading`, `error`, `empty`, and `data`.
10. **Zero-Tolerance Analysis:** Run `flutter analyze` and confirm zero warnings or errors before marking any individual task as complete.
11. **Mobile-Touch Focus:** Phone-only design paradigm. No hover states, no `MouseRegion` widgets, and no desktop/web-first interaction patterns. Ensure all touch targets use `InkWell` or `GestureDetector` optimized for immediate touch feedback.
12. **Debounced Network Queries:** Any interactive text search input or real-time filter execution hitting a Repository or Supabase must utilize a minimum 300ms debounce pattern via Riverpod or an explicit debouncer mechanism. Never trigger database operations on individual keystrokes.
13. **Modern Component Spacing:** Zero usage of raw `Divider()` lines between list components. Every list item row must be configured as a distinct Material 3 container/card element styled with uniform `BorderRadius.circular(16)`. Every row or card target must enforce a minimum internal layout padding of `EdgeInsets.all(16)` for physical touch comfort.
14. **Clean Mobile Control Layouts:** Never stack more than two filter inputs or dropdown controls vertically directly on a main screen surface. If a feature demands deeper control variables (e.g., Doctor, Status, Date Ranges), implement a horizontal scrolling row of Material 3 `ChoiceChip` components for primary selectors, alongside a trailing button that opens a structured `showModalBottomSheet`.
15. **Context-Driven Theme Tokens:** Zero usage of absolute color constants from `AppColors` directly within styling or visual component declarations. All component coloring parameters must be mapped dynamically from the active runtime theme context (e.g., `Theme.of(context).colorScheme.surfaceContainer` or `Theme.of(context).colorScheme.onSurface`) to ensure instant system theme compliance.
16. **Design System Compliance:** Zero usage of raw color values or hardcoded
    hex codes in any widget. All colors must come from the active theme via
    Theme.of(context). All spacing must reference AppSizes tokens. All text
    styles must reference AppTextStyles.

17. **Component Reuse Mandate:** Before building any new visual element, check
    shared/widgets/ first. If a suitable component exists, use it. If a new
    pattern is needed, build it in shared/widgets/ first, then use it. Never
    build one-off styled containers inline inside screens.

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
  AppBackButton      — styled native back button navigation
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

## 15. Codebase Rule Violations & Leftovers

This section tracks existing legacy code that violates the inviolable rules or contains unused files.

### Rule 1 Violations (Files exceeding 200 lines)
The following files exceed the 200-line limit:
- [app_strings.dart](file:///c:/Users/Elite-Store/spine_clinic_app/lib/core/constants/app_strings.dart) (225 lines) - Exception: centralized localization string definitions.
- [app_exception.dart](file:///c:/Users/Elite-Store/spine_clinic_app/lib/core/errors/app_exception.dart) (245 lines) - Base exception classes and Supabase mapper.
- [router.dart](file:///c:/Users/Elite-Store/spine_clinic_app/lib/core/network/router.dart) (243 lines) - Central app router configuration.
- [appointment_action_buttons.dart](file:///c:/Users/Elite-Store/spine_clinic_app/lib/features/appointment/presentation/widgets/appointment_action_buttons.dart) (213 lines) - Form/action buttons sheet.
- [booking_form_fields.dart](file:///c:/Users/Elite-Store/spine_clinic_app/lib/features/appointment/presentation/widgets/booking_form_fields.dart) (261 lines) - Form fields wrapper.
- [new_appointment_form.dart](file:///c:/Users/Elite-Store/spine_clinic_app/lib/features/appointment/presentation/widgets/new_appointment_form.dart) (220 lines) - Booking builder.
- [doctor_register_screen.dart](file:///c:/Users/Elite-Store/spine_clinic_app/lib/features/auth/presentation/doctor_register_screen.dart) (207 lines) - Doctor self-registration screen.
- [medical_records_providers.dart](file:///c:/Users/Elite-Store/spine_clinic_app/lib/features/medical_records/presentation/medical_records_providers.dart) (235 lines) - Providers configuration.
- [edit_patient_form.dart](file:///c:/Users/Elite-Store/spine_clinic_app/lib/features/patient/presentation/widgets/edit_patient_form.dart) (241 lines) - Patient data editor form.
- [record_payment_screen.dart](file:///c:/Users/Elite-Store/spine_clinic_app/lib/features/payments/presentation/record_payment_screen.dart) (239 lines) - Payment entry form.
- [payment_form_fields.dart](file:///c:/Users/Elite-Store/spine_clinic_app/lib/features/payments/presentation/widgets/payment_form_fields.dart) (217 lines) - Payment fields.
- [manage_replacement_controller.dart](file:///c:/Users/Elite-Store/spine_clinic_app/lib/features/replacements/presentation/manage_replacement_controller.dart) (303 lines) - Replacements scheduler controller.
- [affected_appointments_checklist.dart](file:///c:/Users/Elite-Store/spine_clinic_app/lib/features/replacements/presentation/widgets/affected_appointments_checklist.dart) (226 lines) - Bulk swap selector UI.
- [app_doctor_multi_select_field.dart](file:///c:/Users/Elite-Store/spine_clinic_app/lib/features/staff/presentation/widgets/app_doctor_multi_select_field.dart) (211 lines) - Custom multiselect field.

### Rule 8 & 11 Compliance
- **Rule 8**: Verified. No hardcoded hex colors or direct material colors found in `lib/features`. Paddings and sizes are correctly bound to `AppSizes` tokens.
- **Rule 11**: Verified. [file_opener_helper_mobile.dart](file:///c:/Users/Elite-Store/spine_clinic_app/lib/core/utils/file_opener_helper_mobile.dart) and [file_cache_manager.dart](file:///c:/Users/Elite-Store/spine_clinic_app/lib/core/utils/file_cache_manager.dart) download files to local secure document cache directories and handle native storage and file-opening permissions gracefully.

### Leftover / Unused Codebase Files
- [AppointmentReadOnlyNotesCard](file:///c:/Users/Elite-Store/spine_clinic_app/lib/features/appointment/presentation/widgets/appointment_read_only_notes_card.dart) - Unused widget. Editable appointment notes are handled by `AppointmentNotesCard` on `AppointmentDetailScreen`.
- `branch_providers.dart` (under `lib/features/admin/presentation/`) - Correctly integrated with active branch configuration, not a leftover.

---

## 16. Standard Prompt Template

Use this template for every task given to the agent.
Replace bracketed sections with the specific task details.

========================================================================
read agennt_context.md
========================================================================

# ROLE & CONTEXT
You are an expert Flutter & Riverpod Engineer specialized in Clean Architecture. You are working on the "Spine Clinic" platform. 

# PROJECT GUIDANCE
- Use the exact schemas, database rules, and structural constraints documented in @AGENT_CONTEXT.md and @SCREENS.md.
- Ensure all business logic remains in Repositories; Widgets are for UI and State Consumption only.

# CURRENT TASK: [Phase Name & Screen Name]


**Requirements:**
1. [Functional Requirement 1]
2. [Functional Requirement 2]
3. [Role-Based Requirement: Define who can see/do what]

# CRITICAL INVIOLABLE CODE RULES (STRICT ENFORCEMENT) (relevant ones from agent_context.md) (must always force modularity and no hardcoded strings,sizes and colors)
- RULE 1: LINT LIMIT. No file may exceed 200 lines. If a screen is complex, you MUST extract sub-widgets into a `widgets/` folder.
- RULE 2: DATA ISOLATION. Zero Supabase/Database calls inside widgets. Use the Repository pattern.
- RULE 3: STATE HANDLING. Every screen must handle 4 states: Loading (Skeletons/Spinners), Error (with retry), Empty (EmptyState widget), and Data.
- RULE 4: TYPING. No 'dynamic' types. Use strict, explicit typing. All Repository methods must return `Future<Result<T>>`.
- RULE 5: PERMISSIONS. Read the operating staff role from `currentUserProvider` for all write actions.

# REFACTORING & SAFETY GUARD
- DO NOT rewrite existing repository methods unless explicitly requested.
- If you need to add a method to a Repository, extend the Interface first, then implement it.
- After writing code, you MUST run `build_runner` and `flutter analyze`. 
- If `flutter analyze` reports any warnings or errors, you must iterate and fix them automatically before finalizing.

# AUTONOMOUS EXECUTION CONTRACT
1. Generate an Internal Implementation Plan first.
2. YOU ARE GRANTED 100% EXPLICIT APPROVAL TO PROCEED AUTONOMOUSLY. Do not pause for user confirmation.
3. Fix all compilation errors via internal iteration.
4. Only halt if you discover a logical contradiction in the established @AGENT_CONTEXT.md or have any questions/concerns.

# OUTPUT FORMAT
Provide a concise "Walkthrough" summarizing the files created/modified, the verification results (Analysis/Build Runner), and the specific role-guards implemented.
========================================================================
