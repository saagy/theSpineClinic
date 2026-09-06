import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_routes.dart';
import '../../features/auth/domain/staff.dart';
import '../../features/auth/domain/user_role.dart';

/// Resolves authentication without losing a protected browser deep link.
String? authRedirect(AsyncValue<Staff?> asyncUser, Uri uri) {
  final String location = uri.path;

  if (asyncUser.isLoading) {
    if (location == AppRoutes.login || location == AppRoutes.register) {
      return null;
    }
    return location == AppRoutes.splash
        ? null
        : Uri(
            path: AppRoutes.splash,
            queryParameters: {'from': uri.toString()},
          ).toString();
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

  if (_isPublicRoute(location)) {
    final Uri? destination = Uri.tryParse(uri.queryParameters['from'] ?? '');
    if (location == AppRoutes.splash &&
        destination != null &&
        !destination.hasScheme &&
        !destination.hasAuthority &&
        destination.path.startsWith('/') &&
        !destination.path.startsWith('//') &&
        !_isPublicRoute(destination.path)) {
      // Run the same role guards before restoring the requested location.
      return authRedirect(asyncUser, destination) ?? destination.toString();
    }
    return _homeRouteForRole(user.role);
  }

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
