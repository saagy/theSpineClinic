library;

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'appointment_providers.dart';
import 'pending_booking_provider.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';

part 'booking_controller.g.dart';

@Riverpod(keepAlive: true)
class BookingController extends _$BookingController {
  @override
  FutureOr<void> build() {}

  /// Both parts of a bundle share one atomic, retryable database request.
  Future<Result<void>> executeBooking({
    required String patientId,
    required AppointmentType type,
    required List<DateTime> slots,
    required TimeOfDay time,
    required List<Staff> doctors,
    required bool usePackage,
    DateTime? expectedNextVisitDate,
    AppointmentType? companionType,
    TimeOfDay? companionTime,
    List<Staff> companionDoctors = const [],
  }) async {
    final Staff? creator = ref.read(currentUserProvider).value;
    if (creator == null ||
        !creator.isActive ||
        (creator.role == UserRole.doctor && !creator.isSeniorDoctor)) {
      return const Result.failure(
        AuthException(
          code: 'security/permission-denied',
          message: 'Booking permission denied.',
          userMessageKey: 'error_database_permission_denied',
        ),
      );
    }
    try {
      final List<DateTime> scheduledSlots = slots.map((slot) {
        return DateTime(
          slot.year,
          slot.month,
          slot.day,
          time.hour,
          time.minute,
        );
      }).toList();

      final List<String> doctorIds = doctors.map((d) => d.id).toList();

      return await ref
          .read(appointmentRepositoryProvider)
          .createRecurringBookings(
            patientId: patientId,
            type: type,
            slots: scheduledSlots,
            usePackage: usePackage,
            creatorId: creator.id,
            doctorIds: doctorIds,
            expectedNextVisitDate: expectedNextVisitDate,
            companion: companionType == null || companionTime == null
                ? null
                : BookingCompanion(
                    type: companionType,
                    slots: slots
                        .map(
                          (slot) => DateTime(
                            slot.year,
                            slot.month,
                            slot.day,
                            companionTime.hour,
                            companionTime.minute,
                          ),
                        )
                        .toList(),
                    doctorIds: companionDoctors
                        .map((doctor) => doctor.id)
                        .toList(),
                  ),
          );
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    } finally {
      if (ref.mounted) ref.invalidate(pendingBookingProvider(patientId));
    }
  }
}
