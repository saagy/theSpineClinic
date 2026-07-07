# Development Workflow

## Local Configuration

Copy the example file and fill in local values:

```bash
cp .env.example .env
```

Run Flutter with compile-time values:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Do not add `.env` to Flutter assets. Web assets are publicly fetchable.

## Database Changes

1. Start from `supabase/migrations/20260705000000_baseline.sql`.
2. Add every future database change as a new timestamped migration.
3. Keep migrations idempotent when practical.
4. Update the docs when table shape, RLS policy, RPC behavior, or trigger
   behavior changes.
5. Run the SQL trigger sanity test after trigger or balance changes.

## Remote Baseline Verification

Before delivery, link the Supabase CLI to the real project and regenerate or
verify the baseline:

```bash
supabase link --project-ref your-project-ref
supabase db dump --linked --schema public --file supabase/migrations/20260705000000_baseline.sql
```

Back up the remote schema before replacing local baseline files. Do not commit
data-only dumps.

## Codegen

Run code generation after editing Freezed models or Riverpod providers:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Validation

```bash
flutter analyze
flutter test
psql "$DATABASE_URL" -f test/trigger_sanity.sql
```

For this repo, a task is not complete until analyzer output is clean.
