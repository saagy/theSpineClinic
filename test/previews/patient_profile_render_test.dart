import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import '../fixtures/workspace_harness.dart';
import 'ui_polish_capture.dart';

void main() {
  setUpAll(loadPolishFonts);
  for (final width in [390.0, 1440.0]) {
    testWidgets('patient overview renders ID and recorded profile details at $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: const WorkspaceHarness(
          role: 'reception',
          longName: true,
          profile: PatientPersonalDetails(
            address: 'Demo address, New Cairo',
            nationality: 'Egyptian',
            secondaryPhone: '00000000003',
            insuranceCompany: 'Demo Insurance',
            referralSource: 'Referred by a doctor',
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.patientIdLabel(107)), findsOneWidget);
      expect(find.text('Demo Insurance'), findsOneWidget);
      expect(find.text(AppStrings.patientInsuranceNumber), findsNothing);
      await capturePolish(tester, key, 'patient-personal-details-$width');
      expect(tester.takeException(), isNull);
    });
  }
}
