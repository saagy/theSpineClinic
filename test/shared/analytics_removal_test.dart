import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/network/router.dart';
import 'package:spine_clinic_app/core/utils/theme_mode_controller.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_nav_rail.dart';
import '../fixtures/staff_workspace.dart';

class _Theme extends ThemeModeController {
  @override
  ThemeMode build() => ThemeMode.light;
}

void main() {
  testWidgets('saved analytics URL redirects to Admin with the correct nav index', (tester) async {
    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(StaffWorkspaceUser.new),
        themeModeControllerProvider.overrideWith(_Theme.new),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currentUserProvider.future);
    final router = container.read(routerProvider);
    router.go(AppRoutes.reports);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.adminHub);
    expect(tester.widget<AppNavRail>(find.byType(AppNavRail)).currentIndex, 2);
    expect(find.text(AppStrings.navAnalytics), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
