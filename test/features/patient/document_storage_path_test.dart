import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/patient/data/patient_documents_repository.dart';
import '../../fixtures/test_supabase_service.dart';
import 'package:spine_clinic_app/features/patient/data/patient_document_storage.dart';

void main() {
  test(
    'filename-only test records show an incomplete link without a network call',
    () async {
      final service = TestSupabaseService(
        (_) async => throw StateError('Unexpected request'),
      );
      addTearDown(service.client.dispose);
      final result = await PatientDocumentsRepositoryImpl(
        supabaseService: service,
      ).downloadDocumentBytes(fileUrl: 'scan.jpg', fileName: 'scan.jpg');
      expect(
        result.exceptionOrNull!.userMessageKey,
        'error_doc_link_incomplete',
      );
    },
  );
  test(
    'storage keys require a patient UUID and safe nonempty path components',
    () {
      const patient = '10000000-0000-0000-0000-000000000001';
      expect(isPatientDocumentStoragePath('$patient/scan.jpg'), true);
      expect(isPatientDocumentStoragePath('$patient/../scan.jpg'), false);
      expect(isPatientDocumentStoragePath('$patient//scan.jpg'), false);
      expect(isPatientDocumentStoragePath('scan.jpg'), false);
    },
  );
  test('legacy signed URLs exclude token and decode the filename', () {
    expect(
      patientDocumentStoragePath(
        'https://example.test/storage/v1/object/sign/patient-documents/patient/report%20one.pdf?token=secret',
      ),
      'patient/report one.pdf',
    );
  });

  test('raw keys and R2 signed URLs resolve to the same object', () {
    expect(
      patientDocumentStoragePath('patient/report.pdf'),
      'patient/report.pdf',
    );
    expect(
      patientDocumentStoragePath(
        'https://example.test/bucket/patient/report.pdf?signature=secret',
      ),
      'patient/report.pdf',
    );
  });

  test('empty and malformed encoded paths are rejected', () {
    expect(patientDocumentStoragePath(null), isNull);
    expect(patientDocumentStoragePath('  '), isNull);
    expect(patientDocumentStoragePath('patient/bad%xx.pdf'), isNull);
  });
}
