import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

part 'package_balance_controller.g.dart';

/// Presentation controller managing the state of manual package balance edits.
@riverpod
class PackageBalanceController extends _$PackageBalanceController {
  @override
  FutureOr<void> build() {
    // Initial state is idle.
  }

  /// Updates a patient's package balance in the database.
  ///
  /// Checks role permissions before proceeding. Invalidates patient detail
  /// and search providers on success.
  Future<Result<void>> updateBalance({
    required Patient patient,
    required int newBalance,
  }) async {
    state = const AsyncValue.loading();

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null || currentUser.role == UserRole.doctor) {
      final error = UnknownException(
        message: AppStrings.editPackageBalanceAccessDenied,
      );
      state = AsyncValue.error(error, StackTrace.current);
      return Result.failure(error);
    }

    final repo = ref.read(patientRepositoryProvider);
    final updatedPatient = patient.copyWith(packageBalance: newBalance);
    final Result<void> result = await repo.updatePatient(updatedPatient);
    if (!ref.mounted) return result;

    state = result.when(
      success: (_) {
        ref.invalidate(patientDetailProvider(patient.id));
        ref.invalidate(patientSearchProvider);
        return const AsyncValue.data(null);
      },
      failure: (error) => AsyncValue.error(error, StackTrace.current),
    );

    return result;
  }
}
