part of 'router.dart';

String? _redirect(Ref ref, GoRouterState state) {
  final AsyncValue<Staff?> asyncUser = ref.read(currentUserProvider);
  final String location = state.matchedLocation;

  if (asyncUser.isLoading) {
    if (location == AppRoutes.login || location == AppRoutes.register) {
      return null;
    }
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }

  if (asyncUser.hasError) {
    if (location == AppRoutes.login || location == AppRoutes.register) {
      return null;
    }
    return AppRoutes.login;
  }

  final Staff? user = asyncUser.value;
  if (user == null || !user.isActive) {
    return (location == AppRoutes.login || location == AppRoutes.register)
        ? null
        : AppRoutes.login;
  }

  if (_isPublicRoute(location)) return _homeRouteForRole(user.role);

  if (_isAdminRoute(location) && user.role != UserRole.superAdmin) {
    return _homeRouteForRole(user.role);
  }

  if (_isDoctorRoute(location) && user.role != UserRole.doctor) {
    return _homeRouteForRole(user.role);
  }

  return null;
}

bool _isPublicRoute(String location) =>
    location == AppRoutes.login ||
    location == AppRoutes.register ||
    location == AppRoutes.splash;

bool _isAdminRoute(String location) => location.startsWith('/admin');

bool _isDoctorRoute(String location) =>
    location == AppRoutes.schedule ||
    location == AppRoutes.myPatients ||
    location == AppRoutes.doctorProfile ||
    location == AppRoutes.doctorHistory;

String _homeRouteForRole(UserRole role) => switch (role) {
  UserRole.doctor => AppRoutes.schedule,
  UserRole.receptionist => AppRoutes.allAppointments,
  UserRole.superAdmin => AppRoutes.allAppointments,
};

/// Redirects an active session immediately if the account is deactivated.
class _SessionGuard extends ConsumerWidget {
  const _SessionGuard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<Staff?>>(currentUserProvider, (previous, next) {
      final Staff? prevUser = previous?.value;
      final Staff? nextUser = next.value;
      if (prevUser != null &&
          prevUser.isActive &&
          nextUser != null &&
          !nextUser.isActive) {
        context.go(AppRoutes.login);
      }
    });
    return child;
  }
}
