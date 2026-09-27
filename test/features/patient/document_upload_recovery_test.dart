import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spine_clinic_app/features/patient/data/patient_document_cache.dart';
import 'package:spine_clinic_app/features/patient/data/patient_documents_repository.dart';
import '../../fixtures/test_supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final loseStage in ['put', 'finish']) {
    test(
      'lost $loseStage response reuses durable identity without deletion or another PUT',
      () async {
        SharedPreferences.setMockInitialValues({});
        bool stored = false, committed = false, loseReply = true;
        int puts = 0;
        final actions = <String>[];
        final ids = <String>[];
        final document = {
          'id': 'document',
          'patient_id': 'patient',
          'file_url': 'patient/object',
          'file_name': 'scan.png',
          'uploaded_by': 'staff',
          'uploaded_at': DateTime(2026).toIso8601String(),
        };
        final service = TestSupabaseService((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final action = body['action'] as String;
          actions.add(action);
          ids.add(body['requestId'] as String);
          if (action == 'finish-upload') {
            committed = true;
            if (loseStage == 'finish' && loseReply) {
              loseReply = false;
              throw TimeoutException('Lost database reply');
            }
          }
          if (stored) committed = true;
          return http.Response(
            jsonEncode(
              committed
                  ? {'ok': true, 'document': document}
                  : {
                      'uploadUrl': 'https://example.test/upload',
                      'objectKey': 'patient/object',
                      'contentType': 'image/png',
                    },
            ),
            200,
            headers: {'content-type': 'application/json'},
          );
        });
        addTearDown(service.client.dispose);
        final bytes = Uint8List.fromList([1, 2, 3]);
        final cache = PatientDocumentCache();
        await http.runWithClient(
          () async {
            final first =
                await PatientDocumentsRepositoryImpl(
                  supabaseService: service,
                  cache: cache,
                ).uploadDocument(
                  patientId: 'patient',
                  fileName: 'scan.png',
                  fileBytes: bytes,
                  uploadedBy: 'staff',
                );
            expect(first.isFailure, true);
            expect(cache.get('patient/object'), null);
            expect(
              (await SharedPreferences.getInstance()).getKeys(),
              isNotEmpty,
            );
            // Recreate the repository to model navigation/reload, not an in-memory retry.
            final retry =
                await PatientDocumentsRepositoryImpl(
                  supabaseService: service,
                  cache: cache,
                ).uploadDocument(
                  patientId: 'patient',
                  fileName: 'scan.png',
                  fileBytes: bytes,
                  uploadedBy: 'staff',
                );
            expect(retry.isSuccess, true);
            expect(cache.get('patient/object'), bytes);
            expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
          },
          () => MockClient((request) async {
            puts++;
            stored = true;
            if (loseStage == 'put' && loseReply) {
              loseReply = false;
              throw http.ClientException('Lost PUT reply');
            }
            return http.Response('', 200);
          }),
        );
        expect(puts, 1);
        expect(ids.toSet(), hasLength(1));
        expect(actions, isNot(contains('delete-objects')));
      },
    );
  }
}
