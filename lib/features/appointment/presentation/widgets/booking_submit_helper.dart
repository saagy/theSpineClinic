library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_doctor.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
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
      for (final DateTime slot in slots) {
        final DateTime scheduledAt = DateTime(
          slot.year,
          slot.month,
          slot.day,
          time.hour,
          time.minute,
        ).toUtc();

        final Appointment appt = Appointment(
          id: '',
          patientId: patientId,
          type: type,
          scheduledAt: scheduledAt,
          status: AppointmentStatus.scheduled,
          // Assessments never deduct — force this off as a safety net.
          usePackage: type.affectsPackageBalance ? usePackage : false,
          createdBy: creatorId,
          createdAt: DateTime.now().toUtc(),
        );

        final Result<String> createResult = await repo.createAppointment(appt);

        // Track errors inside callbacks
        Result<void>? errorResult;

        await createResult.when(
          success: (newAppointmentId) async {
            for (final Staff doctor in doctors) {
              final AppointmentDoctor apptDoc = AppointmentDoctor(
                id: '',
                appointmentId: newAppointmentId,
                doctorId: doctor.id,
                isReplacement: false,
                replacedDoctorId: null,
                isActive: true,
                addedBy: creatorId,
                addedAt: DateTime.now().toUtc(),
              );

              final Result<void> docResult = await repo.createAppointmentDoctor(apptDoc);
              docResult.when(
                success: (_) {},
                failure: (err) {
                  errorResult = Result.failure(err);
                },
              );
            }

          },
          failure: (err) {
            errorResult = Result.failure(err);
          },
        );

        if (errorResult != null) {
          return errorResult!;
        }
      }
      return const Result.success(null);
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }
}
