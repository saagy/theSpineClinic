import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/auth_repository.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';

class _Repository implements AuthRepository {
  _Repository(this.outcome);
  final Result<void> outcome;
  final user = Staff(
    id: 'test-staff',
    fullName: 'Test staff',
    email: 'test@example.test',
    role: UserRole.doctor,
    createdAt: DateTime(2026),
  );
  @override
  bool get isAuthenticated => true;
  @override
  Future<Result<Staff?>> getCurrentUserStaffProfile() async =>
      Result.success(user);
  @override
  Future<Result<void>> signOut() async => outcome;
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('failed logout preserves the session and reports failure', () async {
    final repo = _Repository(
      const Result.failure(
        NetworkException(code: 'network/offline', message: 'Offline'),
      ),
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    await container.read(currentUserProvider.future);
    expect(
      await container.read(currentUserProvider.notifier).logout(),
      isA<Failure<void>>(),
    );
    expect(container.read(currentUserProvider).value, repo.user);
  });
  test('successful logout clears the session', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _Repository(const Result.success(null)),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(currentUserProvider.future);
    expect(
      await container.read(currentUserProvider.notifier).logout(),
      isA<Success<void>>(),
    );
    expect(container.read(currentUserProvider).value, isNull);
  });
}
