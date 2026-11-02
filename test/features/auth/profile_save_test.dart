import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/auth/data/auth_repository_impl.dart';
import '../../fixtures/test_supabase_service.dart';
import '../../fixtures/workspace_data.dart';

class _ProfileService extends TestSupabaseService {
  _ProfileService({required this.rejectProfile, required this.rejectPassword})
    : super(
        (request) async => http.Response(
          jsonEncode(
            rejectProfile
                ? {'code': '42501', 'message': 'Denied'}
                : {'id': 'staff-fixture'},
          ),
          rejectProfile ? 403 : 200,
          headers: {'content-type': 'application/json'},
        ),
      );
  final bool rejectProfile, rejectPassword;
  int passwordWrites = 0;
  @override
  Future<void> updatePassword(String password) async {
    passwordWrites++;
    if (rejectPassword) {
      throw const NetworkException(
        code: 'network/timeout',
        message: 'Lost response',
      );
    }
  }
}

void main() {
  for (final bool rejectPassword in [true, false]) {
    test(
      'standalone password failure=$rejectPassword makes no profile write',
      () async {
        final service = _ProfileService(
          rejectProfile: true,
          rejectPassword: rejectPassword,
        );
        addTearDown(service.client.dispose);
        final result = await AuthRepositoryImpl(
          supabaseService: service,
        ).changeOwnPassword('standalone-password');
        expect(service.passwordWrites, 1);
        expect(result.isSuccess, !rejectPassword);
        if (rejectPassword) {
          expect(result.exceptionOrNull, isA<NetworkException>());
        }
      },
    );
  }
  for (final rejectProfile in [true, false]) {
    test('profile failure=$rejectProfile never changes password', () async {
      final service = _ProfileService(
        rejectProfile: rejectProfile,
        rejectPassword: true,
      );
      addTearDown(service.client.dispose);
      final result = await AuthRepositoryImpl(supabaseService: service)
          .updateStaffProfile(
            staff: workspaceStaff(
              'senior',
            ).copyWith(userId: service.currentUserId),
          );
      expect(service.passwordWrites, 0);
      expect(result.isSuccess, !rejectProfile);
    });
  }
}
