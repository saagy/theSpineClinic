import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spine_clinic_app/features/medical_records/data/program_repository_impl.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_repository.dart';
import '../../fixtures/test_supabase_service.dart';
import '../../fixtures/workspace_data.dart';

http.Response _json(Object data) => http.Response(
  jsonEncode(data),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final lostStage in ['program', 'attachment']) {
    test(
      'lost $lostStage response resumes without duplicate programs or files',
      () async {
        final program = workspacePrograms.first;
        final receipts = <String>{};
        final uploaded = <String>{};
        final programIds = <String>[];
        final uploadIds = <String>[];
        bool loseReply = true;
        final service = TestSupabaseService((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          if (request.url.path.endsWith('/save_program_mutation')) {
            final id = body['p_request_id'] as String;
            programIds.add(id);
            receipts.add(id);
            if (lostStage == 'program' && loseReply) {
              loseReply = false;
              throw TimeoutException('Lost after commit');
            }
            return _json({'ok': true, 'program': program.toJson()});
          }
          expect(body['action'], 'start-upload');
          expect(body['programId'], program.id);
          final id = body['requestId'] as String;
          uploadIds.add(id);
          uploaded.add(id);
          if (lostStage == 'attachment' && loseReply && uploaded.length == 2) {
            loseReply = false;
            throw TimeoutException('Lost after document commit');
          }
          return _json({
            'ok': true,
            'document': {
              'id': id,
              'patient_id': program.patientId,
              'program_id': program.id,
              'file_url': '${program.patientId}/$id',
              'file_name': body['fileName'],
              'uploaded_by': 'staff',
              'uploaded_at': DateTime(2026).toIso8601String(),
            },
          });
        });
        addTearDown(service.client.dispose);
        Future<bool> save() async {
          final result = await ProgramRepositoryImpl(supabaseService: service)
              .createProgram(
                patientId: program.patientId,
                conditionIds: ['condition'],
                pendingAttachments: [
                  for (int i = 0; i < 2; i++)
                    ProgramAttachment(
                      fileName: '$i.jpg',
                      bytes: Uint8List.fromList([i + 1]),
                    ),
                ],
              );
          if (result.isFailure) {
            expect(
              result.exceptionOrNull!.userMessageKey,
              lostStage == 'program'
                  ? 'mutation_unconfirmed'
                  : 'program_attachments_pending',
            );
          } else {
            expect(result.dataOrNull!.conditions.first.condition, isNotNull);
          }
          return result.isSuccess;
        }

        expect(await save(), false);
        expect(await save(), true);
        expect(receipts, hasLength(1));
        expect(programIds, hasLength(2));
        expect(uploaded, hasLength(2));
        if (lostStage == 'attachment') expect(uploadIds, hasLength(4));
        expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
      },
    );
  }
  test('invalid attachment is rejected before saving the program', () async {
    final service = TestSupabaseService(
      (_) async => throw StateError('Unexpected write'),
    );
    addTearDown(service.client.dispose);
    final result = await ProgramRepositoryImpl(supabaseService: service)
        .createProgram(
          patientId: 'patient',
          conditionIds: ['condition'],
          pendingAttachments: [
            ProgramAttachment(fileName: 'script.exe', bytes: Uint8List(1)),
          ],
        );
    expect(
      result.exceptionOrNull!.userMessageKey,
      'error_doc_unsupported_type',
    );
  });
  test(
    'definitive attachment rejection preserves the saved program identity',
    () async {
      final ids = <String>{};
      final program = workspacePrograms.first;
      final service = TestSupabaseService((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if (request.url.path.endsWith('/save_program_mutation')) {
          ids.add(body['p_request_id'] as String);
          return _json({'ok': true, 'program': program.toJson()});
        }
        return _json({'ok': false, 'code': '23503'});
      });
      addTearDown(service.client.dispose);
      for (int attempt = 0; attempt < 2; attempt++) {
        final result = await ProgramRepositoryImpl(supabaseService: service)
            .createProgram(
              patientId: program.patientId,
              conditionIds: ['condition'],
              pendingAttachments: [
                ProgramAttachment(fileName: 'scan.jpg', bytes: Uint8List(1)),
              ],
            );
        expect(
          result.exceptionOrNull!.userMessageKey,
          'program_attachments_rejected',
        );
      }
      expect(ids, hasLength(1));
      expect((await SharedPreferences.getInstance()).getKeys(), hasLength(1));
    },
  );
}
