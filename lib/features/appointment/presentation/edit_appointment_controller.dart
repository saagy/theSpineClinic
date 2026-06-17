import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_detail_controller.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_schedule_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_list_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';

part 'edit_appointment_controller.g.dart';

/// Notifier state class for editing appointment.
@riverpod
class EditAppointmentController extends _$EditAppointmentController {
  @override
  FutureOr<void> build() {
    // Nothing to initialize
  }

  /// Updates an appointment and its assigned doctors.
  Future<Result<void>> updateAppointment({
    required Appointment appointment,
    required List<String> doctorIds,
  }) async {
    state = const AsyncLoading();
    final repo = ref.read(appointmentRepositoryProvider);
    final editorId = ref.read(currentUserProvider).value?.id;

    // 1. Update appointment fields
    final Result<void> updateResult = await repo.updateAppointment(appointment);
    if (updateResult is Failure<void>) {
      state = AsyncError(updateResult.exception, StackTrace.current);
      return updateResult;
    }

    // 2. Update appointment doctor assignments
    final Result<void> docResult = await repo.updateAppointmentDoctors(
      appointment.id,
      doctorIds,
      editorId,
    );
    if (docResult is Failure<void>) {
      state = AsyncError(docResult.exception, StackTrace.current);
      return docResult;
    }

    // 3. Invalidate caches to refresh all screens
    _invalidateCaches(appointment.id, appointment.patientId);

    state = const AsyncData(null);
    return const Result.success(null);
  }

  /// Deletes an appointment.
  Future<Result<void>> deleteAppointment({
    required String appointmentId,
    required String patientId,
  }) async {
    state = const AsyncLoading();
    final repo = ref.read(appointmentRepositoryProvider);

    final Result<void> result = await repo.deleteAppointment(appointmentId);
    if (result is Failure<void>) {
      state = AsyncError(result.exception, StackTrace.current);
      return result;
    }

    _invalidateCaches(appointmentId, patientId);

    state = const AsyncData(null);
    return const Result.success(null);
  }

  void _invalidateCaches(String appointmentId, String patientId) {
    ref.invalidate(todayAppointmentsProvider);
    ref.read(allAppointmentsProvider.notifier).refresh();
    ref.invalidate(patientAppointmentsProvider(patientId));
    ref.invalidate(patientDetailProvider(patientId));
    ref.invalidate(futureScheduledAppointmentsCountProvider(patientId));
    ref.invalidate(availablePackageBalanceProvider(patientId));
    ref.invalidate(doctorScheduleProvider);
    ref.invalidate(patientListProvider);
    ref.invalidate(singleAppointmentProvider(appointmentId));
    ref.invalidate(appointmentDetailControllerProvider(appointmentId));
    ref.invalidate(appointmentDoctorsProvider(appointmentId));
    ref.invalidate(appointmentDoctorsDetailsProvider(appointmentId));
    
    // Refresh the receptionist dashboard queues immediately
    ref.read(receptionistAppointmentsProvider.notifier).loadToday();
    ref.read(receptionistAppointmentsProvider.notifier).loadUpcoming();
  }
}
