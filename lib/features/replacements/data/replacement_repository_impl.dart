/// Supabase-backed implementation of [ReplacementRepository].
///
/// Rule 2 — all Supabase calls live here, never in widgets.
/// Rule 5 — no dynamic types; explicit casts on all mappings.
library;

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/replacements/domain/replacement_repository.dart';

/// Implements [ReplacementRepository] against the Supabase backend.
class ReplacementRepositoryImpl implements ReplacementRepository {
  /// Creates a [ReplacementRepositoryImpl].
  ReplacementRepositoryImpl({required SupabaseService supabaseService})
      : _service = supabaseService;

  final SupabaseService _service;

  static const String _replacementsTable = 'doctor_replacements';
  static const String _appointmentsTable = 'appointments';
  static const String _appointmentDoctorsTable = 'appointment_doctors';

  Future<Result<T>> _run<T>(Future<T> Function() action) async {
    try {
      final T res = await _service.guardQuery(action);
      return Result.success(res);
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<String>> createReplacement({
    required String absentDoctorId,
    required String coveringDoctorId,
    required DateTime date,
    required String initiatedBy,
  }) {
    return _run(() async {
      final String dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final Map<String, Object?> row = await _service
          .from(_replacementsTable)
          .insert({
            'absent_doctor_id': absentDoctorId,
            'covering_doctor_id': coveringDoctorId,
            'replacement_date': dateStr,
            'initiated_by': initiatedBy,
          })
          .select('id')
          .single();
      return row['id'] as String;
    });
  }

  @override
  Future<Result<List<AffectedAppointmentItem>>>
      getAffectedAppointments({
    required String absentDoctorId,
    required DateTime date,
  }) {
    return _run(() async {
      final DateTime dayStart =
          DateTime(date.year, date.month, date.day).toUtc();
      final DateTime dayEnd = dayStart.add(const Duration(days: 1));

      // Fetch appointment IDs where the absent doctor is active.
      final List<Map<String, Object?>> adRows = await _service
          .from(_appointmentDoctorsTable)
          .select('appointment_id')
          .eq('doctor_id', absentDoctorId)
          .eq('is_active', true);

      if (adRows.isEmpty) return [];

      final List<String> appointmentIds = adRows
          .map((Map<String, Object?> r) => r['appointment_id'] as String)
          .toList();

      // Fetch appointments on that date matching the IDs.
      final List<Map<String, Object?>> apptRows = await _service
          .from(_appointmentsTable)
          .select('*, patient:patients!patient_id(*)')
          .inFilter('id', appointmentIds)
          .gte('scheduled_at', dayStart.toIso8601String())
          .lt('scheduled_at', dayEnd.toIso8601String())
          .neq('status', 'cancelled')
          .order('scheduled_at', ascending: true);

      final List<AffectedAppointmentItem> items = [];
      for (final Map<String, Object?> row in apptRows) {
        final Map<String, Object?>? patientMap =
            row['patient'] as Map<String, Object?>?;
        if (patientMap == null) continue;

        final Patient patient = Patient.fromJson(
          patientMap.cast<String, dynamic>(),
        );
        final Appointment appointment = Appointment.fromJson(
          (Map<String, Object?>.from(row)..remove('patient'))
              .cast<String, dynamic>(),
        );

        items.add(AffectedAppointmentItem(
          appointment: appointment,
          patientName: patient.fullName,
          patient: patient,
        ));
      }
      return items;
    });
  }

  @override
  Future<Result<int>> applyBulkSwap({
    required List<String> appointmentIds,
    required String absentDoctorId,
    required String coveringDoctorId,
    required String addedBy,
  }) {
    return _run(() async {
      int swapCount = 0;

      for (final String appointmentId in appointmentIds) {
        // 1. Deactivate absent doctor's row.
        await _service
            .from(_appointmentDoctorsTable)
            .update({'is_active': false})
            .eq('appointment_id', appointmentId)
            .eq('doctor_id', absentDoctorId)
            .eq('is_active', true);

        // 2. Insert covering doctor row.
        await _service.from(_appointmentDoctorsTable).insert({
          'appointment_id': appointmentId,
          'doctor_id': coveringDoctorId,
          'is_replacement': true,
          'replaced_doctor_id': absentDoctorId,
          'is_active': true,
          'added_by': addedBy,
        });

        swapCount++;
      }

      return swapCount;
    });
  }

  @override
  Future<Result<bool>> replacementExists({
    required String absentDoctorId,
    required DateTime date,
  }) {
    return _run(() async {
      final String dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final List<Map<String, Object?>> rows = await _service
          .from(_replacementsTable)
          .select('id')
          .eq('absent_doctor_id', absentDoctorId)
          .eq('replacement_date', dateStr);
      return rows.isNotEmpty;
    });
  }

  @override
  Future<Result<void>> deleteExistingReplacement({
    required String absentDoctorId,
    required DateTime date,
  }) {
    return _run(() async {
      final String dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      await _service
          .from(_replacementsTable)
          .delete()
          .eq('absent_doctor_id', absentDoctorId)
          .eq('replacement_date', dateStr);
    });
  }
}
