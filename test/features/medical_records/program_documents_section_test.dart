import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_detail_documents.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/shared/widgets/record_skeleton.dart';
import '../../fixtures/workspace_data.dart';

void main() {
  final program = workspacePrograms.first;
  final provider = programDocumentsProvider(patientId: program.patientId, programId: program.id);

  testWidgets('documents retain an actionable heading while loading and when empty', (tester) async {
    final gate = Completer<List<PatientDocument>>();
    int opened = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [provider.overrideWith((ref) => gate.future)],
        child: MaterialApp(
          home: Scaffold(
            body: ProgramDetailDocuments(program: program, onEdit: () => opened++),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(AppStrings.tabDocuments), findsOneWidget);
    expect(find.byType(RecordSkeleton), findsOneWidget);
    gate.complete([]);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.noDocumentsYet), findsOneWidget);
    await tester.tap(find.text(AppStrings.addDocument));
    expect(opened, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('documents recover from failure without hiding their management action', (tester) async {
    int attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          provider.overrideWith((ref) async {
            if (++attempts == 1) throw StateError('Fixture network failure');
            return [workspaceDocuments.first];
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ProgramDetailDocuments(program: program, onEdit: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.patientSectionError), findsOneWidget);
    expect(find.text(AppStrings.manage), findsOneWidget);
    await tester.tap(find.text(AppStrings.retry));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.patientSectionError), findsNothing);
    expect(find.text(workspaceDocuments.first.fileName), findsOneWidget);
    expect(find.text(AppStrings.imagingAttachments), findsNothing);
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
  });
}
