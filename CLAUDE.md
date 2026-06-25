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
11. **Mobile-Touch Focus:** Phone-only design paradigm. No hover states, no `MouseRegion` widgets, and no desktop/web-first interaction patterns. Ensure all touch targets use `InkWell` or `GestureDetector` optimized for immediate touch feedback.
12. **Debounced Network Queries:** Any interactive text search input or real-time filter execution hitting a Repository or Supabase must utilize a minimum 300ms debounce pattern via Riverpod or an explicit debouncer mechanism. Never trigger database operations on individual keystrokes.
13. **Modern Component Spacing:** Zero usage of raw `Divider()` lines between list components. Every list item row must be configured as a distinct Material 3 container/card element styled with uniform `BorderRadius.circular(16)`. Every row or card target must enforce a minimum internal layout padding of `EdgeInsets.all(16)` for physical touch comfort.
14. **Clean Mobile Control Layouts:** Never stack more than two filter inputs or dropdown controls vertically directly on a main screen surface. If a feature demands deeper control variables (e.g., Doctor, Status, Date Ranges), implement a horizontal scrolling row of Material 3 `ChoiceChip` components for primary selectors, alongside a trailing button that opens a structured `showModalBottomSheet`.
15. **Context-Driven Theme Tokens:** Zero usage of absolute color constants from `AppColors` directly within widget styling or visual component declarations. `AppColors` constants are seed values for `ThemeData` construction in `main.dart` only. Widgets must never reference `AppColors` directly — use `Theme.of(context).colorScheme.*` or component theme defaults to ensure instant system theme and light/dark mode compliance.
16. **Design System Compliance:** Zero usage of raw color values or hardcoded
    hex codes in any widget. All colors must come from the active theme via
    Theme.of(context). All spacing must reference AppSizes tokens. All text
    styles must reference AppTextStyles.
    *Legacy note: The codebase currently has 100+ `AppColors` references inside
    widget files. These are legacy violations. When touching a file for any
    reason, migrate its color references to `Theme.of(context)`. Do not
    introduce new `AppColors` references in widgets.*
17. **Component Reuse Mandate:** Before building any new visual element, check
    shared/widgets/ first. If a suitable component exists, use it. If a new
    pattern is needed, build it in shared/widgets/ first, then use it. Never
    build one-off styled containers inline inside screens.
18. **Audit Before Restyle:** When rebuilding any screen, 
    treat it as a blank canvas. Explicitly list every UX 
    problem found before writing a single line of code. 
    Do not preserve legacy widgets or layout structures 
    unless they make UX sense.

19. **No Legacy Preservation:** Never restyle a widget 
    that shouldn't exist. If a component has no clear 
    UX purpose, remove it entirely and redesign that 
    section from scratch.

20. **Initials Avatar Fallback:** The CircleAvatar initials 
    logic must always handle edge cases — names starting 
    with numbers, single character names, empty names. 
    Always show Icons.person as fallback when valid letter 
    initials cannot be derived.

21. **FAB Shape Consistency:** All FABs must be perfect 
    circles. Never use rounded square FABs.

22. **Data That Doesn't Fit Gets Removed:** If a data 
    point breaks the layout or has no clean natural place 
    in a list item, remove it from the list view entirely 
    and show it only in the detail screen.
23. **Explicit Height and Scrolling Containment:** Never wrap infinite or dynamic-length lists (`ListView.builder`) inside an unconstrained vertical container or an unbounded `Column` that risks layout crashes. Always combine with explicit structural primitives (`Expanded`, `SliverList`, or `Flexible`) and ensure list views utilize native iOS/Android bounce physics (`AlwaysScrollableScrollPhysics`).
24. **No Arbitrary Hardcoded Spacing Tweaks:** All spacing adjustments between stacked elements must use uniform `SizedBox(height: AppSizes.spacingMedium)` or corresponding padding tokens from the design tokens file. Never inject inline magic numbers (e.g., `SizedBox(height: 13.5)`) to "force" an element into place.

25. **Defensive State Construction — copyWith Only:** Never construct a state
    object directly for a mutation (e.g. `state = MyState(loading: true)`).
    Always mutate via `state.copyWith(loading: true)` so every field you don't
    explicitly name retains its current value. Constructor defaults are only
    valid for the *initial* state inside `build()`. A direct constructor call
    that omits `todayLoading` will silently reset it to the default — this bug
    has shipped 4 times across 3 screens. The `copyWith` method must be defined
    on every state class. Every `Notifier` that mutates `state` must use it.

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

## Known Gotchas

### Status Callback Wiring
Every screen that uses `ReceptionistAppointmentCard` with `showMenu: true`
(the default) MUST pass an `onStatusChanged` callback that refreshes that
screen's data source. The callback chain must be unbroken: Screen → tab
widget → day list → every card. A missing callback means status changes
disappear until the user manually pulls to refresh.
```dart
// Screen
onStatusChanged: () => ref.read(myProvider.notifier).refresh()
// Widget accepts VoidCallback? onStatusChanged and forwards to card
```

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
```

## 3. Folder Structure
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

## Build & Test Commands
- Check compilation/errors: `flutter analyze`
- Run local tests: `flutter test`
- Get dependencies: `flutter pub get`
- Regenerate code (after editing Freezed models or Riverpod providers):
  `dart run build_runner build --delete-conflicting-outputs`

## Data Sources
- **Schema Docs (agent-readable):** `docs/database-schema.md` — full DB reference (tables, columns, enums, RLS, functions, business rules, model mapping)
- **Schema DDL (recreation):** `supabase/full_schema.sql` — run this to recreate the DB schema from scratch
- **Migrations:** `supabase/migrations/` — incremental changes (not comprehensive)

## Design Reference
Target aesthetic: Medics Medical App UI Kit vibe.
- Primary accent: #2BB5A0 (teal)
- All primary buttons: pill-shaped (BorderRadius.circular(999))
- Cards: white, soft shadow, BorderRadius.circular(16), padding 16
- Avatars: initials circle, teal background, white text
- Typography: large bold dark titles, small muted gray subtitles
- Active filter chips: teal fill + white text
- Inactive filter chips: gray text on white
- Bottom nav: icon + label, teal on active
- See AppTheme for full token definitions

## Autonomy
- Auto-accept all file edits and creations
- Auto-accept all bash commands except: git push, flutter clean, pub get on unknown packages
- Never ask for confirmation on read operations
