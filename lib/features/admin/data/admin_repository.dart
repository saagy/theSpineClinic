import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

/// Single data point for trend charts.
class TrendPoint {
  const TrendPoint({required this.label, required this.visits, required this.revenue});
  final String label;
  final int visits;
  final double revenue;
}

/// Per-branch comparative metrics.
class BranchMetrics {
  const BranchMetrics({
    required this.totalPatients,
    required this.totalAppointments,
    required this.grossIncome,
  });
  final int totalPatients;
  final int totalAppointments;
  final double grossIncome;
}

/// Aggregated metrics for administrative reports.
class ReportData {
  const ReportData({
    required this.totalPatients,
    required this.newPatients,
    required this.totalAppointments,
    required this.grossIncome,
    required this.totalPackageBalances,
    required this.statusBreakdown,
    required this.typeBreakdown,
    required this.doctorBreakdown,
    required this.tagamoaMetrics,
    required this.masrElgedidaMetrics,
    required this.monthlyTrends,
    required this.yearlyTrends,
  });

  final int totalPatients;
  final int newPatients;
  final int totalAppointments;
  final double grossIncome;
  final int totalPackageBalances;
  final Map<String, int> statusBreakdown;
  final Map<String, int> typeBreakdown;
  final Map<String, int> doctorBreakdown;
  final BranchMetrics tagamoaMetrics;
  final BranchMetrics masrElgedidaMetrics;
  final List<TrendPoint> monthlyTrends;
  final List<TrendPoint> yearlyTrends;
}

/// Repository handling data interactions for administrative dashboards.
abstract class AdminRepository {
  Future<Result<List<Staff>>> getPendingDoctorApplications();
  Future<Result<List<Staff>>> getAllDoctorApplications();
  Future<Result<void>> approveDoctor(String id);
  Future<Result<void>> rejectDoctor({required String id, required String userId});

  Future<Result<ReportData>> getReportData({
    required ClinicLocation? clinic,
    required DateTime startDate,
    required DateTime endDate,
  });
}

/// Supabase-backed implementation of [AdminRepository].
class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl({required SupabaseService supabaseService}) : _service = supabaseService;
  final SupabaseService _service;

  @override
  Future<Result<List<Staff>>> getPendingDoctorApplications() async {
    try {
      final rows = await _service.guardQuery(() => _service
          .from('staff').select().eq('role', 'doctor').eq('is_active', false).order('created_at'));
      return Result.success(rows.map(Staff.fromJson).toList());
    } on AppException catch (e) {
      return Result.failure(e);
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  @override
  Future<Result<List<Staff>>> getAllDoctorApplications() async {
    try {
      final rows = await _service.guardQuery(() => _service
          .from('staff').select().eq('role', 'doctor').order('created_at'));
      return Result.success(rows.map(Staff.fromJson).toList());
    } on AppException catch (e) {
      return Result.failure(e);
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  @override
  Future<Result<void>> approveDoctor(String id) async {
    try {
      await _service.guardQuery(() => _service.from('staff').update({'is_active': true}).eq('id', id));
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  @override
  Future<Result<void>> rejectDoctor({required String id, required String userId}) async {
    try {
      await _service.guardQuery(() => _service.rpc('delete_doctor_user', params: {'target_user_id': userId}));
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  @override
  Future<Result<ReportData>> getReportData({
    required ClinicLocation? clinic,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // ── Patient metrics ──
      final List<Map<String, dynamic>> patientRows = await _service.guardQuery(() {
        final query = _service.from('patients').select('created_at, clinic, session_balance, traction_balance');
        return clinic != null ? query.eq('clinic', clinic.dbValue) : query;
      });

      final int totalPatients = patientRows.length;
      final int newPatients = patientRows.where((row) {
        final String? s = row['created_at'] as String?;
        if (s == null) return false;
        final DateTime d = DateTime.parse(s);
        return d.isAfter(startDate) && d.isBefore(endDate);
      }).length;
      final int totalPackageBalances = patientRows.fold<int>(
        0,
        (sum, row) =>
            sum +
            ((row['session_balance'] as int?) ?? 0) +
            ((row['traction_balance'] as int?) ?? 0),
      );

      // ── Per-branch patient counts ──
      int tagamoaPatients = 0;
      int masrElgedidaPatients = 0;
      for (final row in patientRows) {
        final String c = row['clinic'] as String? ?? '';
        if (c == ClinicLocation.tagamoa.dbValue) {
          tagamoaPatients++;
        } else if (c == ClinicLocation.masrElgedida.dbValue) {
          masrElgedidaPatients++;
        }
      }

      // ── Payment / revenue ──
      final List<Map<String, dynamic>> payRows = await _service.guardQuery(() {
        final query = _service.from('payment_records').select('amount, recorded_at, patient:patients!inner(clinic)')
            .gte('recorded_at', startDate.toIso8601String())
            .lte('recorded_at', endDate.toIso8601String());
        return clinic != null ? query.eq('patient.clinic', clinic.dbValue) : query;
      });

      double grossIncome = 0;
      double tagamoaIncome = 0;
      double masrElgedidaIncome = 0;
      for (final row in payRows) {
        final double amt = (row['amount'] as num?)?.toDouble() ?? 0;
        grossIncome += amt;
        final Object? patient = row['patient'];
        final String pc = (patient is Map<String, dynamic>) ? (patient['clinic'] as String? ?? '') : '';
        if (pc == ClinicLocation.tagamoa.dbValue) {
          tagamoaIncome += amt;
        } else if (pc == ClinicLocation.masrElgedida.dbValue) {
          masrElgedidaIncome += amt;
        }
      }

      // ── Appointments ──
      final List<Map<String, dynamic>> apptRows = await _service.guardQuery(() {
        final base = _service.from('appointments').select(
          'id, status, type, scheduled_at, patient:patients!inner(clinic), appointment_doctors(is_active, doctor_id)',
        ).gte('scheduled_at', startDate.toIso8601String()).lte('scheduled_at', endDate.toIso8601String());
        return clinic != null ? base.eq('patient.clinic', clinic.dbValue) : base;
      });

      final int totalAppointments = apptRows.length;
      final Map<String, int> statusBreakdown = <String, int>{};
      final Map<String, int> typeBreakdown = <String, int>{};
      int tagamoaAppts = 0;
      int masrElgedidaAppts = 0;

      // Doctor name map
      final List<Map<String, dynamic>> doctorRows = await _service.guardQuery(
        () => _service.from('staff').select('id, full_name').eq('role', 'doctor'),
      );
      final Map<String, String> doctorNames = {
        for (final row in doctorRows) row['id'] as String: row['full_name'] as String,
      };
      final Map<String, int> doctorBreakdown = <String, int>{};

      for (final row in apptRows) {
        final String status = row['status'] as String? ?? 'unknown';
        statusBreakdown[status] = (statusBreakdown[status] ?? 0) + 1;
        final String type = row['type'] as String? ?? 'unknown';
        typeBreakdown[type] = (typeBreakdown[type] ?? 0) + 1;

        final Object? patient = row['patient'];
        final String pc = (patient is Map<String, dynamic>) ? (patient['clinic'] as String? ?? '') : '';
        if (pc == ClinicLocation.tagamoa.dbValue) {
          tagamoaAppts++;
        } else if (pc == ClinicLocation.masrElgedida.dbValue) {
          masrElgedidaAppts++;
        }

        final List<Map<String, dynamic>> docs = (row['appointment_doctors'] as List<Object?>?)?.cast<Map<String, dynamic>>() ?? [];
        for (final doc in docs) {
          if (doc['is_active'] == true) {
            final String? docId = doc['doctor_id'] as String?;
            if (docId != null) {
              final String docName = doctorNames[docId] ?? 'Unknown Doctor';
              doctorBreakdown[docName] = (doctorBreakdown[docName] ?? 0) + 1;
            }
          }
        }
      }

      // ── Monthly trends (last 12 months) ──
      final List<TrendPoint> monthlyTrends = await _buildMonthlyTrends(clinic);
      final List<TrendPoint> yearlyTrends = await _buildYearlyTrends(clinic);

      return Result.success(ReportData(
        totalPatients: totalPatients,
        newPatients: newPatients,
        totalAppointments: totalAppointments,
        grossIncome: grossIncome,
        totalPackageBalances: totalPackageBalances,
        statusBreakdown: statusBreakdown,
        typeBreakdown: typeBreakdown,
        doctorBreakdown: doctorBreakdown,
        tagamoaMetrics: BranchMetrics(
          totalPatients: tagamoaPatients,
          totalAppointments: tagamoaAppts,
          grossIncome: tagamoaIncome,
        ),
        masrElgedidaMetrics: BranchMetrics(
          totalPatients: masrElgedidaPatients,
          totalAppointments: masrElgedidaAppts,
          grossIncome: masrElgedidaIncome,
        ),
        monthlyTrends: monthlyTrends,
        yearlyTrends: yearlyTrends,
      ));
    } on AppException catch (e) {
      return Result.failure(e);
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  // ── Trend builders ──

  Future<List<TrendPoint>> _buildMonthlyTrends(ClinicLocation? clinic) async {
    final List<TrendPoint> trends = <TrendPoint>[];
    final DateTime now = DateTime.now();
    for (int i = 11; i >= 0; i--) {
      final DateTime monthStart = DateTime(now.year, now.month - i, 1);
      final DateTime monthEnd = DateTime(now.year, now.month - i + 1, 1).subtract(const Duration(microseconds: 1));

      final List<Map<String, dynamic>> rows = await _service.guardQuery(() {
        final query = _service.from('appointments').select('id, patient:patients!inner(clinic)')
            .gte('scheduled_at', monthStart.toIso8601String())
            .lte('scheduled_at', monthEnd.toIso8601String());
        return clinic != null ? query.eq('patient.clinic', clinic.dbValue) : query;
      });
      final int visits = rows.length;

      final List<Map<String, dynamic>> payRows = await _service.guardQuery(() {
        final query = _service.from('payment_records').select('amount, patient:patients!inner(clinic)')
            .gte('recorded_at', monthStart.toIso8601String())
            .lte('recorded_at', monthEnd.toIso8601String());
        return clinic != null ? query.eq('patient.clinic', clinic.dbValue) : query;
      });
      final double revenue = payRows.fold<double>(0, (sum, r) => sum + ((r['amount'] as num?)?.toDouble() ?? 0));

      final String label = '${monthStart.month}/${monthStart.year.toString().substring(2)}';
      trends.add(TrendPoint(label: label, visits: visits, revenue: revenue));
    }
    return trends;
  }

  Future<List<TrendPoint>> _buildYearlyTrends(ClinicLocation? clinic) async {
    final List<TrendPoint> trends = <TrendPoint>[];
    final DateTime now = DateTime.now();
    for (int i = 4; i >= 0; i--) {
      final int year = now.year - i;
      final DateTime yearStart = DateTime(year, 1, 1);
      final DateTime yearEnd = DateTime(year + 1, 1, 1).subtract(const Duration(microseconds: 1));

      final List<Map<String, dynamic>> rows = await _service.guardQuery(() {
        final query = _service.from('appointments').select('id, patient:patients!inner(clinic)')
            .gte('scheduled_at', yearStart.toIso8601String())
            .lte('scheduled_at', yearEnd.toIso8601String());
        return clinic != null ? query.eq('patient.clinic', clinic.dbValue) : query;
      });
      final int visits = rows.length;

      final List<Map<String, dynamic>> payRows = await _service.guardQuery(() {
        final query = _service.from('payment_records').select('amount, patient:patients!inner(clinic)')
            .gte('recorded_at', yearStart.toIso8601String())
            .lte('recorded_at', yearEnd.toIso8601String());
        return clinic != null ? query.eq('patient.clinic', clinic.dbValue) : query;
      });
      final double revenue = payRows.fold<double>(0, (sum, r) => sum + ((r['amount'] as num?)?.toDouble() ?? 0));

      trends.add(TrendPoint(label: year.toString(), visits: visits, revenue: revenue));
    }
    return trends;
  }
}
