import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart'
    as appointment_cache;
import 'package:spine_clinic_app/features/appointment/presentation/doctor_schedule_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_appointments_notifier.dart'
    as patient_appointment_tab;
import 'package:spine_clinic_app/features/patient/presentation/patient_list_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

abstract final class AppointmentRefresh {
  static void patientAndDashboards(
    WidgetRef ref, {
    required String patientId,
    String? appointmentId,
  }) {
    ref.invalidate(appointment_cache.todayAppointmentsProvider);
    ref.read(allAppointmentsProvider.notifier).refresh();
    ref.invalidate(appointment_cache.patientAppointmentsProvider(patientId));
    ref.invalidate(
      patient_appointment_tab.patientAppointmentsProvider(patientId),
    );
    ref.invalidate(patientDetailProvider(patientId));
    ref.invalidate(
      appointment_cache.futureScheduledAppointmentsCountProvider(patientId),
    );
    ref.invalidate(
      appointment_cache.availablePackageBalanceProvider(patientId),
    );
    ref.invalidate(doctorScheduleProvider);
    ref.invalidate(patientListProvider);

    for (final AppointmentType type in AppointmentType.values) {
      ref.invalidate(
        appointment_cache.futureScheduledAppointmentsCountForTypeProvider((
          patientId: patientId,
          type: type,
        )),
      );
      ref.invalidate(
        appointment_cache.availableBalanceForTypeProvider((
          patientId: patientId,
          type: type,
        )),
      );
    }

    if (appointmentId != null) {
      ref.invalidate(
        appointment_cache.singleAppointmentProvider(appointmentId),
      );
      ref.invalidate(
        appointment_cache.appointmentDoctorsProvider(appointmentId),
      );
      ref.invalidate(
        appointment_cache.appointmentDoctorsDetailsProvider(appointmentId),
      );
    }

    final receptionist = ref.read(receptionistAppointmentsProvider.notifier);
    unawaited(receptionist.loadToday());
    unawaited(receptionist.loadUpcoming());
  }
}
