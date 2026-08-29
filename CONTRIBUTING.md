# Contributing

Thanks for contributing to **The Spine Clinic**. This guide covers setup, the
commands that gate every change, and the conventions the codebase follows.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) with **Dart ≥ 3.10**
- A Supabase project (or the Supabase CLI for schema work)
- For database work: `psql` and the [Supabase CLI](https://supabase.com/docs/guides/cli)

## Setup

```bash
git clone https://github.com/saagy/theSpineClinic.git
cd theSpineClinic
flutter pub get

# Local environment values (Supabase URL + anon key)
cp .env.example .env
```

### Credentials

The app resolves Supabase credentials in this order:

1. Compile-time flags: `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
2. The bundled `.env` asset (convenient local fallback — web builds expose it)
3. Compiled-in defaults

Prefer explicit `--dart-define` flags for anything beyond local development.

### Run

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## Code Generation

Providers (`@riverpod`), Freezed models, and routes are generated. After editing
any of them:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Never hand-write `.g.dart` files or provider classes.

## Validation Gates

A change is complete only when all three pass:

```bash
flutter analyze          # zero warnings, zero errors — no exceptions
flutter test             # unit + widget suite
psql "$DATABASE_URL" -f test/trigger_sanity.sql   # after DB changes
```

Two more SQL sanity scripts live in `test/` for role integrity and document
permissions — see [docs/testing.md](docs/testing.md) for when to run each.

## Conventions

The complete engineering rules are in [AGENTS.md](AGENTS.md). The ones reviewers
will check first:

- **Layering**: widgets never touch Supabase; every async repository call
  returns `Result<T>`; shared state lives in Riverpod providers.
- **Design tokens**: colors come from `Theme.of(context)`, spacing from
  `AppSizes`, text from `AppTextStyles`, user-visible strings from `AppStrings`.
- **File size**: split at ~200 lines; build reusable pieces in `shared/widgets/`.
- **UI states**: every screen handles loading, error, empty, and data.
- **Commits**: conventional style — `feat(ui): …`, `fix(appointment): …`.
- **Database changes**: new timestamped migration + update `supabase/full_schema.sql`
  and `docs/database-schema.md` together. Workflow: [docs/database-overview.md](docs/database-overview.md).

## Web Deployment

`deploy.ps1` (or `deploy.bat`) builds `flutter build web` and publishes to
Firebase Hosting at `spine-clinic-app.web.app`. Requires `firebase login`.

## Where Things Live

- Architecture deep-dive: [docs/architecture.md](docs/architecture.md)
- Database reference: [docs/database-schema.md](docs/database-schema.md)
- Security model: [docs/security-model.md](docs/security-model.md)
