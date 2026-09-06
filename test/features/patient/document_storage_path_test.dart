import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/patient/data/patient_document_storage.dart';

void main() {
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
