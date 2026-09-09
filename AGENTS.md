## Inviolable Code & UI Rules
1. **Strict File Length Limit:** No file longer than 200 lines. Split components or files immediately if they grow past this threshold. (Slightly flexible, if a file is slightly over then it's ok)
2. **Encapsulated Data Access:** No Supabase or database engine calls directly inside widgets. All data access must reside exclusively inside repository classes.
3. **Unified State Management:** Manage all application state via Riverpod. `setState` is acceptable for widget-local state only: form submission flags (`_isSubmitting`), input toggles (password visibility), date/filter selections within a single sheet or form, and expand/collapse animations. All shared, cross-screen, or repository-backed state must go through Riverpod providers.
4. **Type-Safe Async Architecture:** Every asynchronous repository function must return a `Result<T>` wrapper rather than a raw `Future<T>`.
5. **Strict Static Typing:** No `dynamic` as a variable or return type where a concrete type is known. `Map<String, dynamic>` for JSON deserialization (`fromJson`/`toJson`, Supabase query rows) is expected and acceptable — this is the standard Dart serialization pattern. Never use `var` where the type is ambiguous.
6. **Role-Based Security Verification:** Every user action that writes or modifies data must explicitly verify roles and permissions via the `currentUserProvider`.
7. **Zero Hardcoded Strings:** All localized text, labels, and system messages must be sourced via the `AppStrings` constants class.
8. **Semantic Size Mapping:** No hardcoded layout sizing parameters. Dimensions must map completely to layout configurations inside the `AppSizes` token file.
9. **Mandatory UI States:** Every functional screen layout must explicitly handle and display four foundational structural states: `loading`, `error`, `empty`, and `data`.
10. **Zero-Tolerance Analysis:** Run `flutter analyze` and confirm zero warnings or errors before marking any individual task as complete.
11. **Desktop and Mobile:** Both PCs and phones are primary usage contexts. Adapt structure to available window space, not device labels. Support touch, keyboard, focus, and pointer feedback; essential actions must never depend on hover. Maintain touch targets of at least 44 logical pixels through semantic `AppSizes` tokens.
12. **Debounced Network Queries:** Any interactive text search input or real-time filter execution hitting a Repository or Supabase must utilize a minimum 300ms debounce pattern via Riverpod or an explicit debouncer mechanism. Never trigger database operations on individual keystrokes.
13. **Task-Appropriate Containers:** Choose rows, tables, cards, or panels according to information hierarchy and scanning needs. Theme-driven separators are allowed. Cards, shadows, rounded corners, and 16-pixel padding are not mandatory on every row. Keep touch targets comfortable; define component density, spacing, and shape in tokens.
14. **Task-Appropriate Controls:** Keep frequent search and filter actions visible and group related controls. On narrow windows, avoid long stacks of secondary controls; use progressive disclosure when useful. On wide windows, use aligned toolbars or panels where appropriate. Chips and bottom sheets are options, not universal requirements. Keep active filters visible and easy to clear.
15. **Context-Driven Theme Tokens:** Raw palette values belong exclusively in theme construction under `core/constants/`. Widgets use `Theme.of(context).colorScheme`, registered theme extensions, or component theme defaults. Never reference `AppColors` or raw palette constants directly inside widgets; preserve light/dark mode compliance.
16. **Design System Compliance:** Zero usage of raw color values or hardcoded
    hex codes in any widget. All colors must come from the active theme via
    Theme.of(context). All spacing must reference AppSizes tokens. All text
    styles must reference AppTextStyles.
    *Status note: the legacy `AppColors` migration is complete — widget files
    reference the theme exclusively. Keep it that way; never re-introduce
    `AppColors` references inside widgets.*
17. **Purposeful Component Reuse:** Inspect shared/widgets/ before building visual elements. Reuse components that fit the redesigned workflow; replace unsuitable legacy components instead of retaining them for consistency alone. Build reusable visual patterns in shared/widgets/ and keep feature composition in its presentation layer. Avoid one-off inline styling and speculative abstractions.
18. **Audit Before Restyle:** Treat each screen as a blank canvas. Explicitly list every UX problem found before writing implementation code. Preserve legacy widgets or layouts only when they make UX sense.

19. **No Legacy Preservation:** Remove components without a clear UX purpose and redesign that section from scratch instead of restyling them.

20. **Initials Avatar Fallback:** When initials avatars are used, handle names starting with numbers, single-character names, and empty names. Show Icons.person when valid letter initials cannot be derived.

21. **Primary Action Placement:** Make the main permitted action clear and accessible. Choose a labeled toolbar button, inline action, or FAB according to the layout; FABs are not required. Use consistent component shape tokens and prevent floating actions from obscuring content.

22. **Prioritize Information:** Keep identification and task-critical information readable. Adapt columns, wrapping, or secondary detail placement when space is limited. Move nonessential metadata to details; do not silently remove essential information or shrink names to make a legacy layout fit.
23. **Explicit Height and Scrolling Containment:** Never wrap infinite or dynamic-length lists (`ListView.builder`) inside an unconstrained vertical container or an unbounded `Column`. Use `Expanded`, `SliverList`, or `Flexible` as appropriate. Preserve platform-appropriate scrolling; `AlwaysScrollableScrollPhysics` permits scrolling with short content and does not itself prescribe bounce behavior. Ensure pull-to-refresh works with short or empty content where offered.
24. **Semantic Spacing:** All spacing uses `AppSizes` tokens. Select token levels to distinguish related items from separate groups; equal gaps everywhere are not required. Add a meaningful reusable token when needed instead of inserting magic numbers to force a layout into place.

25. **Defensive State Construction — copyWith Only:** Never construct a state object directly for a mutation (e.g. `state = MyState(loading: true)`). Always mutate via `state.copyWith(loading: true)` to retain unspecified fields. Constructor defaults are only valid for the initial state inside `build()`. Every state class must define `copyWith`; every Notifier state mutation must use it. Direct construction can silently reset fields such as `todayLoading`, a recurring regression in this app.

26. **Async Provider Resilience:** When a `Notifier.build()` depends on data
    from an async provider (e.g. `currentUserProvider`), you MUST `ref.watch`
    that provider inside `build()` so the notifier re-evaluates when the
    dependency resolves. Never call `ref.read(someAsyncProvider).value` from
    inside `build()` or a method called by `build()` — if the async provider
    hasn't resolved yet, `.value` returns `null`, your load function exits
    silently, and the screen spins forever with no retry. Use the pattern:
    ```
    @override
    MyState build() {
      final user = ref.watch(currentUserProvider).value;
      if (user != null && !_started) {
        _started = true;
        Future.microtask(() => _load(user));
      }
      return MyState(doctor: user);
    }
    ```

27. **Atomic Multi-Step Mutations:** Any repository operation that touches more
    than one table, modifies multiple rows conditionally, or performs a
    read-modify-write on a record, MUST be executed inside a single PostgreSQL
    RPC function (`SECURITY DEFINER` transaction) — never as sequential client-side
    PostgREST HTTP calls. When an operation spans the database and an external
    store (e.g., Supabase Storage), follow the strict safety contract:
    - For deletions/updates: Database is the source of truth and executes first;
      storage deletion executes second with best-effort error suppression.
    - For uploads/creations: If storage upload succeeds but the subsequent
      database record insert fails, the catch block MUST execute a compensating
      deletion of the uploaded storage object to prevent orphaned artifacts.
    - Never perform client-side read-modify-write (e.g. fetch balance -> add delta
      -> update balance); use atomic database RPCs or atomic SQL increment
      expressions.

28. **Mutation Controller Lifecycle (`keepAlive: true`):** Any action or mutation
    controller (`class XController extends _$XController`) that is invoked via
    `ref.read(xControllerProvider.notifier).someAction(...)` from a button, form,
    or modal bottom sheet MUST be declared with `@Riverpod(keepAlive: true)`.
    Without `keepAlive: true`, an unobserved auto-dispose controller will be
    garbage-collected by Riverpod while the async network request is in-flight,
    causing `ref.mounted` to evaluate to `false` upon completion and silently
    skipping state updates/invalidations.

## Known Gotchas

### Empty Patient Deletion
All permitted roles may delete only completely empty patients. Keep client
preflight and `delete_empty_patient` RPC wired; the database delete trigger
rejects related appointments, payments, programs, notes, documents, medical
history and nonzero session/traction balances. Do not restore a privileged-role
bypass or replace the RPC with a direct client delete.

### Status Callback Wiring
Every screen that uses `ReceptionistAppointmentCard` with `showMenu: true`
(the default) MUST pass an `onStatusChanged` callback that refreshes that
screen's data source. The callback chain must be unbroken: Screen → tab
widget → day list → every card. A missing callback means status changes
disappear until the user manually pulls to refresh. Card action cache refreshes
also invalidate `patientDetailProvider(patientId)` so package balances update.
```dart
// Screen
onStatusChanged: () => ref.read(myProvider.notifier).refresh()
// Widget accepts VoidCallback? onStatusChanged and forwards to card
```

### PostgreSQL Base Table Grants vs RLS
In PostgreSQL/Supabase, Row Level Security (`CREATE POLICY`) only takes effect
*after* table-level privileges are granted to the executing role. Creating a new
table and defining RLS policies without issuing `GRANT ... TO authenticated;`
will cause PostgreSQL to reject all queries with error `42501: permission denied
for table <table_name>` before RLS policies are even evaluated. Every new table
created in migrations MUST include explicit grants:
```sql
GRANT SELECT, INSERT, UPDATE, DELETE ON public.<table_name> TO authenticated;
```

## Data Flow Contract

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

## Folder Structure
Every file must live inside this exact structure. Never create folders
outside it. Never place business logic in presentation. Never place
Supabase calls in widgets.

Every feature folder follows the same `data/domain/presentation` layering:
`data/` for repository implementations and DTOs, `domain/` for Freezed models
and repository interfaces, `presentation/` for screens, providers, and notifiers.

```
lib/
├── core/
│   ├── constants/       # AppColors, AppSizes, AppStrings, AppTextStyles
│   ├── errors/          # AppException, Failure types, Result<T>
│   ├── network/         # Supabase client singleton, SupabaseService,
│   │                    # app router & routes
│   └── utils/           # formatDate, formatCurrency, formatPhone
├── shared/
│   └── widgets/         # AppButton, AppTextField, AppSearchBar,
│                        # LoadingOverlay, ErrorView, EmptyState,
│                        # ConfirmationDialog, AppBadge, AppChip,
│                        # SectionCard, DataListTile, InfoRow,
│                        # AppBottomSheet, AppBottomNav, AppShell
└── features/
    ├── auth/            # data/ domain/ presentation/
    ├── patient/         # data/ domain/ presentation/
    ├── appointment/     # data/ domain/ presentation/
    ├── medical_records/ # data/ domain/ presentation/
    ├── payments/        # data/ domain/ presentation/
    ├── staff/           # data/ domain/ presentation/
    └── admin/           # data/ domain/ presentation/
# replacements/ — on hold, may return in future
```

## Development Rules
- ALWAYS run `flutter analyze` immediately after rewriting logic or files.
- If an automated edit breaks compiling, stop and fix the core structural files first.
- Keep components modular. Do not merge visual presentation with database models.
- Providers are created via `@riverpod` annotations and `riverpod_generator`.
  Never hand-write Provider classes — use the annotation pattern and run
  `build_runner` to generate `.g.dart` files.
- **Docs stay in sync:** when a task changes anything documented in AGENTS.md or
  `docs/`, update the doc in the same task — never "later". If docs and code
  disagree, code is the source of truth: fix the doc, then mention the fix in
  your summary. Never "fix" working code to match a stale doc.

## Build & Test Commands
- Check compilation/errors: `flutter analyze`
- Run local tests: `flutter test`
- Get dependencies: `flutter pub get`
- Regenerate code (after editing Freezed models or Riverpod providers):
  `dart run build_runner build --delete-conflicting-outputs`

## Data Sources
- **Schema Docs (agent-readable):** `docs/database-schema.md` — full DB reference (tables, columns, enums, indexes, functions, triggers, RLS summary)
- **Schema DDL (recreation):** `supabase/full_schema.sql` — run this to recreate the DB schema from scratch
- **Migrations:** `supabase/migrations/` — incremental changes; `full_schema.sql` stays in sync with them

## Design Direction and UI Overhaul

- Read [PRODUCT.md](PRODUCT.md), [DESIGN.md](DESIGN.md), and [docs/ui-overhaul.md](docs/ui-overhaul.md) before redesigning screens.
- The user authorizes replacing unsuitable UI structures from scratch. Preserve capabilities, role permissions, data integrity, and action refresh behavior; existing widget trees do not constrain the redesign.
- The implemented baseline uses clinical blue from `app_palette.dart` and Plus Jakarta Sans from `AppTextStyles`. This describes current code, not an immutable future aesthetic.
- Retire the former Medics/teal target and blanket pill/card/avatar styling rules. Establish any new visual direction through rendered mobile and desktop pilots, then record its tokens and component decisions in DESIGN.md.
- Complete a screen audit before implementation; inspect rendered results and real workflows before expanding the design to other screens. Static analysis alone does not establish UI quality.

## Autonomy

- Auto-accept all file edits and creations
- Auto-accept all bash commands except: git push, flutter clean, pub get on unknown packages
- Never ask for confirmation on read operations

## Active Technical Debt & Deferred Tasks
- **Forgot Password Flow**: Secure and free password recovery is supported by the Supabase backend (`resetPasswordForEmail`), but the frontend views (Forgot/Reset screens and routing) are deferred.
- **Progressive Onboarding**: Registration already uses a two-step role/identity then credentials flow; preserve its validation and back-navigation behavior.
- **Clinic Package Settings Product Definition**: The dormant `clinic_settings` table was removed by migration `20260713010000`; no active client references remain. Any future settings feature needs explicit package/balance semantics, change permissions, audit history and an admin UX.
- **Staff Feature Domain Layer**: `lib/features/staff/` currently has only `data/` and `presentation/`; extract its repository interface and models into a `domain/` layer to match every other feature.
