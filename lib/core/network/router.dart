/// Centralized GoRouter configuration with role-based redirect guards.
///
/// Listens to [currentUserProvider] state transitions via a
/// [ChangeNotifier] bridge to drive navigation without recursion.
///
/// Route path strings are sourced from [AppRoutes].
/// Splash overlay is sourced from [SplashScreen].
/// Both files are decoupled to respect the 200-line boundary.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/doctor_register_screen.dart';
import 'package:spine_clinic_app/features/auth/presentation/login_screen.dart';
import 'package:spine_clinic_app/features/auth/presentation/splash_screen.dart';
import 'package:spine_clinic_app/features/appointment/presentation/home_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_detail_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_search_screen.dart';
import 'package:spine_clinic_app/shared/widgets/app_shell.dart';

part 'router.g.dart';

// ─────────────────── Listenable Bridge ───────────────────

/// One-way valve: [currentUserProvider] state → [GoRouter] refresh.
///
/// Fires [notifyListeners] whenever the provider emits a new
/// [AsyncValue]. The router's [redirect] reads the latest value
/// without mutating state, breaking the recursion chain.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AsyncValue<Staff?>>(
      currentUserProvider,
      (_, __) => notifyListeners(),
    );
  }
}

// ─────────────────── Router Provider ───────────────────

/// Provides the application's centralized [GoRouter] instance.
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final _RouterRefreshNotifier refreshNotifier = _RouterRefreshNotifier(ref);

  final GoRouter goRouter = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (BuildContext context, GoRouterState state) =>
        _redirect(ref, state),
    routes: _buildRoutes(ref),
  );

  ref.onDispose(() {
    refreshNotifier.dispose();
    goRouter.dispose();
  });

  return goRouter;
}

// ─────────────────── Redirect Engine ───────────────────

/// Pure redirect function — reads state, never mutates it.
String? _redirect(Ref ref, GoRouterState state) {
  final AsyncValue<Staff?> asyncUser = ref.read(currentUserProvider);
  final String location = state.matchedLocation;

  // Loading → park on splash
  if (asyncUser.isLoading) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }

  // Error → send to login
  if (asyncUser.hasError) {
    return _isPublicRoute(location) ? null : AppRoutes.login;
  }

  final Staff? user = asyncUser.value;

  // Unauthenticated → only public routes allowed
  if (user == null) {
    return _isPublicRoute(location) ? null : AppRoutes.login;
  }

  // Safety net: inactive staff (notifier should have auto-logged out)
  if (!user.isActive) {
    return _isPublicRoute(location) ? null : AppRoutes.login;
  }

  // Authenticated + active → block public routes, send to role home
  if (_isPublicRoute(location)) {
    return _homeRouteForRole(user.role);
  }

  return null; // already on a valid authenticated route
}

/// Returns `true` for routes accessible without authentication.
bool _isPublicRoute(String location) =>
    location == AppRoutes.login ||
    location == AppRoutes.register ||
    location == AppRoutes.splash;

/// Maps a [UserRole] to its designated landing route path.
String _homeRouteForRole(UserRole role) => switch (role) {
      UserRole.doctor => AppRoutes.schedule,
      UserRole.receptionist => AppRoutes.home,
      UserRole.superAdmin => AppRoutes.home,
    };

// ─────────────────── Route Tree ───────────────────

List<RouteBase> _buildRoutes(Ref ref) {
  return [
    GoRoute(
      path: AppRoutes.splash,
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (_, __) => const DoctorRegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.search,
      builder: (_, __) => const PatientSearchScreen(),
    ),
    GoRoute(
      path: AppRoutes.patientDetail,
      builder: (_, GoRouterState state) {
        final String patientId = state.pathParameters['id'] ?? '';
        return PatientDetailScreen(patientId: patientId);
      },
    ),
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        final Staff? user =
            ref.read(currentUserProvider).value;
        final String role = user?.role.dbValue ?? 'receptionist';

        return AppShell(
          title: AppStrings.appName,
          userRole: role,
          currentTabIndex: 0, // wired in a future navigation phase
          onTabSelected: (_) {}, // wired in a future navigation phase
          actions: state.matchedLocation == AppRoutes.home
              ? [
                  IconButton(
                    icon: const Icon(Icons.search_rounded),
                    onPressed: () => context.push(AppRoutes.search),
                  ),
                ]
              : null,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (_, __) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.schedule,
          builder: (_, __) => const _ScheduleStub(),
        ),
      ],
    ),
  ];
}

// ─────────────────── Temporary Stub Screens ───────────────────
// Lightweight placeholders for screens not yet built.

class _ScheduleStub extends StatelessWidget {
  const _ScheduleStub();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text(AppStrings.appointments));
}
