import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/payments/domain/clinic_package.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';

part 'clinic_settings_controller.g.dart';

/// Controller managing update mutations for the clinic settings packages.
@riverpod
class ClinicSettingsAction extends _$ClinicSettingsAction {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Helper to get current staff ID
  String? _getCurrentStaffId() {
    return ref.read(currentUserProvider).value?.id;
  }

  /// Appends a new clinic package to settings.
  Future<Result<void>> addPackage(ClinicPackage package) async {
    state = const AsyncValue.loading();
    final repo = ref.read(paymentRepositoryProvider);
    final staffId = _getCurrentStaffId();

    if (staffId == null) {
      const err = AuthException(
        code: 'auth/unauthorized',
        message: 'No active staff user session found.',
      );
      state = AsyncValue.error(err, StackTrace.current);
      return const Result.failure(err);
    }

    final currentPackagesAsync = ref.read(clinicPackagesProvider);
    final currentPackages = currentPackagesAsync.value ?? [];
    final updatedList = [...currentPackages, package];

    final result = await repo.updateClinicPackages(updatedList, staffId);
    if (!ref.mounted) return result;

    state = result.when(
      success: (_) {
        ref.invalidate(clinicPackagesProvider);
        return const AsyncValue.data(null);
      },
      failure: (error) => AsyncValue.error(error, StackTrace.current),
    );

    return result;
  }

  /// Modifies an existing clinic package in settings.
  Future<Result<void>> editPackage(int index, ClinicPackage package) async {
    state = const AsyncValue.loading();
    final repo = ref.read(paymentRepositoryProvider);
    final staffId = _getCurrentStaffId();

    if (staffId == null) {
      const err = AuthException(
        code: 'auth/unauthorized',
        message: 'No active staff user session found.',
      );
      state = AsyncValue.error(err, StackTrace.current);
      return const Result.failure(err);
    }

    final currentPackagesAsync = ref.read(clinicPackagesProvider);
    final currentPackages = currentPackagesAsync.value ?? [];
    if (index < 0 || index >= currentPackages.length) {
      const err = UnknownException(message: 'Invalid package index requested.');
      state = AsyncValue.error(err, StackTrace.current);
      return const Result.failure(err);
    }

    final updatedList = [...currentPackages];
    updatedList[index] = package;

    final result = await repo.updateClinicPackages(updatedList, staffId);
    if (!ref.mounted) return result;

    state = result.when(
      success: (_) {
        ref.invalidate(clinicPackagesProvider);
        return const AsyncValue.data(null);
      },
      failure: (error) => AsyncValue.error(error, StackTrace.current),
    );

    return result;
  }

  /// Permanently removes a clinic package from settings.
  Future<Result<void>> deletePackage(int index) async {
    state = const AsyncValue.loading();
    final repo = ref.read(paymentRepositoryProvider);
    final staffId = _getCurrentStaffId();

    if (staffId == null) {
      const err = AuthException(
        code: 'auth/unauthorized',
        message: 'No active staff user session found.',
      );
      state = AsyncValue.error(err, StackTrace.current);
      return const Result.failure(err);
    }

    final currentPackagesAsync = ref.read(clinicPackagesProvider);
    final currentPackages = currentPackagesAsync.value ?? [];
    if (index < 0 || index >= currentPackages.length) {
      const err = UnknownException(message: 'Invalid package index requested.');
      state = AsyncValue.error(err, StackTrace.current);
      return const Result.failure(err);
    }

    final updatedList = [...currentPackages];
    updatedList.removeAt(index);

    final result = await repo.updateClinicPackages(updatedList, staffId);
    if (!ref.mounted) return result;

    state = result.when(
      success: (_) {
        ref.invalidate(clinicPackagesProvider);
        return const AsyncValue.data(null);
      },
      failure: (error) => AsyncValue.error(error, StackTrace.current),
    );

    return result;
  }
}
