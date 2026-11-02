import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spine_clinic_app/features/medical_records/data/program_repository_impl.dart';
import '../../fixtures/test_supabase_service.dart';
import '../../fixtures/workspace_data.dart';

http.Response _json(Object value, {int status = 200}) =>
    http.Response(jsonEncode(value), status, headers: {'content-type': 'application/json'});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final program = workspacePrograms.first;

  for (final cleanupFails in [false, true]) {
    test('removals share the save RPC; cleanup follows commit, failure=$cleanupFails', () async {
      final calls = <String>[];
      final service = TestSupabaseService((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if (request.url.path.endsWith('/save_program_mutation')) {
          calls.add('database');
          final payload = body['p_payload'] as Map<String, dynamic>;
          expect(payload['p_removed_document_ids'], ['doc-a', 'doc-b']);
          expect(payload['p_notes'], 'Updated notes');
          return _json({
            'ok': true,
            'program': program.toJson(),
            'removed_document_ids': ['doc-a', 'doc-b'],
            'removed_document_paths': [
              'https://storage.example/patient-documents/patient/scan%20one.jpg',
              'patient/thumb.jpg',
              'patient/thumb.jpg',
            ],
          });
        }
        calls.add('storage');
        expect(body['action'], 'delete-objects');
        expect(body['objectKeys'], ['patient/scan one.jpg', 'patient/thumb.jpg']);
        return _json({'success': !cleanupFails}, status: cleanupFails ? 500 : 200);
      });
      addTearDown(service.client.dispose);
      final result = await ProgramRepositoryImpl(supabaseService: service).updateProgram(
        programId: program.id,
        patientId: program.patientId,
        conditionIds: ['condition'],
        notes: 'Updated notes',
        removedDocumentIds: ['doc-b', 'doc-a', 'doc-a'],
      );
      expect(result.isSuccess, true);
      expect(calls, ['database', 'storage']);
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    });
  }

  test('lost save response reuses identity and cleans paths from the replayed receipt', () async {
    final requests = <String>[];
    int cleanup = 0;
    final service = TestSupabaseService((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      if (request.url.path.endsWith('/save_program_mutation')) {
        requests.add(body['p_request_id'] as String);
        if (requests.length == 1) throw TimeoutException('Committed; response lost');
        return _json({
          'ok': true,
          'program': program.toJson(),
          'removed_document_ids': ['doc-a'],
          'removed_document_paths': ['patient/a.pdf'],
        });
      }
      cleanup++;
      return _json({'success': true});
    });
    addTearDown(service.client.dispose);
    final repo = ProgramRepositoryImpl(supabaseService: service);
    final first = await repo.updateProgram(
      programId: program.id,
      patientId: program.patientId,
      conditionIds: [],
      removedDocumentIds: ['doc-a'],
    );
    expect(first.exceptionOrNull!.userMessageKey, 'mutation_unconfirmed');
    expect(cleanup, 0);
    final retry = await repo.updateProgram(
      programId: program.id,
      patientId: program.patientId,
      conditionIds: [],
      removedDocumentIds: ['doc-a'],
    );
    expect(retry.isSuccess, true);
    expect(requests.toSet(), hasLength(1));
    expect(cleanup, 1);
  });

  for (final acknowledged in [false, true]) {
    test('never cleans storage for unacknowledged removals; acknowledged=$acknowledged', () async {
      final service = TestSupabaseService((request) async {
        expect(request.url.path.endsWith('/save_program_mutation'), true);
        return _json({
          'ok': true,
          'program': program.toJson(),
          if (acknowledged) 'removed_document_ids': ['doc-a'],
        });
      });
      addTearDown(service.client.dispose);
      final result = await ProgramRepositoryImpl(supabaseService: service).updateProgram(
        programId: program.id,
        patientId: program.patientId,
        conditionIds: [],
        removedDocumentIds: ['doc-a'],
      );
      expect(result.isSuccess, acknowledged);
      if (!acknowledged) expect(result.exceptionOrNull!.userMessageKey, 'mutation_unconfirmed');
    });
  }

  test('rejected transaction never attempts storage cleanup', () async {
    final service = TestSupabaseService((request) async {
      expect(request.url.path.endsWith('/save_program_mutation'), true);
      return _json({'ok': false, 'code': '23503', 'message': 'Invalid condition'});
    });
    addTearDown(service.client.dispose);
    final result = await ProgramRepositoryImpl(supabaseService: service).updateProgram(
      programId: program.id,
      patientId: program.patientId,
      conditionIds: [],
      removedDocumentIds: ['doc-a'],
    );
    expect(result.isFailure, true);
    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
  });
}
