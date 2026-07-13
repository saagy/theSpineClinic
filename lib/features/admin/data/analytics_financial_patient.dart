import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/admin/data/analytics_dtos.dart';
import 'package:spine_clinic_app/features/admin/data/analytics_query_helpers.dart';

Future<Result<FinancialSummary>> fetchFinancialSummary(
  SupabaseService service,
  DateTimeRange range,
  String? branchId,
) async {
  try {
    final List<Map<String, dynamic>> payments = await fetchPayments(
      service,
      range,
      branchId,
    );
    double total = 0;
    final Map<String, double> byType = <String, double>{};
    final Map<String, double> byBranch = <String, double>{};
    for (final Map<String, dynamic> row in payments) {
      final double amount = (row['amount'] as num?)?.toDouble() ?? 0;
      total += amount;
      final String category = paymentCategory(
        (row['reason'] as String? ?? '').toLowerCase(),
      );
      byType[category] = (byType[category] ?? 0) + amount;
      final String clinic = extractClinic(row['patient']);
      byBranch[clinic] = (byBranch[clinic] ?? 0) + amount;
    }
    final List<Map<String, dynamic>> patients = await service.guardQuery(() {
      var query = service
          .from('patients')
          .select('session_balance, traction_balance, clinic');
      if (branchId != null) query = query.eq('clinic', branchId);
      return query;
    });
    final List<Map<String, dynamic>> negative = patients.where((row) {
      final int sessions = (row['session_balance'] as int?) ?? 0;
      final int traction = (row['traction_balance'] as int?) ?? 0;
      return sessions < 0 || traction < 0;
    }).toList();
    int owedSessions = 0;
    int owedTraction = 0;
    for (final Map<String, dynamic> row in negative) {
      final int sessions = (row['session_balance'] as int?) ?? 0;
      final int traction = (row['traction_balance'] as int?) ?? 0;
      if (sessions < 0) owedSessions += sessions.abs();
      if (traction < 0) owedTraction += traction.abs();
    }
    final Iterable<Map<String, dynamic>> packageRows = payments.where(
      (row) =>
          (row['reason'] as String? ?? '').toLowerCase().contains('package'),
    );
    return Result.success(
      FinancialSummary(
        totalRevenue: total,
        revenueByPaymentType: byType,
        revenueByBranch: byBranch,
        outstandingBalanceCount: negative.length,
        owedSessions: owedSessions,
        owedTractionSessions: owedTraction,
        packageSalesCount: packageRows.length,
        packageSalesValue: packageRows.fold<double>(
          0,
          (sum, row) => sum + ((row['amount'] as num?)?.toDouble() ?? 0),
        ),
      ),
    );
  } on AppException catch (error) {
    return Result.failure(error);
  } on Exception catch (error) {
    return Result.failure(AppException.fromSupabaseException(error));
  }
}

Future<Result<PatientSummary>> fetchPatientSummary(
  SupabaseService service,
  DateTimeRange range,
  String? branchId,
) async {
  try {
    final List<Map<String, dynamic>> patients = await service.guardQuery(() {
      var query = service.from('patients').select('id, clinic, created_at');
      if (branchId != null) query = query.eq('clinic', branchId);
      return query;
    });
    int newRegistrations = 0;
    final Map<String, int> byBranch = <String, int>{};
    final Set<String> preexistingIds = <String>{};
    for (final Map<String, dynamic> row in patients) {
      final String clinic = row['clinic'] as String? ?? 'unknown';
      byBranch[clinic] = (byBranch[clinic] ?? 0) + 1;
      final String? created = row['created_at'] as String?;
      if (created == null) continue;
      final DateTime createdAt = DateTime.parse(created);
      if (createdAt.isAfter(range.start) && createdAt.isBefore(range.end)) {
        newRegistrations++;
      }
      if (createdAt.isBefore(range.start)) {
        preexistingIds.add(row['id'] as String);
      }
    }
    final List<Map<String, dynamic>> appointments = await service.guardQuery(
      () => service
          .from('appointments')
          .select('patient_id')
          .gte('scheduled_at', range.start.toIso8601String())
          .lte('scheduled_at', range.end.toIso8601String()),
    );
    final Set<String> seenIds = appointments
        .map((row) => row['patient_id'] as String)
        .toSet();
    final int returning = seenIds.where(preexistingIds.contains).length;
    return Result.success(
      PatientSummary(
        newRegistrations: newRegistrations,
        totalActivePatients: patients.length,
        patientsByBranch: byBranch,
        returningRatio: seenIds.isEmpty ? 0 : returning / seenIds.length,
      ),
    );
  } on AppException catch (error) {
    return Result.failure(error);
  } on Exception catch (error) {
    return Result.failure(AppException.fromSupabaseException(error));
  }
}
