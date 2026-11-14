import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/booking_branch_field.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/booking_schedule_warnings.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_details_providers.dart';
import '../fixtures/staff_branches_fixture.dart';
import '../fixtures/staff_editor_harness.dart';
import '../fixtures/staff_workspace.dart';
import 'ui_polish_capture.dart';

void main() {
  setUpAll(loadPolishFonts);
  for (final (String name, bool dark) in [('light', false), ('dark', true)]) {
    testWidgets('booking branch and schedule warning $name', (tester) async {
      tester.view.physicalSize = const Size(390, 420);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: ProviderScope(
            overrides: [
              currentUserProvider.overrideWith(() => StaffEditorUser(staffAdmin)),
              staffAssignmentsProvider.overrideWith((ref) async => demoAssignments),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: dark ? AppTheme.dark(clinicalBluePaletteDark) : AppTheme.light(clinicalBluePaletteLight),
              home: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BookingBranchField(
                        value: ClinicLocation.tagamoa,
                        registeredAt: ClinicLocation.madinaty,
                        onChanged: (_) {},
                      ),
                      const SizedBox(height: 16),
                      // Sunday: Ahmed works at Madinaty, not Tagamoa.
                      BookingScheduleWarnings(
                        doctors: [staffRoster[1]],
                        branch: ClinicLocation.tagamoa,
                        starts: [DateTime(2026, 11, 15, 13)],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.staffSchedule.registeredAt('Madinaty')), findsOneWidget);
      expect(find.text('Ahmed Hassan works at Madinaty on Sunday.'), findsOneWidget);
      expect(find.text(AppStrings.staffSchedule.warningNote), findsOneWidget);
      await capturePolish(tester, key, 'booking-branch-$name');
    });
  }
}
