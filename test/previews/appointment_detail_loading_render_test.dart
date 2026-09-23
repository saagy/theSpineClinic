import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_notes_card.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_program_pdf_tile.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_records_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

import '../fixtures/workspace_data.dart';
import '../fixtures/workspace_overrides.dart';
import 'ui_polish_capture.dart';

class _DelayedAppointmentNote extends AppointmentNote {
  _DelayedAppointmentNote(this.note);
  final Future<PatientNote?> note;

  @override
  Future<PatientNote?> build(String appointmentId) => note;
}

void main() {
  setUpAll(loadPolishFonts);
  for (final width in [360.0, 1280.0]) {
    testWidgets('appointment detail fields settle without fallback at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final note = Completer<PatientNote?>();
      final key = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith(() => WorkspaceUser('doctor')),
            canAccessPatientProvider(
              workspacePatient.id,
            ).overrideWith((ref) async => true),
            patientProgramsProvider(
              workspacePatient.id,
            ).overrideWith(() => WorkspaceProgramData(false)),
            appointmentNoteProvider(
              'appointment-fixture',
            ).overrideWith(() => _DelayedAppointmentNote(note.future)),
          ],
          child: RepaintBoundary(
            key: key,
            child: MaterialApp(
              theme: AppTheme.light(clinicalBluePaletteLight),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      AppointmentProgramPdfTile(patient: workspacePatient),
                      AppointmentNotesCard(
                        appointmentId: 'appointment-fixture',
                        patientId: workspacePatient.id,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(SkeletonBox), findsWidgets);
      expect(find.text(AppStrings.clinicalAssessmentAndPlan), findsNothing);
      note.complete(
        PatientNote(
          id: 'note-fixture',
          patientId: workspacePatient.id,
          appointmentId: 'appointment-fixture',
          createdBy: 'staff-fixture',
          noteText: 'Patient tolerated the session well.',
          createdAt: DateTime(2026, 9, 23),
          updatedAt: DateTime(2026, 9, 23),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));
      expect(find.text('Patient tolerated the session well.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capturePolish(tester, key, 'appointment-detail-fields-$width');
    });
  }
}
