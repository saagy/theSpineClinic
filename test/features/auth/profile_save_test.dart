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
  for (final rejectProfile in [true, false]) {
    for (final rejectPassword in [true, false]) {
      test(
        'profile failure=$rejectProfile password failure=$rejectPassword',
        () async {
          final service = _ProfileService(
            rejectProfile: rejectProfile,
            rejectPassword: rejectPassword,
          );
          addTearDown(service.client.dispose);
          final result = await AuthRepositoryImpl(supabaseService: service)
              .updateStaffProfile(
                staff: workspaceStaff(
                  'senior',
                ).copyWith(userId: service.currentUserId),
                newPassword: 'test-password',
              );
          expect(service.passwordWrites, rejectProfile ? 0 : 1);
          expect(result.isSuccess, !rejectProfile && !rejectPassword);
          if (!rejectProfile && rejectPassword) {
            expect(
              result.exceptionOrNull!.userMessageKey,
              'profile_saved_password_unconfirmed',
            );
          }
        },
      );
    }
  }
}
