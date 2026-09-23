import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_document_groups.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_note_row.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_program_pdf_tile.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_program_summary.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

import '../../fixtures/workspace_data.dart';
import '../../fixtures/workspace_overrides.dart';

class _DelayedPrograms extends PatientProgramsNotifier {
  _DelayedPrograms(this.programs);
  final Future<List<PatientProgram>> programs;

  @override
  Future<List<PatientProgram>> build(String patientId) => programs;
}

void main() {
  test('document folders wait for program titles before appearing', () async {
    final programs = Completer<List<PatientProgram>>();
    final id = workspacePatient.id;
    final container = ProviderContainer(
      overrides: [
        patientDocumentsNotifierProvider(
          id,
        ).overrideWith(() => WorkspaceDocumentData(false)),
        patientProgramsProvider(
          id,
        ).overrideWith(() => _DelayedPrograms(programs.future)),
      ],
    );
    addTearDown(container.dispose);
    final provider = patientDocumentGroupsProvider(id);
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(provider).isLoading, isTrue);

    programs.complete(workspacePrograms);
    final groups = await container.read(provider.future);
    expect(groups.folders, hasLength(2));
    expect(groups.folders.every((folder) => folder.program != null), isTrue);
  });

  testWidgets('note author keeps the same left edge as its placeholder', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final author = Completer<Staff>();
    final note = PatientNote(
      id: 'note-fixture',
      patientId: workspacePatient.id,
      createdBy: 'staff-fixture',
      noteText: 'Patient is improving.',
      createdAt: DateTime(2026, 9, 6),
      updatedAt: DateTime(2026, 9, 6),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          staffProfileProvider(
            'staff-fixture',
          ).overrideWith((ref) => author.future),
        ],
        child: MaterialApp(
          home: Scaffold(body: WorkspaceNoteRow(note: note)),
        ),
      ),
    );
    final before = tester.getTopLeft(find.byType(SkeletonBox).first).dx;
    author.complete(workspaceStaff('doctor'));
    await tester.pump();
    final fade = find.ancestor(
      of: find.text('Dr. Mariam Khaled'),
      matching: find.byType(FadeTransition),
    );
    expect(
      tester.widget<FadeTransition>(fade.first).opacity.value,
      lessThan(1),
    );
    await tester.pump(const Duration(milliseconds: 200));
    final after = tester.getTopLeft(find.text('Dr. Mariam Khaled')).dx;
    expect(after, closeTo(before, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('appointment report shows no generic subtitle while loading', (
    tester,
  ) async {
    final programs = Completer<List<PatientProgram>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          canAccessPatientProvider(
            workspacePatient.id,
          ).overrideWith((ref) async => true),
          patientProgramsProvider(
            workspacePatient.id,
          ).overrideWith(() => _DelayedPrograms(programs.future)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AppointmentProgramPdfTile(patient: workspacePatient),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(AppStrings.programReport), findsOneWidget);
    expect(find.byType(SkeletonBox), findsWidgets);
    expect(find.text(AppStrings.clinicalAssessmentAndPlan), findsNothing);

    programs.complete(workspacePrograms);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      find.text(appointmentProgramSummary(workspacePrograms)),
      findsOneWidget,
    );
    expect(find.text(AppStrings.clinicalAssessmentAndPlan), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
