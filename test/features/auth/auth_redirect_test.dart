import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/network/auth_redirect.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/payments/domain/billing_access.dart';
import '../../fixtures/profile_editor_harness.dart';

void main() {
  final Staff receptionist = Staff(
    id: 'qa',
    fullName: 'QA',
    email: 'qa@example.com',
    role: UserRole.receptionist,
    createdAt: DateTime.utc(2026),
  );
  final AsyncValue<Staff?> signedIn = AsyncData(receptionist);

  test('billing requires the receptionist payment permission', () {
    final location = Uri.parse(AppRoutes.billing);
    expect(authRedirect(signedIn, location), AppRoutes.allAppointments);
    final cashier = receptionist.copyWith(canManagePayments: true);
    expect(authRedirect(AsyncData(cashier), location), isNull);
  }, skip: !BillingAccess.enabled);

  test(
    'profile refresh retains the current route while the session reloads',
    () async {
      final repo = ProfileEditorRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      await container.read(currentUserProvider.future);
      repo.pendingLoad = Completer<Staff?>();
      container.invalidate(currentUserProvider);
      final AsyncValue<Staff?> refreshing = container.read(currentUserProvider);
      expect(refreshing.isLoading, isTrue);
      expect(refreshing.hasValue, isTrue);
      expect(
        authRedirect(refreshing, Uri.parse(AppRoutes.editProfile)),
        isNull,
      );
      expect(
        authRedirect(refreshing, Uri.parse(AppRoutes.profilePassword)),
        isNull,
      );
      repo.pendingLoad!.complete(repo.user);
      await container.read(currentUserProvider.future);
    },
  );

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
