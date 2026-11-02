import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_list_screen.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_management_controller.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_applications_controller.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_form_body.dart';
import 'package:spine_clinic_app/shared/widgets/app_shell.dart';
import '../fixtures/staff_workspace.dart';
import 'ui_polish_capture.dart';

void main() {
  setUpAll(loadPolishFonts);
  for (final size in [const Size(390, 844), const Size(800, 1000), const Size(1440, 1000)]) {
    for (final dark in [false, true]) {
      testWidgets('staff workspace ${size.width} dark=$dark', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final key = GlobalKey();
        await tester.pumpWidget(RepaintBoundary(key: key, child: ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(StaffWorkspaceUser.new),
            staffListProvider.overrideWith(StaffWorkspaceRoster.new),
            pendingStaffApplicationsProvider.overrideWith(StaffWorkspacePending.new),
          ],
          child: MaterialApp(debugShowCheckedModeBanner: false,
            theme: dark ? AppTheme.dark(clinicalBluePaletteDark) : AppTheme.light(clinicalBluePaletteLight),
            home: AppShell(currentTabIndex: 2, onTabSelected: (_) {}, userRole: 'super_admin',
              child: const StaffListScreen()),
          ),
        )));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.navAnalytics), findsNothing);
        expect(find.text(AppStrings.addStaff), findsOneWidget);
        await capturePolish(tester, key, 'staff-${size.width}-$dark');
        await tester.tap(find.text(AppStrings.sectionCount(AppStrings.pending, 2)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await capturePolish(tester, key, 'pending-${size.width}-$dark');
        await tester.tap(find.text(AppStrings.approve).first);
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.approveStaffMessage(pendingStaff.first.fullName)), findsOneWidget);
        await tester.tap(find.text(AppStrings.cancel));
        await tester.pumpAndSettle();
        expect(find.text(AppStrings.approve).first, findsOneWidget);
      });
    }
  }
  for (final width in [390.0, 1440.0]) {
    testWidgets('staff create form $width', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(key: key, child: ProviderScope(
        child: MaterialApp(debugShowCheckedModeBanner: false,
          theme: AppTheme.light(clinicalBluePaletteLight),
          home: StaffFormBody(currentUser: staffAdmin)),
      )));
      await tester.pumpAndSettle();
      await capturePolish(tester, key, 'staff-form-$width');
      await tester.tap(find.text(AppStrings.save));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.fullNameRequired), findsOneWidget);
      expect(find.text(AppStrings.roleRequired), findsOneWidget);
      final role = find.byType(FormBuilderDropdown<UserRole>);
      await tester.ensureVisible(role);
      await tester.tap(role);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capturePolish(tester, key, 'staff-role-$width');
      await tester.tap(find.text(AppStrings.receptionist).last);
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.canManagePayments), findsOneWidget);
      expect(tester.getBottomRight(find.text(AppStrings.save)).dy, lessThan(1000));
    });
  }
}
