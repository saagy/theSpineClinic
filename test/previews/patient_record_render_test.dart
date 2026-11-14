import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import '../fixtures/workspace_harness.dart';
import 'ui_polish_capture.dart';

final PatientPersonalDetails profile = PatientPersonalDetails(
  address: 'Tagamoa 5, building 12',
  dateOfBirth: DateTime(1988, 4, 2),
  nationality: 'Egyptian',
  gender: PatientGender.male,
  secondaryPhone: '01222222222',
  referralSource: 'Facebook',
);

void main() {
  setUpAll(loadPolishFonts);
  for (final (String name, double width, bool dark) in [
    ('desktop', 1280.0, false),
    ('phone', 390.0, false),
    ('phone-dark', 390.0, true),
  ]) {
    testWidgets('patient record keeps identity and contact out of the overview $name', (tester) async {
      tester.view.physicalSize = Size(width, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(key: key, child: WorkspaceHarness(role: 'receptionist', dark: dark, profile: profile)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Male · '), findsOneWidget);
      expect(find.text(AppStrings.personalDetails), findsNothing);
      expect(find.text('Facebook'), findsOneWidget);
      expect(find.text('Tagamoa 5, building 12'), findsOneWidget);
      await capturePolish(tester, key, 'patient-record-$name');
    });
  }
}
