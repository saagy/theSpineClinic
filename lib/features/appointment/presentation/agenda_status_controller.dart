import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart'
    as cache;
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_schedule_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/booking_workboard_provider.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_detail_controller.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/doctor_history_provider.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_appointments_notifier.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_list_providers.dart';

part 'agenda_status_controller.g.dart';

class AgendaStatusState {
  const AgendaStatusState({this.pending = false});
  final bool pending;
  AgendaStatusState copyWith({bool? pending}) =>
      AgendaStatusState(pending: pending ?? this.pending);
}

/// One in-flight mutation per appointment, shared by row and menu.
@Riverpod(keepAlive: true)
class AgendaStatusController extends _$AgendaStatusController {
  @override
  AgendaStatusState build(String appointmentId) => const AgendaStatusState();

  Future<Result<void>?> update(String patientId, AppointmentStatus status) async {
    if (state.pending) return null;
    state = state.copyWith(pending: true);
    try {
      final user = ref.read(currentUserProvider).value;
      final allowedRole =
          user?.role == UserRole.doctor ||
          user?.role == UserRole.receptionist ||
          user?.role == UserRole.superAdmin;
      if (user?.isActive != true ||
          !allowedRole ||
          !await ref.read(
            cache
                .canAccessAppointmentProvider(appointmentId: appointmentId, patientId: patientId)
                .future,
          ) ||
          ref.read(currentUserProvider).value?.id != user?.id) {
        return const Failure(
          DatabaseException(
            code: 'db/permission-denied',
            message: 'Appointment access denied',
            userMessageKey: 'error_database_permission_denied',
          ),
        );
      }
      final result = await ref
          .read(cache.appointmentRepositoryProvider)
          .updateAppointmentStatus(appointmentId, status);
      if (result is Success<void>) _refresh(patientId, status);
      return result;
    } catch (error) {
      return Failure(AppException.fromSupabaseException(error));
    } finally {
      state = state.copyWith(pending: false);
    }
  }

  void _refresh(String patientId, AppointmentStatus status) {
    ref.read(receptionistAppointmentsProvider.notifier).changeStatus(appointmentId, status);
    ref.read(doctorScheduleProvider.notifier).changeStatus(appointmentId, status);
    ref.read(allAppointmentsProvider.notifier).updateStatus(appointmentId, status);
    ref.read(patientAppointmentsProvider(patientId).notifier).changeStatus(appointmentId, status);
    ref.invalidate(doctorHistoryProvider);
    ref.invalidate(patientDetailProvider(patientId));
    ref.invalidate(patientListProvider);
    ref.invalidate(cache.todayAppointmentsProvider);
    ref.invalidate(cache.patientAppointmentsProvider(patientId));
    ref.invalidate(cache.singleAppointmentProvider(appointmentId));
    ref.invalidate(appointmentDetailControllerProvider(appointmentId));
    ref.invalidate(cache.futureScheduledAppointmentsCountProvider(patientId));
    ref.invalidate(cache.availablePackageBalanceProvider(patientId));
    for (final type in AppointmentType.values) {
      ref.invalidate(
        cache.futureScheduledAppointmentsCountForTypeProvider((patientId: patientId, type: type)),
      );
      ref.invalidate(cache.availableBalanceForTypeProvider((patientId: patientId, type: type)));
    }
    ref.read(bookingWorkboardProvider.notifier).changeStatus(appointmentId, status);
  }
}
