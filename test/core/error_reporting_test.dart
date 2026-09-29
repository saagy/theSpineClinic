import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:spine_clinic_app/core/errors/app_exception.dart';

void main() {
  test(
    'normalizing an application error twice retains its type and identity',
    () {
      const original = NetworkException(
        code: 'network/timeout',
        message: 'Timeout',
      );
      expect(AppException.fromSupabaseException(original), same(original));
    },
  );
  test(
    'duplicate registration is expected, other unique constraints remain DB errors',
    () {
      const duplicate = supabase.PostgrestException(
        code: '23505',
        message: 'Duplicate',
      );
      final result = AppException.fromSupabaseException(
        duplicate,
        operation: 'register_doctor_application',
      );
      expect(result.code, 'auth/user-already-exists');
      expect(
        AppException.fromSupabaseException(duplicate),
        isA<DatabaseException>(),
      );
    },
  );
  test(
    'unexpected errors keep original stack and safe operation tags',
    () async {
      final captured = Completer<SentryEvent>();
      await Sentry.init((options) {
        options.dsn = 'https://01234567890123456789012345678901@example.test/1';
        options.beforeSend = (event, hint) {
          captured.complete(event);
          return null; // Never transmit test events.
        };
      });
      addTearDown(Sentry.close);
      AppException.fromSupabaseException(
        const supabase.FunctionException(
          status: 500,
          details: {'error': 'private filename'},
        ),
        stackTrace: StackTrace.fromString(
          '#0 originalOperation (package:spine_clinic_app/test.dart:12:3)',
        ),
        operation: 'document-storage',
      );
      final event = await captured.future.timeout(const Duration(seconds: 5));
      expect(event.tags?['operation'], 'document-storage');
      expect(event.tags?['http_status'], '500');
      expect(event.toJson().toString(), contains('originalOperation'));
      expect(event.toJson().toString(), isNot(contains('private filename')));
    },
  );
}
