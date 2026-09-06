import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/network/auth_redirect.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';

void main() {
  final Staff receptionist = Staff(
    id: 'qa',
    fullName: 'QA',
    email: 'qa@example.com',
    role: UserRole.receptionist,
    createdAt: DateTime.utc(2026),
  );
  final AsyncValue<Staff?> signedIn = AsyncData(receptionist);

  test('restores patient deep link after session loading, including query', () {
    final Uri patient = Uri.parse('/patient/qa?tab=notes');
    final String splash = authRedirect(const AsyncLoading(), patient)!;
    expect(Uri.parse(splash).path, AppRoutes.splash);
    expect(authRedirect(signedIn, Uri.parse(splash)), patient.toString());
  });

  test('restored links still enforce roles and authentication', () {
    final Uri splash = Uri(
      path: AppRoutes.splash,
      queryParameters: {'from': '/admin'},
    );
    expect(authRedirect(signedIn, splash), AppRoutes.allAppointments);
    expect(authRedirect(const AsyncData(null), splash), AppRoutes.login);
    expect(
      authRedirect(AsyncData(receptionist.copyWith(isActive: false)), splash),
      AppRoutes.login,
    );
  });

  test('splash cannot redirect to an external host or itself', () {
    for (final String destination in [
      'https://example.com',
      '//example.com',
      '/splash',
      '/login',
      '',
    ]) {
      final Uri splash = Uri(
        path: AppRoutes.splash,
        queryParameters: {'from': destination},
      );
      expect(authRedirect(signedIn, splash), AppRoutes.allAppointments);
    }
  });
}
