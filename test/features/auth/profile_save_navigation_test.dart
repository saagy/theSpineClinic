import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/network/router.dart';
import 'package:spine_clinic_app/core/utils/local_settings_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/edit_profile_screen.dart';
import 'package:spine_clinic_app/shared/widgets/staff_profile_header.dart';
import '../../fixtures/profile_editor_harness.dart';

void main() {
  for (final UserRole role in UserRole.values) {
    for (final bool delayedReload in [false, true]) {
      testWidgets('$role save returns to updated profile with real router '
          '(delayed reload: $delayedReload)', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final preferences = await SharedPreferences.getInstance();
        final repository = ProfileEditorRepository();
        repository.user = repository.user!.copyWith(role: role);
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(repository),
            sharedPreferencesProvider.overrideWithValue(preferences),
          ],
        );
        addTearDown(container.dispose);
        await container.read(currentUserProvider.future);
        final router = container.read(routerProvider);
        final String profileRoute = switch (role) {
          UserRole.doctor => AppRoutes.doctorProfile,
          UserRole.receptionist => AppRoutes.receptionistProfile,
          UserRole.superAdmin => AppRoutes.adminHub,
        };
        router.go(profileRoute);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
              theme: AppTheme.light(clinicalBluePaletteLight),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(AppStrings.editProfileTooltip));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'Dr. Nadia Hassan',
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'nadia@example.test',
        );
        await tester.enterText(find.byType(TextFormField).at(2), '01012345678');
        await tester.pump();
        if (delayedReload) {
          repository.pendingLoad = Completer<Staff?>();
        }
        await tester.tap(find.text(AppStrings.saveChanges));
        await tester.pumpAndSettle();
        expect(repository.profileWrites, 1);
        expect(router.routeInformationProvider.value.uri.path, profileRoute);
        expect(find.byType(EditProfileScreen), findsNothing);
        if (delayedReload) {
          repository.pendingLoad!.complete(repository.user);
          await tester.pumpAndSettle();
        }
        final Staff displayed = tester
            .widget<StaffProfileHeader>(find.byType(StaffProfileHeader))
            .user;
        expect(displayed.fullName, 'Dr. Nadia Hassan');
        expect(displayed.email, 'nadia@example.test');
        expect(displayed.phone, '01012345678');
        await tester.tap(find.byTooltip(AppStrings.editProfileTooltip));
        await tester.pumpAndSettle();
        expect(find.text('Dr. Nadia Hassan'), findsOneWidget);
        expect(find.text('nadia@example.test'), findsOneWidget);
        expect(find.text('01012345678'), findsOneWidget);
      });
    }
  }
}
