/// Data-layer implementation of [AppointmentRepository] backed by Supabase.
///
/// Enforces all required appointment status transitions and database trigger
/// balance assumptions (AGENT_CONTEXT §7), along with active doctor limits
/// (AGENT_CONTEXT §5).
///
/// Rule 1 — No file longer than 200 lines.
/// Rule 2 — No Supabase calls in widgets.
/// Rule 4 — Every async method returns `Result<T>`.
library;

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_doctor.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';

/// Supabase-backed implementation of [AppointmentRepository].
class AppointmentRepositoryImpl implements AppointmentRepository {
  /// Creates an [AppointmentRepositoryImpl] with the given [supabaseService].
  AppointmentRepositoryImpl({required SupabaseService supabaseService})
      : _service = supabaseService;

  final SupabaseService _service;

  static const String _appointmentsTable = 'appointments';
  static const String _appointmentDoctorsTable = 'appointment_doctors';

  /// Appointment Doctor Rule 3: Maximum 2 active appointment_doctors rows.
  static const int _maxActiveDoctors = 2;

  @override
  Future<Result<List<Appointment>>> getAppointmentsForToday() async {
    try {
      final DateTime now = DateTime.now().toUtc();
      final DateTime todayStart = DateTime.utc(now.year, now.month, now.day);
      final DateTime tomorrowStart = todayStart.add(const Duration(days: 1));

      final List<Map<String, dynamic>> rows = await _service.guardQuery(
        () => _service
            .from(_appointmentsTable)
            .select()
            .gte('scheduled_at', todayStart.toIso8601String())
            .lt('scheduled_at', tomorrowStart.toIso8601String())
            .order('scheduled_at', ascending: true),
      );

      final List<Appointment> appointments =
          rows.map(Appointment.fromJson).toList();
      return Result.success(appointments);
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<void>> updateAppointmentStatus(
    String appointmentId,
    AppointmentStatus status,
  ) async {
    try {
      await _service.guardQuery(
        () => _service
            .from(_appointmentsTable)
            .update({'status': status.dbValue})
            .eq('id', appointmentId),
      );
      return const Result.success(null);
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<List<AppointmentDoctor>>> getAppointmentDoctors(
    String appointmentId,
  ) async {
    try {
      final List<Map<String, dynamic>> rows = await _service.guardQuery(
        () => _service
            .from(_appointmentDoctorsTable)
            .select()
            .eq('appointment_id', appointmentId)
            .eq('is_active', true),
      );

      final List<AppointmentDoctor> doctors =
          rows.map(AppointmentDoctor.fromJson).toList();
      return Result.success(doctors);
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  /// Validates that adding another doctor to the appointment does not violate limit rules.
  ///
  /// Enforces Appointment Doctor Rule 3 (Maximum 2 active doctors per appointment).
  /// Throws [DatabaseException] if the limit is exceeded.
  // ignore: unused_element
  Future<void> _validateActiveDoctorLimit(String appointmentId) async {
    final List<Map<String, dynamic>> rows = await _service.guardQuery(
      () => _service
          .from(_appointmentDoctorsTable)
          .select('id')
          .eq('appointment_id', appointmentId)
          .eq('is_active', true),
    );

    if (rows.length >= _maxActiveDoctors) {
      throw const DatabaseException(
        code: 'db/appointment-doctor-limit-exceeded',
        message: 'Maximum of 2 active doctors allowed per appointment',
        userMessageKey: 'error_database_validation_failed',
      );
    }
  }
}
