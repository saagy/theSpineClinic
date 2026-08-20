import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_replacement_args.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';

/// Helper to load doctor replacement data when accessed via deep-link or refresh.
abstract final class DoctorReplacementLoader {
  static Future<Result<DoctorReplacementArgs>> loadFallback({
    required WidgetRef ref,
    required String? doctorId,
    required DateTime? date,
  }) async {
    if (doctorId == null) {
      return const Result.failure(
        UnknownException(message: AppStrings.errorDatabaseQueryFailed),
      );
    }
    final List<Staff> allDoctors =
        await ref.read(allDoctorsForFilterProvider.future);
    final Staff? absent =
        allDoctors.where((Staff d) => d.id == doctorId).firstOrNull;
    if (absent == null) {
      return const Result.failure(
        UnknownException(message: AppStrings.errorDatabaseQueryFailed),
      );
    }
    final DateTime target = date ?? DateTime.now();
    final DateTime start = DateTime(target.year, target.month, target.day);
    final Result<List<AppointmentWithPatient>> result = await ref
        .read(appointmentRepositoryProvider)
        .getAllAppointments(
          dateFrom: start,
          dateTo: start.add(const Duration(days: 1)),
          doctorId: absent.id,
          clinic: ref.read(activeBranchProvider).dbValue,
          offset: 0,
          limit: 500,
          ascending: true,
        );
    return result.map(
      (List<AppointmentWithPatient> items) => DoctorReplacementArgs(
        absentDoctor: absent,
        availableDoctors:
            allDoctors.where((Staff d) => d.id != absent.id).toList(),
        appointments: items,
        day: start,
      ),
    );
  }
}
