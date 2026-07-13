import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/admin/data/analytics_dtos.dart';
import 'package:spine_clinic_app/features/admin/data/analytics_query_helpers.dart';

bool isAttendanceEligible(Map<String, dynamic> row, DateTime now) {
  final String? scheduled = row['scheduled_at'] as String?;
  return scheduled != null &&
      !DateTime.parse(scheduled).isAfter(now) &&
      row['status'] != 'cancelled';
}

Future<Result<AppointmentSummary>> fetchAppointmentSummary(
  SupabaseService service,
  DateTimeRange range,
  String? branchId,
) async {
  try {
    final List<Map<String, dynamic>> rows = await fetchAppointments(
      service,
      range,
      branchId,
    );
    final Map<String, int> byStatus = <String, int>{};
    final Map<String, int> byDay = <String, int>{
      for (final String day in dayLabels) day: 0,
    };
    int eligible = 0;
    int checkedIn = 0;
    final DateTime now = DateTime.now();
    for (final Map<String, dynamic> row in rows) {
      final String status = row['status'] as String? ?? 'unknown';
      byStatus[status] = (byStatus[status] ?? 0) + 1;
      final String? scheduled = row['scheduled_at'] as String?;
      if (scheduled != null) {
        final DateTime date = DateTime.parse(scheduled);
        byDay[dayLabels[date.weekday - 1]] =
            (byDay[dayLabels[date.weekday - 1]] ?? 0) + 1;
      }
      if (isAttendanceEligible(row, now)) {
        eligible++;
        if (status == 'checked_in') checkedIn++;
      }
    }
    final int cancelled = byStatus['cancelled'] ?? 0;
    return Result.success(
      AppointmentSummary(
        totalAppointments: rows.length,
        attendanceRate: eligible == 0 ? 0 : checkedIn / eligible,
        cancellationRate: rows.isEmpty ? 0 : cancelled / rows.length,
        byStatus: byStatus,
        byDayOfWeek: byDay,
      ),
    );
  } on AppException catch (error) {
    return Result.failure(error);
  } on Exception catch (error) {
    return Result.failure(AppException.fromSupabaseException(error));
  }
}

Future<Result<StaffSummary>> fetchStaffSummary(
  SupabaseService service,
  DateTimeRange range,
) async {
  try {
    final List<Map<String, dynamic>> appointments = await service.guardQuery(
      () => service
          .from('appointments')
          .select(
            'id, status, scheduled_at, '
            'appointment_doctors!inner(doctor_id, is_active)',
          )
          .gte('scheduled_at', range.start.toIso8601String())
          .lte('scheduled_at', range.end.toIso8601String()),
    );
    final List<Map<String, dynamic>> doctors = await service.guardQuery(
      () => service.from('staff').select('id, full_name, role'),
    );
    final Map<String, String> names = <String, String>{
      for (final Map<String, dynamic> row in doctors)
        row['id'] as String: row['full_name'] as String,
    };
    final Map<String, String?> roles = <String, String?>{
      for (final Map<String, dynamic> row in doctors)
        row['id'] as String: row['role'] as String?,
    };
    final Map<String, Map<String, _DailyAttendance>> doctorDays =
        <String, Map<String, _DailyAttendance>>{};
    final DateTime now = DateTime.now();
    for (final Map<String, dynamic> appointment in appointments) {
      if (!isAttendanceEligible(appointment, now)) continue;
      final DateTime date = DateTime.parse(
        appointment['scheduled_at'] as String,
      );
      final String day = date.toIso8601String().substring(0, 10);
      final bool checkedIn = appointment['status'] == 'checked_in';
      final List<Object?> assignments =
          appointment['appointment_doctors'] as List<Object?>? ?? <Object?>[];
      for (final Object? assignment in assignments) {
        final Map<String, dynamic> row = assignment! as Map<String, dynamic>;
        if (row['is_active'] != true) continue;
        final String doctorId = row['doctor_id'] as String;
        final _DailyAttendance attendance = doctorDays
            .putIfAbsent(doctorId, () => <String, _DailyAttendance>{})
            .putIfAbsent(day, _DailyAttendance.new);
        attendance.eligible++;
        if (checkedIn) attendance.checkedIn++;
      }
    }
    final Map<String, int> appointmentsPerDoctor = <String, int>{};
    final Map<String, double> rates = <String, double>{};
    final List<DoctorPerformance> performances = <DoctorPerformance>[];
    doctorDays.forEach((String doctorId, Map<String, _DailyAttendance> days) {
      if (roles[doctorId] != 'doctor') return;
      final String name = names[doctorId] ?? doctorId;
      int eligible = 0;
      int checkedIn = 0;
      final List<DoctorDailyLog> logs = days.entries.map((entry) {
        eligible += entry.value.eligible;
        checkedIn += entry.value.checkedIn;
        return DoctorDailyLog(
          date: DateTime.parse(entry.key),
          checkedInAppointments: entry.value.checkedIn,
          eligibleAppointments: entry.value.eligible,
        );
      }).toList()..sort((a, b) => a.date.compareTo(b.date));
      appointmentsPerDoctor[name] = eligible;
      rates[name] = eligible == 0 ? 0 : checkedIn / eligible;
      performances.add(
        DoctorPerformance(
          id: doctorId,
          fullName: name,
          eligibleAppointments: eligible,
          checkedInAppointments: checkedIn,
          activeDays: days.length,
          dailyLogs: logs,
        ),
      );
    });
    final List<MapEntry<String, int>> sorted =
        appointmentsPerDoctor.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return Result.success(
      StaffSummary(
        appointmentsPerDoctor: appointmentsPerDoctor,
        attendanceRatePerDoctor: rates,
        topDoctors: sorted.take(5).map((entry) => entry.key).toList(),
        doctorPerformances: performances,
      ),
    );
  } on AppException catch (error) {
    return Result.failure(error);
  } on Exception catch (error) {
    return Result.failure(AppException.fromSupabaseException(error));
  }
}

class _DailyAttendance {
  int eligible = 0;
  int checkedIn = 0;
}
