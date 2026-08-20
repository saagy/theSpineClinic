import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_schedule_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/booking_workboard_provider.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_appointments_notifier.dart'
    as patient_tab;
import 'package:spine_clinic_app/features/patient/presentation/patient_list_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

part 'edit_appointment_controller.g.dart';

/// Notifier state class for editing appointment.
@riverpod
class EditAppointmentController extends _$EditAppointmentController {
  @override
  FutureOr<void> build() {}

  /// Updates an appointment and its assigned doctors.
  Future<Result<void>> updateAppointment({
    required Appointment appointment,
    required List<String> doctorIds,
  }) async {
    final user = ref.read(currentUserProvider).value;
    if (user != null && user.role == UserRole.doctor) {
      final canEdit = await ref.read(
        canEditAppointmentProvider(
          appointmentId: appointment.id,
          patientId: appointment.patientId,
        ).future,
      );
      if (!canEdit) {
        return const Result.failure(
          DatabaseException(
            code: 'db/permission-denied',
            message:
                'Doctor cannot edit this appointment outside the active window',
            userMessageKey: 'error_database_permission_denied',
          ),
        );
      }
    }

    final repo = ref.read(appointmentRepositoryProvider);
    final editorId = user?.id;

    final Result<void> updateResult = await repo.updateAppointment(appointment);
    if (updateResult is Failure<void>) return updateResult;

    final Result<void> docResult = await repo.updateAppointmentDoctors(
      appointment.id,
      doctorIds,
      editorId,
    );
    if (docResult is Failure<void>) return docResult;

    if (ref.mounted) _invalidateCaches(appointment.id, appointment.patientId);

    return const Result.success(null);
  }

  /// Deletes an appointment.
  Future<Result<void>> deleteAppointment({
    required String appointmentId,
    required String patientId,
  }) async {
    final repo = ref.read(appointmentRepositoryProvider);

    final Result<void> result = await repo.deleteAppointment(appointmentId);
    if (result is Failure<void>) return result;

    if (ref.mounted) _invalidateCaches(appointmentId, patientId);

    return const Result.success(null);
  }

  void _invalidateCaches(String appointmentId, String patientId) {
    ref.invalidate(todayAppointmentsProvider);
    ref.read(allAppointmentsProvider.notifier).refresh();
    ref.invalidate(patientAppointmentsProvider(patientId));
    ref.invalidate(patient_tab.patientAppointmentsProvider(patientId));
    ref.invalidate(patientDetailProvider(patientId));
    ref.invalidate(futureScheduledAppointmentsCountProvider(patientId));
    ref.invalidate(availablePackageBalanceProvider(patientId));
    for (final AppointmentType type in AppointmentType.values) {
      ref.invalidate(
        futureScheduledAppointmentsCountForTypeProvider((
          patientId: patientId,
          type: type,
        )),
      );
      ref.invalidate(
        availableBalanceForTypeProvider((patientId: patientId, type: type)),
      );
    }
    ref.invalidate(doctorScheduleProvider);
    ref.invalidate(patientListProvider);
    ref.invalidate(singleAppointmentProvider(appointmentId));
    ref.invalidate(appointmentDoctorsProvider(appointmentId));
    ref.invalidate(appointmentDoctorsDetailsProvider(appointmentId));

    // Refresh the receptionist dashboard queues immediately
    ref.read(receptionistAppointmentsProvider.notifier).loadToday();
    ref.read(bookingWorkboardProvider.notifier).refresh();
  }
}
