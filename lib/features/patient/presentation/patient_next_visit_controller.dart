/// Riverpod controller managing patient follow-up date mutations
/// from the patient detail screen.
///
/// Source-of-truth for `patients.next_visit_date`. The canonical write
/// surface lives here (called from the patient Info tab) instead of
/// from the appointment detail screen, where the destructive "clear"
/// action could be misread as cancelling the appointment itself.
///
/// All mutations invalidate `patientDetailProvider` and refresh
/// `bookingWorkboardProvider` so the booking workboard's Due list
/// stays in sync.
///
/// Rule 3 — Riverpod state management.
/// Rule 4 — repository calls return [Result<T>].
/// Rule 25 — all state mutations go through [PatientNextVisitState.copyWith].
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/presentation/booking_workboard_provider.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_repository.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

part 'patient_next_visit_controller.g.dart';

/// Mutable state for the [PatientNextVisitController].
class PatientNextVisitState {
  /// Creates an initial [PatientNextVisitState].
  const PatientNextVisitState({
    this.isMutating = false,
    this.error,
    this.lastActionSuccess = false,
  });

  /// Whether a set/clear mutation is currently in flight.
  final bool isMutating;

  /// Last error from a mutation, ready for surface display.
  final AppException? error;

  /// Whether the last mutation succeeded; cleared on next mutation.
  final bool lastActionSuccess;

  /// Returns a new state with the supplied fields replaced.
  PatientNextVisitState copyWith({
    bool? isMutating,
    AppException? error,
    bool? lastActionSuccess,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return PatientNextVisitState(
      isMutating: isMutating ?? this.isMutating,
      error: clearError ? null : (error ?? this.error),
      lastActionSuccess: clearSuccess
          ? false
          : (lastActionSuccess ?? this.lastActionSuccess),
    );
  }
}

/// Controller backing the patient detail's tappable Next-visit stat.
@riverpod
class PatientNextVisitController extends _$PatientNextVisitController {
  @override
  PatientNextVisitState build() => const PatientNextVisitState();

  /// Sets the follow-up date for a patient. Pass [date] = null to clear.
  Future<Result<void>> setNextVisit(String patientId, DateTime? date) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null ||
        !user.isActive ||
        (user.role != UserRole.receptionist &&
            user.role != UserRole.superAdmin)) {
      return Result.failure(
        const DatabaseException(
          code: 'db/permission-denied',
          message: 'Access denied.',
          userMessageKey: 'error_database_permission_denied',
        ),
      );
    }
    state = state.copyWith(
      isMutating: true,
      clearError: true,
      clearSuccess: true,
    );
    final PatientRepository repo = ref.read(patientRepositoryProvider);
    final Result<void> result = await repo.updateNextVisitDate(
      patientId,
      date,
    );
    if (!ref.mounted) return result;
    switch (result) {
      case Success<void>():
        await _refreshCaches(patientId);
        if (ref.mounted) {
          state = state.copyWith(
            isMutating: false,
            lastActionSuccess: true,
          );
        }
      case Failure<void>(:final exception):
        state = state.copyWith(
          isMutating: false,
          error: exception,
        );
    }
    return result;
  }

  /// Convenience wrapper that clears the follow-up date.
  Future<Result<void>> clearNextVisit(String patientId) {
    return setNextVisit(patientId, null);
  }

  Future<void> _refreshCaches(String patientId) async {
    ref.invalidate(patientDetailProvider(patientId));
    await ref.read(bookingWorkboardProvider.notifier).refresh();
  }
}
