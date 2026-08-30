import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_repository.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_documents_repository.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_document_actions.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_document_item.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_tab_documents.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/program_document_folder_tile.dart';

class FakePatientDocumentsRepository implements PatientDocumentsRepository {
  final List<PatientDocument> mockDocs;
  FakePatientDocumentsRepository(this.mockDocs);

  @override
  Future<Result<List<PatientDocument>>> fetchDocuments(String patientId) async {
    return Result.success(mockDocs);
  }

  @override
  Future<Result<PatientDocument>> uploadDocument({
    required String patientId,
    required String fileName,
    required Uint8List fileBytes,
    required String uploadedBy,
    String? programId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Uint8List>> downloadDocumentBytes({
    required String fileUrl,
    required String fileName,
  }) async {
    return Result.success(Uint8List(0));
  }

  @override
  Future<Result<PatientDocument>> renameDocument({
    required String documentId,
    required String fileName,
  }) async {
    final int index = mockDocs.indexWhere(
      (PatientDocument document) => document.id == documentId,
    );
    final PatientDocument renamed = mockDocs[index].copyWith(
      fileName: fileName,
    );
    mockDocs[index] = renamed;
    return Result.success(renamed);
  }

  @override
  Future<Result<void>> deleteDocument({required String documentId}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> deletePatientStorageFolder(String patientId) {
    throw UnimplementedError();
  }
}

class FakeProgramRepository implements ProgramRepository {
  final List<PatientProgram> programs;
  FakeProgramRepository(this.programs);

  @override
  Future<Result<List<PatientProgram>>> getProgramsForPatient(
    String patientId,
  ) async =>
      Result.success(programs);

  @override
  Future<Result<PatientProgram?>> getProgramById(String programId) async =>
      Result.success(programs.where((p) => p.id == programId).firstOrNull);

  @override
  Future<Result<PatientProgram>> createProgram({
    required String patientId,
    required List<String> conditionIds,
    String? examination,
    String? imagingNotes,
    String? exaggeratingPositions,
    String? relievingPositions,
    String? notes,
    List<ProgramAttachment>? pendingAttachments,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<PatientProgram>> updateProgram({
    required String programId,
    required String patientId,
    required List<String> conditionIds,
    String? examination,
    String? imagingNotes,
    String? exaggeratingPositions,
    String? relievingPositions,
    String? notes,
    ProgramStatus? status,
    List<ProgramAttachment>? pendingAttachments,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<void>> updateProgramStatus({
    required String programId,
    required ProgramStatus status,
  }) async =>
      const Result.success(null);

  @override
  Future<Result<void>> deleteProgram(String programId) async =>
      const Result.success(null);
}

void main() {
  final patient = Patient(
    id: 'p1',
    fullName: 'John Doe',
    phoneNumber: '12345678',
    clinic: ClinicLocation.tagamoa,
    createdAt: DateTime.now(),
  );

  final mockDocs = [
    PatientDocument(
      id: 'd1',
      patientId: 'p1',
      fileUrl: 'https://example.com/doc1.pdf',
      fileName: 'doc1.pdf',
      uploadedAt: DateTime.now(),
    ),
    PatientDocument(
      id: 'd2',
      patientId: 'p1',
      fileUrl: 'https://example.com/doc2.pdf',
      fileName: 'doc2.pdf',
      uploadedAt: DateTime.now(),
    ),
  ];

  Widget buildTestWidget({
    required FakePatientDocumentsRepository repo,
    required double width,
    FakeProgramRepository? programRepo,
  }) {
    return ProviderScope(
      overrides: [
        patientDocumentsRepositoryProvider.overrideWithValue(repo),
        if (programRepo != null)
          programRepositoryProvider.overrideWithValue(programRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            height: 800,
            child: PatientTabDocuments(patient: patient),
          ),
        ),
      ),
    );
  }

  PatientProgram buildProgram({
    required String id,
    required DateTime createdAt,
  }) {
    return PatientProgram(
      id: id,
      patientId: 'p1',
      createdBy: 'doc1',
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  group('PatientTabDocuments Responsive Columns Test', () {
    testWidgets('document actions use the minimum touch target', (
      WidgetTester tester,
    ) async {
      final repo = FakePatientDocumentsRepository(List.of(mockDocs));
      await tester.pumpWidget(buildTestWidget(repo: repo, width: 375));
      await tester.pumpAndSettle();

      final Finder actions = find.byType(PatientDocumentActions).first;
      expect(tester.getSize(actions), const Size(44, 44));
    });

    testWidgets('Uses exactly 2 columns on mobile screen (width < 600)', (
      tester,
    ) async {
      final repo = FakePatientDocumentsRepository(mockDocs);

      // Set mobile screen size
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget(repo: repo, width: 375));
      await tester.pumpAndSettle();

      // Find the GridView
      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);

      final GridView grid = tester.widget(gridFinder);
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      // Verify that it is locked to 2 columns on mobile
      expect(delegate.crossAxisCount, 2);
    });

    testWidgets('Scales columns up on desktop/PC screen (width >= 600)', (
      tester,
    ) async {
      final repo = FakePatientDocumentsRepository(mockDocs);

      // Set desktop screen size
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget(repo: repo, width: 1200));
      await tester.pumpAndSettle();

      // Find the GridView
      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);

      final GridView grid = tester.widget(gridFinder);
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      // At 1200 width, formula is (1200 / 300).floor().clamp(2, 6) = 4 columns
      expect(delegate.crossAxisCount, 4);
    });
  });

  group('PatientTabDocuments Program Folder Grouping', () {
    PatientDocument doc(String id, {String? programId, DateTime? at}) =>
        PatientDocument(
          id: id,
          patientId: 'p1',
          fileUrl: 'https://example.com/$id.pdf',
          fileName: '$id.pdf',
          programId: programId,
          uploadedAt: at ?? DateTime(2026, 8, 30),
        );

    testWidgets('renders program docs as a single folder tile', (
      tester,
    ) async {
      final docs = [
        doc('d1', programId: 'prog-1'),
        doc('d2', programId: 'prog-1'),
        doc('d3'), // standalone
      ];
      final repo = FakePatientDocumentsRepository(List.of(docs));
      final progRepo = FakeProgramRepository([
        buildProgram(
          id: 'prog-1',
          createdAt: DateTime(2026, 8, 20),
        ),
      ]);

      await tester.pumpWidget(
        buildTestWidget(
          repo: repo,
          width: 375,
          programRepo: progRepo,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProgramDocumentFolderTile), findsOneWidget);
      // Only the standalone doc is rendered as a PatientDocumentItem.
      expect(find.byType(PatientDocumentItem), findsOneWidget);
    });

    testWidgets('standalone docs with no programId render as doc tiles', (
      tester,
    ) async {
      final docs = [
        doc('d1'),
        doc('d2'),
      ];
      final repo = FakePatientDocumentsRepository(List.of(docs));

      await tester.pumpWidget(buildTestWidget(repo: repo, width: 375));
      await tester.pumpAndSettle();

      expect(find.byType(ProgramDocumentFolderTile), findsNothing);
      expect(find.byType(PatientDocumentItem), findsNWidgets(2));
    });

    testWidgets('program with no docs does not surface a folder', (
      tester,
    ) async {
      final docs = [doc('d1')];
      final repo = FakePatientDocumentsRepository(List.of(docs));
      final progRepo = FakeProgramRepository([
        buildProgram(id: 'prog-empty', createdAt: DateTime(2026, 1, 1)),
      ]);

      await tester.pumpWidget(
        buildTestWidget(repo: repo, width: 375, programRepo: progRepo),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProgramDocumentFolderTile), findsNothing);
      expect(find.byType(PatientDocumentItem), findsOneWidget);
    });

    testWidgets('tapping a folder tile pushes a new route', (
      tester,
    ) async {
      final docs = [
        doc('d1', programId: 'prog-1'),
        doc('d2', programId: 'prog-1'),
      ];
      final repo = FakePatientDocumentsRepository(List.of(docs));
      final progRepo = FakeProgramRepository([
        buildProgram(id: 'prog-1', createdAt: DateTime(2026, 8, 20)),
      ]);

      await tester.pumpWidget(
        buildTestWidget(
          repo: repo,
          width: 800,
          programRepo: progRepo,
        ),
      );
      await tester.pumpAndSettle();

      final BuildContext tabContext = tester.element(
        find.byType(PatientTabDocuments),
      );
      final NavigatorState nav = Navigator.of(tabContext);
      expect(nav.canPop(), isFalse);

      await tester.tap(find.byType(ProgramDocumentFolderTile));
      await tester.pumpAndSettle();

      expect(nav.canPop(), isTrue);
    });
  });
}
