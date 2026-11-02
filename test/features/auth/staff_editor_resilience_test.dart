import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_management_controller.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import '../../fixtures/staff_editor_harness.dart';
import '../../fixtures/staff_workspace.dart';

void main() {
  testWidgets(
    'resizing and role changes preserve contact, branch and permission drafts',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = StaffEditorRepository();
      await pumpStaffEditor(tester, repo);
      final form = tester.state<FormBuilderState>(find.byType(FormBuilder));
      final emailState = form.fields['email'];
      form.fields['is_senior']!.didChange(true);
      form.fields['role']!.didChange(UserRole.receptionist);
      await tester.pumpAndSettle();
      form.fields['role']!.didChange(UserRole.doctor);
      await tester.pumpAndSettle();
      expect(form.fields['is_senior']!.value, isTrue);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      form.fields['email']!.didChange('draft@example.invalid');
      form.fields['phone']!.didChange('01011112222');
      form.fields['role']!.didChange(UserRole.receptionist);
      await tester.pumpAndSettle();
      form.fields['branch']!.didChange(ClinicLocation.values.last);
      form.fields['can_manage_payments']!.didChange(true);
      for (final double width in [390, 840, 1440]) {
        tester.view.physicalSize = Size(width, 900);
        await tester.pumpAndSettle();
        expect(identical(form.fields['email'], emailState), isTrue);
        expect(form.fields['email']!.value, 'draft@example.invalid');
        expect(form.fields['phone']!.value, '01011112222');
        expect(form.fields['role']!.value, UserRole.receptionist);
        expect(form.fields['branch']!.value, ClinicLocation.values.last);
        expect(form.fields['can_manage_payments']!.value, isTrue);
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.text(AppStrings.saveChanges));
      await tester.pumpAndSettle();
      expect(repo.submitted!.canManagePayments, isTrue);
      expect(repo.submitted!.isSenior, isFalse);
    },
  );

  testWidgets(
    'inactive account activation is staged and preserves cancellation semantics',
    (tester) async {
      final repo = StaffEditorRepository();
      await pumpStaffEditor(tester, repo, staff: staffRoster[3]);
      await tester.ensureVisible(find.text(AppStrings.activateOnSave));
      await tester.tap(find.text(AppStrings.activateOnSave));
      await tester.pump();
      expect(repo.writes, 0);
      await tester.tap(find.text(AppStrings.saveChanges));
      await tester.pumpAndSettle();
      expect(repo.submitted!.isActive, isTrue);
      expect(repo.submitted!.deactivatedAt, isNull);
      expect(repo.countCalls, 0);
    },
  );

  testWidgets('creation retains required fields and senior doctor access', (
    tester,
  ) async {
    final repo = StaffEditorRepository();
    await pumpStaffEditor(tester, repo, create: true);
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.addStaff));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.fullNameRequired), findsOneWidget);
    expect(repo.writes, 0);
    final form = tester.state<FormBuilderState>(find.byType(FormBuilder));
    form.fields['full_name']!.didChange('New Doctor');
    form.fields['email']!.didChange('new@example.invalid');
    form.fields['role']!.didChange(UserRole.doctor);
    await tester.pumpAndSettle();
    form.fields['is_senior']!.didChange(true);
    form.fields['password']!.didChange('test-password');
    form.fields['confirm_password']!.didChange('test-password');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.addStaff));
    await tester.pumpAndSettle();
    expect(repo.writes, 1);
    expect(repo.submitted!.isSenior, isTrue);
  });

  for (final role in UserRole.values) {
    test('mutation checks active admin permission for $role', () async {
      final repo = StaffEditorRepository();
      final actor = staffAdmin.copyWith(
        role: role,
        isActive: role != UserRole.superAdmin,
      );
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(() => StaffEditorUser(actor)),
          staffRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      await container.read(currentUserProvider.future);
      final result = await container
          .read(staffFormControllerProvider.notifier)
          .updateStaff(staff: staffRoster[1]);
      expect(result.isFailure, isTrue);
      expect(repo.writes, 0);
    });
  }

  test(
    'self role/status protections and unobserved in-flight controller survive',
    () async {
      final repo = StaffEditorRepository()..pending = Completer<Result<void>>();
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(() => StaffEditorUser(staffAdmin)),
          staffRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      await container.read(currentUserProvider.future);
      final controller = container.read(staffFormControllerProvider.notifier);
      expect(
        (await controller.updateStaff(
          staff: staffAdmin.copyWith(isActive: false),
        )).isFailure,
        isTrue,
      );
      expect(
        (await controller.updateStaff(
          staff: staffAdmin.copyWith(role: UserRole.doctor),
        )).isFailure,
        isTrue,
      );
      final Future<Result<void>> first = controller.updateStaff(
        staff: staffRoster[1],
      );
      await container.pump();
      expect(container.read(staffFormControllerProvider).isLoading, isTrue);
      expect(
        (await controller.updateStaff(staff: staffRoster[1])).isFailure,
        isTrue,
      );
      expect(repo.writes, 1);
      repo.pending!.complete(const Result.success(null));
      expect((await first).isSuccess, isTrue);
      expect(container.read(staffFormControllerProvider).isLoading, isFalse);
    },
  );
}
