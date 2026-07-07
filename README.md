# Spine Clinic

A production-style clinic management app built with Flutter, Riverpod, and
Supabase. The app supports role-based workflows for receptionists, doctors, and
admins across patient registration, appointments, clinical notes, documents,
payments, packages, and staff management.

This repository is intentionally structured like a handoff-ready product, not a
Flutter starter project: feature modules are layered, Supabase access is kept
behind repositories, and the database baseline includes RLS policies, triggers,
RPCs, and storage policy setup.

## Highlights

- Role-aware dashboards for doctors, receptionists, and super admins.
- Patient profiles with assigned doctors, appointments, notes, documents, and
  payment history.
- Appointment scheduling with package-balance deduction and refund triggers.
- Recurring appointment booking through a transactional Supabase RPC.
- Payment tracking with package credit sync and due-balance support.
- Staff activation, doctor assignment, and replacement coverage workflows.
- Firebase Hosting deploy path for Flutter web.

## Tech Stack

- Flutter and Dart
- Riverpod with generated providers
- Supabase Auth, Postgres, Storage, RLS, triggers, and RPC functions
- GoRouter
- Freezed and JSON serialization
- Firebase Hosting for web delivery

## Architecture

The app follows a feature-first layered structure:

```text
lib/
  core/       shared constants, routing, networking, utilities
  shared/     reusable UI components
  features/   auth, patient, appointment, payments, staff, admin
```

Each feature keeps repository-backed data access out of widgets:

```text
Widget -> Riverpod provider/notifier -> repository interface
       -> repository implementation -> SupabaseService -> Supabase
```

## Screenshots

Add real app captures before sharing the repository publicly. Recommended set:

1. Login screen
2. Receptionist dashboard or appointment list
3. Patient detail profile
4. Payment collection flow
5. Admin staff or clinic settings view

Store final images under `docs/screenshots/` and reference them here once the
screens are captured from a clean demo account.

## Setup

1. Install Flutter and the Supabase CLI.
2. Copy `.env.example` to `.env` for local deploy scripts.
3. Fill in the Supabase URL and anon key.
4. Install dependencies:

```bash
flutter pub get
```

5. Run the app with compile-time configuration:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

For Flutter web, do not bundle `.env` as an asset. Public web builds expose
asset files to users, so runtime configuration must be passed through
`--dart-define`.

## Database

The active pre-delivery database baseline is:

```text
supabase/migrations/20260705000000_baseline.sql
```

It includes the public schema, RLS policies, trigger functions, app RPCs, and
the `patient-documents` storage bucket policy setup. The old migration chain was
squashed because the app has not shipped yet and replayability from a clean
baseline matters more than preserving noisy development history.

Read more:

- [Database Overview](docs/database-overview.md)
- [Schema Reference](docs/schema-reference.md)
- [Security Model](docs/security-model.md)
- [Development Workflow](docs/development-workflow.md)

## Quality Checks

```bash
flutter analyze
flutter test
psql "$DATABASE_URL" -f test/trigger_sanity.sql
```

`test/trigger_sanity.sql` is a rollback-safe SQL test script for the package
balance triggers.

## Deployment

The Firebase Hosting path is:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\deploy.ps1
```

The deploy script reads `.env`, passes Supabase values through `--dart-define`,
builds Flutter web, injects a build id for service-worker refreshes, and deploys
`build/web` to Firebase Hosting.

## Public Repository Notes

- Never commit `.env`, database dumps, service-role keys, or patient data.
- Keep future DB changes as migrations after the baseline.
- Keep screenshots demo-only and free of real patient information.
