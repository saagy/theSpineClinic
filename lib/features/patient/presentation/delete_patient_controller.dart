import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/booking_workboard_provider.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_list_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

part 'delete_patient_controller.g.dart';

@Riverpod(keepAlive: true)
class DeletePatientController extends _$DeletePatientController {
  @override
  FutureOr<void> build() {}

  Future<Result<void>> deletePatient(String patientId) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null || !user.isActive) {
      return const Result.failure(
        AuthException(code: 'auth/unauthorized', message: 'Must be logged in to delete patients.'),
      );
    }
    if (user.role != UserRole.superAdmin && user.role != UserRole.receptionist && !user.isSeniorDoctor) {
      return const Result.failure(
        AuthException(
          code: 'security/permission-denied',
          message: 'Only super admins, receptionists, and senior doctors can delete patients.',
        ),
      );
    }

    state = const AsyncLoading();
    final repo = ref.read(patientRepositoryProvider);
    final empty = await repo.isPatientEmpty(patientId);
    if (empty is Failure<bool>) {
      state = AsyncError(empty.exception, StackTrace.current);
      return Result.failure(empty.exception);
    }
    if (empty is! Success<bool> || !empty.data) {
      const error = DatabaseException(
        code: 'db/patient-not-empty',
        message: 'Only empty patient records can be deleted.',
        userMessageKey: 'error_patient_not_empty',
      );
      state = AsyncError(error, StackTrace.current);
      return const Result.failure(error);
    }
    final result = await repo.deletePatient(patientId);

    if (result is Failure<void>) {
      state = AsyncError(result.exception, StackTrace.current);
      return result;
    }

    ref.invalidate(patientDetailProvider(patientId));
    ref.invalidate(patientSearchProvider);
    ref.read(patientListProvider.notifier).refresh();
    ref.invalidate(todayAppointmentsProvider);
    ref.read(receptionistAppointmentsProvider.notifier).loadToday();
    ref.read(bookingWorkboardProvider.notifier).refresh();

    state = const AsyncData(null);
    return const Result.success(null);
  }
}
