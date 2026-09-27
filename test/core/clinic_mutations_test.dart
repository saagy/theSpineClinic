import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/clinic_mutations.dart';
import '../fixtures/test_supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final payload = <String, dynamic>{'patient_id': 'patient', 'amount': 100};
  final ids = <String>[];
  late TestSupabaseService service;
  bool loseReply = false, reject = false;
  final receipts = <String, Map<String, dynamic>>{};
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ids.clear();
    receipts.clear();
    loseReply = false;
    reject = false;
    service = TestSupabaseService((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final id = body['p_request_id'] as String;
      if (request.url.path.endsWith('/resolve_clinic_mutation')) {
        final completed = receipts[id]?['ok'] == true;
        receipts.putIfAbsent(id, () => {'ok': false});
        return http.Response(jsonEncode(completed), 200);
      }
      ids.add(id);
      final outcome = receipts.putIfAbsent(
        id,
        () => reject
            ? {'ok': false, 'code': '23514', 'message': 'Rejected'}
            : {'ok': true},
      );
      if (loseReply) {
        loseReply = false;
        throw TimeoutException('Response lost after commit');
      }
      return http.Response(jsonEncode(outcome), 200);
    });
  });
  tearDown(() => service.client.dispose());

  test(
    'lost reply retains ID across service recreation and browser storage reload',
    () async {
      loseReply = true;
      await expectLater(
        ClinicMutations(service).execute('payment', 'patient', payload),
        throwsA(isA<NetworkException>()),
      );
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getKeys().map(preferences.get).join();
      expect(stored, isNot(contains('patient_id')));
      expect(stored, isNot(contains('amount')));
      await ClinicMutations(service).execute('payment', 'patient', payload);
      expect(ids, hasLength(2));
      expect(ids[0], ids[1]);
      expect(receipts, hasLength(1));
      expect(preferences.getKeys(), isEmpty);
      // A later deliberate identical payment is a new operation.
      await ClinicMutations(service).execute('payment', 'patient', payload);
      expect(ids.last, isNot(ids.first));
      expect(receipts, hasLength(2));
    },
  );
  test(
    'definite rejection clears the pending ID so corrected details can submit',
    () async {
      reject = true;
      await expectLater(
        ClinicMutations(service).execute('payment', 'patient', payload),
        throwsA(isA<DatabaseException>()),
      );
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
      reject = false;
      await ClinicMutations(
        service,
      ).execute('payment', 'patient', {...payload, 'amount': 150});
      expect(ids.last, isNot(ids.first));
    },
  );
  test(
    'editing an uncertain completed request requires review instead of another write',
    () async {
      loseReply = true;
      await expectLater(
        ClinicMutations(service).execute('payment', 'patient', payload),
        throwsA(isA<NetworkException>()),
      );
      await expectLater(
        ClinicMutations(
          service,
        ).execute('payment', 'patient', {...payload, 'amount': 150}),
        throwsA(
          isA<DatabaseException>().having(
            (e) => e.userMessageKey,
            'message',
            'mutation_previous_completed',
          ),
        ),
      );
      expect(ids, hasLength(1));
      expect(receipts, hasLength(1));
    },
  );
  test('duplicate in-flight click does not send a second request', () async {
    final first = ClinicMutations(
      service,
    ).execute('payment', 'patient', payload);
    await expectLater(
      ClinicMutations(service).execute('payment', 'patient', payload),
      throwsA(isA<NetworkException>()),
    );
    await first;
    expect(ids, hasLength(1));
  });
}
