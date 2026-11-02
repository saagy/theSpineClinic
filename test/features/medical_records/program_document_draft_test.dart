import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/program_document_draft.dart';
import '../../fixtures/workspace_data.dart';

class _User extends CurrentUser {
  @override
  Future<Staff?> build() async => workspaceStaff('senior');
  void replace(Staff? user) => state = AsyncData(user);
}

void main() {
  test(
    'each form has its own draft; profile refresh preserves it and sign-out clears it',
    () async {
      final container = ProviderContainer(overrides: [currentUserProvider.overrideWith(_User.new)]);
      addTearDown(container.dispose);
      await container.read(currentUserProvider.future);
      final first = programDocumentDraftProvider(Object());
      final second = programDocumentDraftProvider(Object());
      final subscription = container.listen(first, (_, _) {});
      addTearDown(subscription.close);
      expect(container.read(first.notifier).remove('doc'), true);
      expect(container.read(first).removedIds, {'doc'});
      expect(container.read(second).removedIds, isEmpty);
      final user = container.read(currentUserProvider.notifier) as _User;
      user.replace(workspaceStaff('senior').copyWith(fullName: 'Updated profile'));
      await container.pump();
      expect(container.read(first).removedIds, {'doc'});
      user.replace(null);
      await container.pump();
      expect(container.read(first).removedIds, isEmpty);
      expect(container.read(first.notifier).remove('doc'), false);
    },
  );

  test('a loss of edit permission resets the draft and prevents further staged removals', () async {
    final container = ProviderContainer(overrides: [currentUserProvider.overrideWith(_User.new)]);
    addTearDown(container.dispose);
    await container.read(currentUserProvider.future);
    final provider = programDocumentDraftProvider(Object());
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    container.read(provider.notifier).remove('doc');
    (container.read(currentUserProvider.notifier) as _User).replace(workspaceStaff('doctor'));
    await container.pump();
    expect(container.read(provider).removedIds, isEmpty);
    expect(container.read(provider.notifier).remove('doc'), false);
  });
}
