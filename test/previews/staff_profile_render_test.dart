import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_details.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_profile_screen.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import '../fixtures/staff_branches_fixture.dart';
import '../fixtures/staff_editor_harness.dart';
import '../fixtures/staff_workspace.dart';
import 'ui_polish_capture.dart';

Future<void> pumpProfile(WidgetTester tester, {required Staff viewer, required GlobalKey key, bool dark = false}) async {
  final repo = StaffEditorRepository()
    ..assignments = demoAssignments
    ..details = StaffDetails(
      nationalId: '29001011234567',
      birthDate: DateTime(1988, 4, 2),
      hireDate: DateTime(2023, 9, 1),
      updatedAt: DateTime(2026, 11, 12),
      updatedById: staffAdmin.id,
    );
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: ProviderScope(
        overrides: [
          staffRepositoryProvider.overrideWithValue(repo),
          currentUserProvider.overrideWith(() => StaffEditorUser(viewer)),
          staffProfileProvider(staffRoster[1].id).overrideWith((ref) async => staffRoster[1]),
          staffProfileProvider(staffAdmin.id).overrideWith((ref) async => staffAdmin),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(clinicalBluePaletteLight),
          darkTheme: AppTheme.dark(clinicalBluePaletteDark),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          home: StaffProfileScreen(staffId: staffRoster[1].id),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadPolishFonts);
  for (final (String name, double width, bool dark) in [
    ('desktop', 1440.0, false),
    ('phone', 390.0, false),
    ('phone-dark', 390.0, true),
  ]) {
    testWidgets('staff profile $name', (tester) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final GlobalKey key = GlobalKey();
      await pumpProfile(tester, viewer: staffAdmin, key: key, dark: dark);
      expect(tester.takeException(), isNull);
      expect(find.text(staffRoster[1].fullName), findsOneWidget);
      expect(find.text(AppStrings.staffSchedule.maskedId('4567')), findsOneWidget);
      expect(find.text('29001011234567'), findsNothing);
      expect(find.text(AppStrings.staffSchedule.edit), findsOneWidget);
      await capturePolish(tester, key, 'staff-profile-$name');
      await tester.tap(find.text(AppStrings.staffSchedule.show));
      await tester.pumpAndSettle();
      expect(find.text('29001011234567'), findsOneWidget);
    });
  }

  testWidgets('head receptionists read the profile without Edit', (tester) async {
    tester.view.physicalSize = const Size(390, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final GlobalKey key = GlobalKey();
    await pumpProfile(tester, viewer: staffRoster[2].copyWith(canManagePayments: true), key: key);
    expect(find.text(AppStrings.staffSchedule.edit), findsNothing);
    expect(find.text(AppStrings.staffSchedule.weeklySchedule), findsOneWidget);
  });
}
