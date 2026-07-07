import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/admin/data/admin_report_models.dart';
import 'package:spine_clinic_app/features/admin/data/admin_report_queries.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

export 'package:spine_clinic_app/features/admin/data/admin_report_models.dart';

abstract class AdminRepository {
  Future<Result<List<Staff>>> getPendingDoctorApplications();
  Future<Result<List<Staff>>> getAllDoctorApplications();
  Future<Result<void>> approveDoctor(String id);
  Future<Result<void>> rejectDoctor({
    required String id,
    required String userId,
  });

  Future<Result<ReportData>> getReportData({
    required ClinicLocation? clinic,
    required DateTime startDate,
    required DateTime endDate,
  });
}

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl({required SupabaseService supabaseService})
    : _service = supabaseService;

  final SupabaseService _service;

  @override
  Future<Result<List<Staff>>> getPendingDoctorApplications() async {
    try {
      final rows = await _service.guardQuery(
        () => _service
            .from('staff')
            .select()
            .eq('is_active', false)
            .isFilter('deactivated_at', null)
            .inFilter('role', [
              UserRole.doctor.dbValue,
              UserRole.receptionist.dbValue,
            ])
            .order('created_at'),
      );
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
      final rows = await _service.guardQuery(
        () => _service.from('staff').select().order('created_at'),
      );
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
      await _service.guardQuery(
        () => _service
            .from('staff')
            .update({'is_active': true, 'deactivated_at': null})
            .eq('id', id),
      );
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  @override
  Future<Result<void>> rejectDoctor({
    required String id,
    required String userId,
  }) async {
    try {
      if (id.isEmpty || userId.isEmpty) {
        return const Result.failure(
          UnknownException(
            message: AppStrings.errorDatabaseRequiredFieldMissing,
          ),
        );
      }
      await _service.guardQuery(
        () => _service.rpc(
          'delete_doctor_user',
          params: {'target_user_id': userId},
        ),
      );
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
  }) {
    return fetchReportData(
      _service,
      clinic: clinic,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
