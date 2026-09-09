import 'dart:convert';
import 'dart:typed_data';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_documents_repository.dart';

class WorkspaceDocumentRepository implements PatientDocumentsRepository {
  final List<String> requests = [];
  @override
  Future<Result<Uint8List>> downloadDocumentBytes({required String fileUrl, required String fileName}) async {
    requests.add(fileUrl);
    return Result.success(base64Decode(sampleImage));
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnsupportedError('${invocation.memberName}');
}

const sampleImage =
    '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'
    'LSlxv0wAAAAASUVORK5CYII=';
