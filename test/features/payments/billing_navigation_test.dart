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
import 'package:spine_clinic_app/features/payments/presentation/billing_screen.dart';
import 'package:spine_clinic_app/features/payments/presentation/service_catalog_providers.dart';
import 'package:spine_clinic_app/features/payments/presentation/service_catalog_screen.dart';
import 'package:spine_clinic_app/shared/widgets/app_nav_bar.dart';
import 'package:spine_clinic_app/shared/widgets/app_nav_rail.dart';
import 'package:spine_clinic_app/features/payments/presentation/billing_report_providers.dart';
import '../../fixtures/billing_report_fixture.dart';
import '../../fixtures/profile_editor_harness.dart';
import '../../fixtures/service_catalog_fixture.dart';

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets('payment staff reach Billing and its services at $width', (tester) async {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final auth = ProfileEditorRepository();
      auth.user = auth.user!.copyWith(role: UserRole.receptionist, canManagePayments: true);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          sharedPreferencesProvider.overrideWithValue(preferences),
          invoiceRepositoryProvider.overrideWithValue(FakeInvoiceRepository()),
          billingReportRepositoryProvider.overrideWithValue(FakeBillingReportRepository()),
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
      Finder tab(String label) => find.descendant(of: nav, matching: find.text(label));
      await tester.tap(tab(AppStrings.invoices.billing));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.billing);
      expect(find.byType(BillingScreen), findsOneWidget);
      expect(nav, findsOneWidget);

      await tester.tap(find.text(AppStrings.invoices.services));
      await tester.pumpAndSettle();
      expect(find.byType(ServiceCatalogScreen), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();

      await tester.tap(tab(AppStrings.profile));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.receptionistProfile);
      expect(tester.takeException(), isNull);
    });
  }
}
