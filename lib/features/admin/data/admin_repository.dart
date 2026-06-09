import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

/// Aggregated metrics for administrative reports.
class ReportData {
  /// Creates a [ReportData] instance.
  const ReportData({
    required this.totalPatients,
    required this.newPatients,
    required this.totalAppointments,
    required this.statusBreakdown,
    required this.typeBreakdown,
    required this.doctorBreakdown,
  });

  /// Total registered patients (lifetime).
  final int totalPatients;

  /// New patients registered during the selected period.
  final int newPatients;

  /// Total appointments scheduled during the selected period.
  final int totalAppointments;

  /// Breakdown of appointments by status (scheduled, checked_in, completed, cancelled, no_show).
  final Map<String, int> statusBreakdown;

  /// Breakdown of appointments by type (session, gehaz_shad_fakarat, check_up).
  final Map<String, int> typeBreakdown;

  /// Appointment count per doctor.
  final Map<String, int> doctorBreakdown;
}

/// Repository handling data interactions for administrative dashboards.
abstract class AdminRepository {
  /// Fetches inactive doctor registration applications.
  Future<Result<List<Staff>>> getPendingDoctorApplications();

  /// Fetches all doctor applications (active and inactive) for audit tracking.
  Future<Result<List<Staff>>> getAllDoctorApplications();

  /// Approves a doctor application, setting is_active to true.
  Future<Result<void>> approveDoctor(String id);

  /// Rejects a doctor application, deleting them from auth and staff databases.
  Future<Result<void>> rejectDoctor({required String id, required String userId});

  /// Fetches report analytics data for a specific clinic and date range.
  Future<Result<ReportData>> getReportData({
    required ClinicLocation? clinic,
    required DateTime startDate,
    required DateTime endDate,
  });
}

/// Supabase-backed implementation of [AdminRepository].
class AdminRepositoryImpl implements AdminRepository {
  /// Creates an [AdminRepositoryImpl].
  AdminRepositoryImpl({required SupabaseService supabaseService}) : _service = supabaseService;
  final SupabaseService _service;

  @override
  Future<Result<List<Staff>>> getPendingDoctorApplications() async {
    try {
      final rows = await _service.guardQuery(() => _service
          .from('staff')
          .select()
          .eq('role', 'doctor')
          .eq('is_active', false)
          .order('created_at'));
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
          .from('staff')
          .select()
          .eq('role', 'doctor')
          .order('created_at'));
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
      await _service.guardQuery(() => _service
          .from('staff')
          .update({'is_active': true})
          .eq('id', id));
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
      await _service.guardQuery(() => _service.rpc(
        'delete_doctor_user',
        params: {'target_user_id': userId},
      ));
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
      // 1. Fetch patients for patient metrics
      var patientsQuery = _service.from('patients').select('created_at, clinic');
      if (clinic != null) {
        patientsQuery = patientsQuery.eq('clinic', clinic.dbValue);
      }
      final List<Map<String, dynamic>> patientRows =
          await _service.guardQuery(() => patientsQuery);

      final int totalPatients = patientRows.length;
      final int newPatients = patientRows.where((row) {
        final createdAtStr = row['created_at'] as String?;
        if (createdAtStr == null) return false;
        final createdAt = DateTime.parse(createdAtStr);
        return createdAt.isAfter(startDate) && createdAt.isBefore(endDate);
      }).length;

      // 2. Fetch doctor roster to map doctor names
      final List<Map<String, dynamic>> doctorRows = await _service.guardQuery(
        () => _service.from('staff').select('id, full_name').eq('role', 'doctor'),
      );
      final Map<String, String> doctorNames = {
        for (final row in doctorRows) row['id'] as String: row['full_name'] as String,
      };

      // 3. Fetch appointments within period
      var appointmentsQuery = _service.from('appointments').select(
            'id, status, type, scheduled_at, patient:patients!inner(clinic), appointment_doctors(is_active, doctor_id)',
          );
      if (clinic != null) {
        appointmentsQuery = appointmentsQuery.eq('patient.clinic', clinic.dbValue);
      }
      appointmentsQuery = appointmentsQuery
          .gte('scheduled_at', startDate.toIso8601String())
          .lte('scheduled_at', endDate.toIso8601String());
      final List<Map<String, dynamic>> appointmentRows =
          await _service.guardQuery(() => appointmentsQuery);

      final int totalAppointments = appointmentRows.length;

      final Map<String, int> statusBreakdown = {};
      final Map<String, int> typeBreakdown = {};
      final Map<String, int> doctorBreakdown = {};

      for (final row in appointmentRows) {
        // Status breakdown
        final status = row['status'] as String? ?? 'unknown';
        statusBreakdown[status] = (statusBreakdown[status] ?? 0) + 1;

        // Type breakdown
        final type = row['type'] as String? ?? 'unknown';
        typeBreakdown[type] = (typeBreakdown[type] ?? 0) + 1;

        // Doctor breakdown
        final doctorsList = row['appointment_doctors'] as List<dynamic>? ?? [];
        for (final doc in doctorsList) {
          if (doc['is_active'] == true) {
            final docId = doc['doctor_id'] as String?;
            if (docId != null) {
              final docName = doctorNames[docId] ?? 'Unknown Doctor';
              doctorBreakdown[docName] = (doctorBreakdown[docName] ?? 0) + 1;
            }
          }
        }
      }

      return Result.success(ReportData(
        totalPatients: totalPatients,
        newPatients: newPatients,
        totalAppointments: totalAppointments,
        statusBreakdown: statusBreakdown,
        typeBreakdown: typeBreakdown,
        doctorBreakdown: doctorBreakdown,
      ));
    } on AppException catch (e) {
      return Result.failure(e);
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }
}
