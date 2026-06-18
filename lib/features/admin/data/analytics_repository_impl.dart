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
        var q = _service.from('patients').select('package_balance, clinic');
        if (branchId != null) q = q.eq('clinic', branchId);
        return q;
      });
      final negative = patients.where((r) => ((r['package_balance'] as int?) ?? 0) < 0).toList();
      final double outstandingTotal = negative.fold<double>(0, (s, r) => s + ((r['package_balance'] as int?) ?? 0));
      final pkgRows = payments.where((r) => ((r['reason'] as String? ?? '').toLowerCase()).contains('package'));
      return Result.success(FinancialSummary(
        totalRevenue: total,
        revenueByPaymentType: byType,
        revenueByBranch: byBranch,
        outstandingBalanceCount: negative.length,
        outstandingBalanceTotal: outstandingTotal,
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
          .select('id, status, appointment_doctors!inner(doctor_id, is_active)')
          .gte('scheduled_at', range.start.toIso8601String())
          .lte('scheduled_at', range.end.toIso8601String()));
      final Map<String, int> apptsPerDoc = <String, int>{};
      final Map<String, int> completedPerDoc = <String, int>{};
      final docRows = await _service.guardQuery(
        () => _service.from('staff').select('id, full_name').eq('role', 'doctor'),
      );
      final Map<String, String> docNames = {for (final r in docRows) r['id'] as String: r['full_name'] as String};
      for (final appt in apptRows) {
        final bool done = (appt['status'] as String?) == 'completed';
        for (final d in (appt['appointment_doctors'] as List<dynamic>?) ?? <dynamic>[]) {
          final Map<String, dynamic> dm = d as Map<String, dynamic>;
          if (dm['is_active'] != true) continue;
          final String name = docNames[dm['doctor_id'] as String] ?? (dm['doctor_id'] as String);
          apptsPerDoc[name] = (apptsPerDoc[name] ?? 0) + 1;
          if (done) completedPerDoc[name] = (completedPerDoc[name] ?? 0) + 1;
        }
      }
      final Map<String, double> ratePerDoc = <String, double>{};
      for (final e in apptsPerDoc.entries) {
        final int cdone = completedPerDoc[e.key] ?? 0;
        ratePerDoc[e.key] = e.value > 0 ? cdone / e.value : 0;
      }
      final sorted = apptsPerDoc.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final newStaffRows = await _service.guardQuery(() => _service
          .from('staff').select('id').eq('role', 'doctor').eq('is_active', true)
          .gte('created_at', range.start.toIso8601String())
          .lte('created_at', range.end.toIso8601String()));
      return Result.success(StaffSummary(
        appointmentsPerDoctor: apptsPerDoc,
        completionRatePerDoctor: ratePerDoc,
        topDoctors: sorted.take(5).map((e) => e.key).toList(),
        newStaffInPeriod: newStaffRows.length,
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
