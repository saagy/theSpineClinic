1. The 12 Inviolable Code Rules

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
12. DEBOUNCED FILTERS. Any interactive text search or filter query hitting a Repository or Supabase must use a minimum 300ms debounce pattern. Never trigger database hits on every single keystroke.

## 2. Data Flow Contract

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

## 3. Folder Structure

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

## Development Rules
- ALWAYS run `flutter analyze` immediately after rewriting logic or files.
- If an automated edit breaks compiling, stop and fix the core structural files first.
- Keep components modular. Do not merge visual presentation with database models.
## Build & Test Commands
- Check compilation/errors: `flutter analyze`
- Run local tests: `flutter test`
- Get dependencies: `flutter pub get`

## Full Data Schema At AGENT_CONTEXT.md
