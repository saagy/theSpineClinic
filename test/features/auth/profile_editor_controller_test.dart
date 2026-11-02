import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/profile_editor_controller.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import '../../fixtures/profile_editor_harness.dart';

void main() {
  for (final UserRole role in UserRole.values) {
    test(
      '$role edits only contact fields and preserves current privileges',
      () async {
        final repo = ProfileEditorRepository();
        repo.user = repo.user!.copyWith(
          role: role,
          isSenior: true,
          canManagePayments: true,
          branch: ClinicLocation.tagamoa,
        );
        final container = ProviderContainer(
          overrides: [authRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);
        await container.read(currentUserProvider.future);
        final controller = container.read(
          profileEditorControllerProvider(repo.user!.id).notifier,
        );
        expect(
          await controller.saveDetails(
            fullName: ' New name ',
            email: ' new@example.test ',
            phone: ' ',
          ),
          isTrue,
        );
        expect(repo.savedProfile!.fullName, 'New name');
        expect(repo.savedProfile!.email, 'new@example.test');
        expect(repo.savedProfile!.phone, isNull);
        expect(repo.savedProfile!.role, role);
        expect(repo.savedProfile!.isSenior, isTrue);
        expect(repo.savedProfile!.canManagePayments, isTrue);
        expect(repo.savedProfile!.branch, ClinicLocation.tagamoa);
        expect(repo.passwordWrites, 0);
      },
    );
  }

  for (final bool active in [true, false]) {
    test(
      'blocks another account and inactive account active=$active',
      () async {
        final repo = ProfileEditorRepository();
        repo.user = repo.user!.copyWith(isActive: active);
        final container = ProviderContainer(
          overrides: [authRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);
        await container.read(currentUserProvider.future);
        final provider = profileEditorControllerProvider(
          active ? 'another-account' : repo.user!.id,
          passwordOnly: true,
        );
        expect(
          await container
              .read(provider.notifier)
              .changePassword('new-password'),
          isFalse,
        );
        expect(repo.passwordWrites, 0);
        expect(
          container.read(provider).errorMessage,
          AppStrings.errorDatabasePermissionDenied,
        );
      },
    );
  }

  test(
    'unobserved mutation survives disposal sweeps and rejects duplicates',
    () async {
      final repo = ProfileEditorRepository()
        ..pendingWrite = Completer<Result<void>>();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      await container.read(currentUserProvider.future);
      final provider = profileEditorControllerProvider(
        repo.user!.id,
        passwordOnly: true,
      );
      final controller = container.read(provider.notifier);
      final Future<bool> first = controller.changePassword('test-password');
      await container.pump();
      expect(container.read(provider).isSaving, isTrue);
      expect(await controller.changePassword('duplicate-password'), isFalse);
      expect(repo.passwordWrites, 1);
      repo.pendingWrite!.complete(const Result.success(null));
      expect(await first, isTrue);
      expect(container.read(provider).isSaving, isFalse);
      expect(repo.profileWrites, 0);
    },
  );

  test('copyWith retains fields unless explicitly cleared', () {
    const state = ProfileEditorState(errorMessage: 'Retain this failure');
    expect(state.copyWith(isSaving: true).errorMessage, state.errorMessage);
    expect(state.copyWith(clearError: true).errorMessage, isNull);
  });
}
