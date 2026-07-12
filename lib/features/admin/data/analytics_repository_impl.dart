import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/admin/data/analytics_dtos.dart';
import 'package:spine_clinic_app/features/admin/data/analytics_query_helpers.dart';
import 'package:spine_clinic_app/features/admin/domain/analytics_repository.dart';

/// Supabase-backed implementation of [AnalyticsRepository].
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  AnalyticsRepositoryImpl({required SupabaseService supabaseService})
    : _service = supabaseService;

  final SupabaseService _service;

  // ── Financial ────────────────────────────────────────────────
  @override
  Future<Result<FinancialSummary>> getFinancialSummary({
    required DateTimeRange range,
    String? branchId,
  }) async {
    try {
      final payments = await fetchPayments(_service, range, branchId);
      double total = 0;
      final Map<String, double> byType = <String, double>{};
      final Map<String, double> byBranch = <String, double>{};
      for (final row in payments) {
        final double amt = (row['amount'] as num?)?.toDouble() ?? 0;
        total += amt;
        final String cat = paymentCategory((row['reason'] as String? ?? '').toLowerCase());
        byType[cat] = (byType[cat] ?? 0) + amt;
        final String clinic = extractClinic(row['patient']);
        byBranch[clinic] = (byBranch[clinic] ?? 0) + amt;
      }
      final patients = await _service.guardQuery(() {
        var q = _service.from('patients').select('session_balance, traction_balance, clinic');
        if (branchId != null) q = q.eq('clinic', branchId);
        return q;
      });
      final negative = patients.where((r) {
        final int s = (r['session_balance'] as int?) ?? 0;
        final int t = (r['traction_balance'] as int?) ?? 0;
        return s < 0 || t < 0;
      }).toList();
      int owedSessions = 0;
      int owedTraction = 0;
      for (final r in negative) {
        final int s = (r['session_balance'] as int?) ?? 0;
        final int t = (r['traction_balance'] as int?) ?? 0;
        if (s < 0) owedSessions += s.abs();
        if (t < 0) owedTraction += t.abs();
      }
      final pkgRows = payments.where((r) => ((r['reason'] as String? ?? '').toLowerCase()).contains('package'));
      return Result.success(FinancialSummary(
        totalRevenue: total,
        revenueByPaymentType: byType,
        revenueByBranch: byBranch,
        outstandingBalanceCount: negative.length,
        owedSessions: owedSessions,
        owedTractionSessions: owedTraction,
        packageSalesCount: pkgRows.length,
        packageSalesValue: pkgRows.fold<double>(0, (s, r) => s + ((r['amount'] as num?)?.toDouble() ?? 0)),
      ));
    } on AppException catch (e) {
      return Result.failure(e);
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  // ── Appointments ─────────────────────────────────────────────
  @override
  Future<Result<AppointmentSummary>> getAppointmentSummary({
    required DateTimeRange range,
    String? branchId,
  }) async {
    try {
      final rows = await fetchAppointments(_service, range, branchId);
      final int total = rows.length;
      final Map<String, int> byStatus = <String, int>{};
      final Map<String, int> byDow = <String, int>{for (final d in dayLabels) d: 0};
      for (final row in rows) {
        final String status = row['status'] as String? ?? 'unknown';
        byStatus[status] = (byStatus[status] ?? 0) + 1;
        final String? ts = row['scheduled_at'] as String?;
        if (ts != null) byDow[dayLabels[DateTime.parse(ts).weekday - 1]] = (byDow[dayLabels[DateTime.parse(ts).weekday - 1]] ?? 0) + 1;
      }
      final int completed = byStatus['completed'] ?? 0;
      final int cancelled = byStatus['cancelled'] ?? 0;
      return Result.success(AppointmentSummary(
        totalAppointments: total,
        completionRate: total > 0 ? completed / total : 0,
        cancellationRate: total > 0 ? cancelled / total : 0,
        byStatus: byStatus,
        byDayOfWeek: byDow,
      ));
    } on AppException catch (e) {
      return Result.failure(e);
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  // ── Staff ────────────────────────────────────────────────────
  @override
  Future<Result<StaffSummary>> getStaffSummary({
    required DateTimeRange range,
  }) async {
    try {
      final apptRows = await _service.guardQuery(() => _service
          .from('appointments')
          .select('id, status, scheduled_at, appointment_doctors!inner(doctor_id, is_active, is_replacement, replaced_doctor_id)')
          .gte('scheduled_at', range.start.toIso8601String())
          .lte('scheduled_at', range.end.toIso8601String()));
      
      final docRows = await _service.guardQuery(
        () => _service.from('staff').select('id, full_name, role, is_active'),
      );
      final Map<String, String> docNames = {for (final r in docRows) r['id'] as String: r['full_name'] as String};
      
      final Map<String, Map<String, _DailyAccumulator>> doctorDays = <String, Map<String, _DailyAccumulator>>{};
      for (final r in docRows) {
        if (r['role'] == 'doctor' && r['is_active'] == true) {
          doctorDays[r['id'] as String] = <String, _DailyAccumulator>{};
        }
      }

      for (final appt in apptRows) {
        final String? scheduledStr = appt['scheduled_at'] as String?;
        if (scheduledStr == null) continue;
        final DateTime scheduledDate = DateTime.parse(scheduledStr);
        final String dateKey = scheduledDate.toIso8601String().substring(0, 10);
        final bool isCompleted = (appt['status'] as String?) == 'completed';

        final docsList = (appt['appointment_doctors'] as List<dynamic>?) ?? <dynamic>[];
        for (final doc in docsList) {
          final Map<String, dynamic> dm = doc as Map<String, dynamic>;
          final String doctorId = dm['doctor_id'] as String;
          final bool isActiveAssignment = dm['is_active'] == true;
          final bool isReplacement = dm['is_replacement'] == true;
          final String? replacedId = dm['replaced_doctor_id'] as String?;

          if (isActiveAssignment) {
            final Map<String, _DailyAccumulator> days = doctorDays.putIfAbsent(doctorId, () => <String, _DailyAccumulator>{});
            final _DailyAccumulator acc = days.putIfAbsent(dateKey, () => _DailyAccumulator());
            acc.total += 1;
            if (isCompleted) {
              acc.completed += 1;
            }
          }

          if (isReplacement && replacedId != null) {
            final Map<String, _DailyAccumulator> days = doctorDays.putIfAbsent(replacedId, () => <String, _DailyAccumulator>{});
            final _DailyAccumulator acc = days.putIfAbsent(dateKey, () => _DailyAccumulator());
            acc.isAbsent = true;
            acc.coveringDoctorName = docNames[doctorId] ?? doctorId;
          }
        }
      }

      final List<DoctorPerformance> performanceList = <DoctorPerformance>[];
      final Map<String, int> apptsPerDoc = <String, int>{};
      final Map<String, int> completedPerDoc = <String, int>{};

      doctorDays.forEach((doctorId, daysMap) {
        final String name = docNames[doctorId] ?? doctorId;
        int totalAppts = 0;
        int completedAppts = 0;
        int absenceCount = 0;
        int activeDays = 0;
        final List<DoctorDailyLog> dailyLogs = <DoctorDailyLog>[];

        daysMap.forEach((dateStr, acc) {
          final DateTime dayDate = DateTime.parse(dateStr);
          dailyLogs.add(DoctorDailyLog(
            date: dayDate,
            completedAppointments: acc.completed,
            totalAppointments: acc.total,
            isAbsent: acc.isAbsent,
            coveringDoctorName: acc.coveringDoctorName,
          ));

          if (acc.isAbsent) {
            absenceCount++;
          } else {
            if (acc.total > 0) {
              activeDays++;
              totalAppts += acc.total;
              completedAppts += acc.completed;
            }
          }
        });

        dailyLogs.sort((a, b) => a.date.compareTo(b.date));

        apptsPerDoc[name] = totalAppts;
        completedPerDoc[name] = completedAppts;

        final staffRole = docRows.firstWhere((r) => r['id'] == doctorId, orElse: () => <String, dynamic>{})['role'] as String?;
        if (staffRole == 'doctor') {
          performanceList.add(DoctorPerformance(
            id: doctorId,
            fullName: name,
            totalAppointments: totalAppts,
            completedAppointments: completedAppts,
            absenceCount: absenceCount,
            activeDays: activeDays,
            dailyLogs: dailyLogs,
          ));
        }
      });

      final Map<String, double> ratePerDoc = <String, double>{};
      for (final e in apptsPerDoc.entries) {
        final int cdone = completedPerDoc[e.key] ?? 0;
        ratePerDoc[e.key] = e.value > 0 ? cdone / e.value : 0;
      }
      
      final sorted = apptsPerDoc.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return Result.success(StaffSummary(
        appointmentsPerDoctor: apptsPerDoc,
        completionRatePerDoctor: ratePerDoc,
        topDoctors: sorted.take(5).map((e) => e.key).toList(),
        doctorPerformances: performanceList,
      ));
    } on AppException catch (e) {
      return Result.failure(e);
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  // ── Patients ─────────────────────────────────────────────────
  @override
  Future<Result<PatientSummary>> getPatientSummary({
    required DateTimeRange range,
    String? branchId,
  }) async {
    try {
      final patientRows = await _service.guardQuery(() {
        var q = _service.from('patients').select('id, clinic, created_at');
        if (branchId != null) q = q.eq('clinic', branchId);
        return q;
      });
      int newRegs = 0;
      final Map<String, int> byBranch = <String, int>{};
      final Set<String> preexistingIds = <String>{};
      for (final row in patientRows) {
        byBranch[row['clinic'] as String? ?? 'unknown'] = (byBranch[row['clinic'] as String? ?? 'unknown'] ?? 0) + 1;
        final String? created = row['created_at'] as String?;
        if (created != null) {
          final DateTime cd = DateTime.parse(created);
          if (cd.isAfter(range.start) && cd.isBefore(range.end)) newRegs++;
          if (cd.isBefore(range.start)) preexistingIds.add(row['id'] as String);
        }
      }
      final apptPatients = await _service.guardQuery(() => _service
          .from('appointments').select('patient_id')
          .gte('scheduled_at', range.start.toIso8601String())
          .lte('scheduled_at', range.end.toIso8601String()));
      final Set<String> seenIds = apptPatients.map((a) => a['patient_id'] as String).toSet();
      final int returning = seenIds.where(preexistingIds.contains).length;
      return Result.success(PatientSummary(
        newRegistrations: newRegs,
        totalActivePatients: patientRows.length,
        patientsByBranch: byBranch,
        returningRatio: (returning + (seenIds.length - returning)) > 0
            ? returning / seenIds.length
            : 0,
      ));
    } on AppException catch (e) {
      return Result.failure(e);
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }
}

class _DailyAccumulator {
  int total = 0;
  int completed = 0;
  bool isAbsent = false;
  String? coveringDoctorName;
}
