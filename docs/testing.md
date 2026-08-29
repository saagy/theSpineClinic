# Testing

The suite has two layers: **Dart tests** (unit + widget, run by `flutter test`)
and **SQL sanity scripts** (transactional, rollback-safe, run against a
disposable Postgres/Supabase database with `psql`).

## Commands

```bash
flutter test                                   # whole suite
flutter test test/features/appointment          # one feature area
flutter test test/widgets/rename_document_dialog_test.dart   # one file

# SQL sanity scripts (after trigger / balance / permission changes)
psql "$DATABASE_URL" -f test/trigger_sanity.sql
psql "$DATABASE_URL" -f test/doctor_role_integrity.sql
psql "$DATABASE_URL" -f test/patient_document_permissions.sql
```

Each SQL script runs inside a transaction and rolls back, so it is safe against
a disposable copy of the schema — never point them at production data.

## Dart Test Layout (29 files)

```text
test/
├── features/               # Feature-scoped unit & widget tests
│   ├── admin/              # Attendance analytics calculations
│   ├── appointment/        # Largest area (10 files): status transitions,
│   │                       # booking workboard, doctor replacement, schedule
│   │                       # density/autoscroll, week navigator, access rules
│   ├── auth/               # Auth screen flow, staff model
│   ├── medical_records/    # Visit-notes form
│   ├── patient/            # Doctor patient-access scoping
│   └── payments/           # Payment recording logic + UI components
├── shared/                 # NavTabs role-based tab sets
├── widgets/                # Shared widgets: context menus, doctor search sheet,
│                           # sheet text fields, document viewer navigation,
│                           # patient tab documents, rename dialog, skeletons
├── appointment_type_redesign_test.dart   # Appointment-type domain rules
├── per_type_future_commitments_test.dart # Future-commitment rules per type
├── trigger_sanity_test.dart              # Dart-side mirror of the SQL sanity checks
└── widget_test.dart                      # Placeholder smoke test
```

Naming convention mirrors the file under test, placed in the matching
`test/features/<feature>/` or `test/widgets/` folder.

## What Is Covered Where

| Concern | Dart tests | SQL scripts |
| --- | --- | --- |
| Package balance deduct/refund, payment sync | `trigger_sanity_test.dart` | `trigger_sanity.sql` |
| Doctor role integrity (assignments, role changes) | `doctor_patient_access_test.dart`, feature tests | `doctor_role_integrity.sql` |
| Document access & rename permissions | `patient_tab_documents_test.dart`, `rename_document_dialog_test.dart` | `patient_document_permissions.sql` |
| Recurring/due-patient booking rules | `booking_workboard_test.dart`, `per_type_future_commitments_test.dart` | — |

## Conventions

- Widget tests pump real screens/components with ProviderScope overrides — no
  live Supabase connections; repositories are faked at the boundary.
- There are currently no golden tests and no `integration_test/` suite; when
  adding UI regression coverage, prefer behavior assertions over pixels.
- After any schema/trigger change, update the SQL scripts alongside
  [`supabase/full_schema.sql`](../supabase/full_schema.sql) and
  [database-schema.md](database-schema.md).
