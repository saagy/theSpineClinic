import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_documents_repository.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_tab_documents.dart';

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
  Future<Result<void>> deleteDocument({required String documentId}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> deletePatientStorageFolder(String patientId) {
    throw UnimplementedError();
  }
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
  }) {
    return ProviderScope(
      overrides: [
        patientDocumentsRepositoryProvider.overrideWithValue(repo),
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

  group('PatientTabDocuments Responsive Columns Test', () {
    testWidgets('Uses exactly 2 columns on mobile screen (width < 600)', (tester) async {
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
      final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      // Verify that it is locked to 2 columns on mobile
      expect(delegate.crossAxisCount, 2);
    });

    testWidgets('Scales columns up on desktop/PC screen (width >= 600)', (tester) async {
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
      final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      // At 1200 width, formula is (1200 / 300).floor().clamp(2, 6) = 4 columns
      expect(delegate.crossAxisCount, 4);
    });
  });
}
