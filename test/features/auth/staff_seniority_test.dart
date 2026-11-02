import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/staff/data/staff_repository.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_form_fields.dart';
import '../../fixtures/staff_workspace.dart';
import '../../fixtures/test_supabase_service.dart';

void main() {
  test('creation and promotion/demotion send senior status atomically', () async {
    final requests = <http.Request>[];
    final service = TestSupabaseService((request) async {
      requests.add(request);
      return http.Response('null', 200);
    });
    addTearDown(service.client.dispose);
    final repo = StaffRepositoryImpl(supabaseService: service);
    await repo.createStaff(
      fullName: 'Senior',
      email: 'senior@example.invalid',
      role: UserRole.doctor,
      password: 'test-password',
      canManagePayments: false,
      isSenior: true,
    );
    expect(requests.single.url.path, endsWith('/rpc/create_staff_account'));
    expect((jsonDecode(requests.single.body) as Map<String, dynamic>)['new_is_senior'], isTrue);
    requests.clear();
    for (final senior in [true, false]) {
      await repo.updateStaff(
        staff: staffRoster[1].copyWith(isSenior: senior),
        newPassword: 'changed-password',
      );
      expect(requests.single.url.path, endsWith('/rpc/update_staff_account'));
      final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect((body['profile'] as Map<String, dynamic>)['is_senior'], senior);
      expect(body['new_password'], 'changed-password');
      requests.clear();
    }
    await repo.updateStaff(
      staff: staffRoster[1].copyWith(role: UserRole.receptionist, isSenior: true),
    );
    final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
    expect((body['profile'] as Map<String, dynamic>)['is_senior'], isFalse);
  });

  testWidgets('doctor access supports senior promotion/demotion, creation and role changes', (
    tester,
  ) async {
    final key = GlobalKey<FormBuilderState>();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FormBuilder(
                key: key,
                child: StaffFormFields(
                  enabled: true,
                  isSelf: false,
                  formKey: key,
                  staff: staffRoster[1].copyWith(isSenior: true),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(key.currentState!.fields['is_senior']!.value, isTrue);
    await tester.ensureVisible(find.text(AppStrings.seniorDoctor));
    await tester.tap(find.text(AppStrings.seniorDoctor));
    await tester.pumpAndSettle();
    expect(key.currentState!.fields['is_senior']!.value, isFalse);
    key.currentState!.fields['role']!.didChange(UserRole.receptionist);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.seniorDoctor), findsNothing);
    key.currentState!.fields['role']!.didChange(UserRole.doctor);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.seniorDoctor), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
