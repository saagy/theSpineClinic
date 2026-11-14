import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import '../fixtures/booking_balance_harness.dart';
import 'ui_polish_capture.dart';

Appointment _visit(DateTime at, AppointmentType type, [ClinicLocation? branch]) => Appointment(
  id: 'visit-${at.toIso8601String()}',
  patientId: bookingTestPatientId,
  type: type,
  scheduledAt: at.toUtc(),
  branch: branch,
  createdAt: DateTime(2026),
);

// The harness books Tuesday 1 Sep 2026 at 9:00 AM.
final List<Appointment> _visits = [
  _visit(DateTime(2026, 9, 1, 9), AppointmentType.reassessment, ClinicLocation.tagamoa),
  _visit(DateTime(2026, 9, 3, 14), AppointmentType.normalPtSession, ClinicLocation.madinaty),
  _visit(DateTime(2026, 9, 8, 9), AppointmentType.normalPtSession),
  _visit(DateTime(2026, 9, 10, 11), AppointmentType.spinalTractionSession),
];

void main() {
  setUpAll(loadPolishFonts);
  for (final (double width, bool dark) in [(360.0, false), (1280.0, false), (1280.0, true)]) {
    testWidgets('patient clash warning at $width, dark=$dark', (tester) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: buildBookingBalanceHarness(
            existingVisits: _visits,
            theme: dark ? AppTheme.dark(clinicalBluePaletteDark) : AppTheme.light(clinicalBluePaletteLight),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.bookingClash.sameTime), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capturePolish(tester, key, 'clash-single-$width-$dark');

      await tester.ensureVisible(find.text(AppStrings.recurringBooking));
      await tester.tap(find.text(AppStrings.recurringBooking));
      await tester.pumpAndSettle();
      for (final day in ['Tue', 'Thu']) {
        await tester.ensureVisible(find.text(day));
        await tester.tap(find.text(day));
        await tester.pumpAndSettle();
      }
      await tester.enterText(find.byType(TextField).last, '6');
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.bookingClash.severalDates(4)), findsOneWidget);
      expect(find.text(AppStrings.bookingClash.more(1)), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text(AppStrings.bookingClash.severalDates(4)));
      await tester.pumpAndSettle();
      await capturePolish(tester, key, 'clash-recurring-$width-$dark');
    });
  }
}
