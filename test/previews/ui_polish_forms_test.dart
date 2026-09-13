import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/new_patient_form.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/edit_patient_form.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/new_appointment_form.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/recurring_pattern_picker.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/screens/program_form_screen.dart';
import '../fixtures/workspace_data.dart';
import '../fixtures/workspace_overrides.dart';
import 'ui_polish_capture.dart';

void main() {
  setUpAll(loadPolishFonts);
  for (final width in [360.0, 1280.0]) {
    for (final name in ['patient-create', 'patient-edit', 'appointment-create', 'program-create']) {
      testWidgets('$name production form at $width', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final key = GlobalKey();
        final Widget form = switch (name) {
          'patient-create' => Scaffold(
            appBar: AppBar(title: const Text(AppStrings.registerPatient)),
            body: const NewPatientForm(),
          ),
          'patient-edit' => EditPatientForm(
            patient: workspacePatient,
            assignedDoctors: [workspaceStaff('doctor')],
          ),
          'appointment-create' => Scaffold(
            appBar: AppBar(title: const Text(AppStrings.newAppointment)),
            body: const NewAppointmentForm(),
          ),
          _ => const ProgramFormScreen(patientId: 'patient'),
        };
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: ProviderScope(
              overrides: [currentUserProvider.overrideWith(() => WorkspaceUser('reception'))],
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light(clinicalBluePaletteLight),
                home: form,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await capturePolish(tester, key, '$name-$width');
        if (name == 'appointment-create') {
          await tester.ensureVisible(find.text(AppStrings.recurringBooking));
          await tester.tap(find.text(AppStrings.recurringBooking));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.byType(RecurringPatternPicker));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await capturePolish(tester, key, 'appointment-recurrence-$width');
        }
        final save = find.byType(FilledButton).last;
        expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(1000));
        expect(tester.getSize(save).height, greaterThanOrEqualTo(44));
      });
    }
  }
}
