import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/network/router.dart';
import 'package:spine_clinic_app/core/utils/local_settings_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/payments/domain/billing_access.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_providers.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_register_screen.dart';
import 'package:spine_clinic_app/shared/widgets/app_nav_bar.dart';
import 'package:spine_clinic_app/shared/widgets/app_nav_rail.dart';
import '../../fixtures/billing_pilot.dart';
import '../../fixtures/profile_editor_harness.dart';

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'cashier can switch from Profile to Billing at $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final preferences = await SharedPreferences.getInstance();
        final auth = ProfileEditorRepository();
        auth.user = auth.user!.copyWith(
          role: UserRole.receptionist,
          canManagePayments: true,
        );
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
            sharedPreferencesProvider.overrideWithValue(preferences),
            billingRepositoryProvider.overrideWithValue(BillingFixture()),
          ],
        );
        addTearDown(container.dispose);
        await container.read(currentUserProvider.future);
        final router = container.read(routerProvider);
        router.go(AppRoutes.receptionistProfile);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        final nav = find.byType(width < 600 ? AppNavBar : AppNavRail);
        Finder tab(String label) =>
            find.descendant(of: nav, matching: find.text(label));
        await tester.tap(tab(AppStrings.billing.title));
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          AppRoutes.billing,
        );
        expect(find.byType(BillingRegisterScreen), findsOneWidget);
        expect(nav, findsOneWidget);

        await tester.tap(tab(AppStrings.profile));
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          AppRoutes.receptionistProfile,
        );
        expect(tester.takeException(), isNull);
      },
      skip: !BillingAccess.enabled,
    );
  }
}
