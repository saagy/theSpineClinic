library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';

/// Encapsulates the loop/transaction creation of appointments and assignment of doctors.
abstract final class BookingSubmitHelper {
  /// Walks through the list of slots, creates each appointment, and attaches
  /// each doctor to the created appointment.
  static Future<Result<void>> executeBooking({
    required AppointmentRepository repo,
    required String patientId,
    required AppointmentType type,
    required List<DateTime> slots,
    required TimeOfDay time,
    required String? creatorId,
    required List<Staff> doctors,
    required bool usePackage,
  }) async {
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

      return await repo.createRecurringBookings(
        patientId: patientId,
        type: type,
        slots: scheduledSlots,
        usePackage: usePackage,
        creatorId: creatorId,
        doctorIds: doctorIds,
      );
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }
}
