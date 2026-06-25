import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/core/utils/patient_helpers.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';

abstract class StaffRepository {
  Future<Result<List<Staff>>> getActiveDoctors();
  Future<Result<List<Patient>>> getAssignedPatients({required String doctorId, String? query});
  Future<Result<List<Staff>>> getAllStaff();
  Future<Result<void>> createStaff({
    required String fullName,
    required String email,
    required UserRole role,
    required String password,
    String? phone,
  });
  Future<Result<void>> updateStaff({
    required Staff staff,
    String? newPassword,
  });
  Future<Result<int>> countUpcomingAppointments(String staffId);
}

class StaffRepositoryImpl implements StaffRepository {
  StaffRepositoryImpl({required SupabaseService supabaseService}) : _service = supabaseService;
  final SupabaseService _service;

  @override
  Future<Result<List<Staff>>> getActiveDoctors() async {
    try {
      final rows = await _service.guardQuery(() => _service
          .from('staff')
          .select()
          .or('role.eq.doctor,role.eq.super_admin')
          .eq('is_active', true)
          .order('full_name'));
      return Result.success(rows.map(Staff.fromJson).toList());
    } on AppException catch (e) {
      return Result.failure(e);
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  @override
  Future<Result<List<Patient>>> getAssignedPatients({required String doctorId, String? query}) async {
    try {
      var builder = _service
          .from('patients')
          .select('*, patient_doctors!inner(), appointments(scheduled_at, status)')
          .eq('patient_doctors.doctor_id', doctorId);
      if (query != null && query.trim().isNotEmpty) {
        for (final token in query.trim().split(RegExp(r'\s+'))) {
          if (token.isNotEmpty) {
            builder = builder.or('full_name.ilike.%$token%,phone_number.ilike.%$token%');
          }
        }
      }
      final rows = await _service.guardQuery(() => builder.order('full_name'));
      return Result.success(rows.map(_buildPatientWithLastVisit).toList());
    } on AppException catch (e) {
      return Result.failure(e);
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  @override
  Future<Result<List<Staff>>> getAllStaff() async {
    try {
      final rows = await _service.guardQuery(() => _service
          .from('staff')
          .select()
          .order('full_name'));
      return Result.success(rows.map(Staff.fromJson).toList());
    } on AppException catch (e) {
      return Result.failure(e);
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  /// Builds a [Patient] from a row that includes embedded appointments.
  ///
  /// The DB's [last_appointment_date] column is always replaced by
  /// [computeLastAppointmentDate] for consistency with every other screen.
  Patient _buildPatientWithLastVisit(Map<String, dynamic> row) {
    final Patient patient = Patient.fromJson(row);
    final dynamic appts = row['appointments'];
    if (appts is! List) return patient;
    final List<Map<String, dynamic>> apptRows = appts
        .whereType<Map<String, dynamic>>()
        .toList();
    final DateTime? computed = computeLastAppointmentDate(apptRows);
    return patient.copyWith(lastAppointmentDate: computed);
  }

  @override
  Future<Result<void>> createStaff({
    required String fullName,
    required String email,
    required UserRole role,
    required String password,
    String? phone,
  }) async {
    try {
      await _service.guardQuery(() => _service.rpc(
        'create_staff_user',
        params: {
          'new_email': email,
          'new_password': password,
          'new_full_name': fullName,
          'new_role': role.dbValue,
          'new_phone': phone,
        },
      ));
      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  @override
  Future<Result<void>> updateStaff({
    required Staff staff,
    String? newPassword,
  }) async {
    try {
      if (staff.userId == _service.currentUserId && !staff.isActive) {
        return Result.failure(const AuthException(
          code: 'auth/self-deactivation',
          message: 'You cannot deactivate your own account.',
        ));
      }

      await _service.guardQuery(() => _service
          .from('staff')
          .update({
            'full_name': staff.fullName,
            'email': staff.email,
            'phone': staff.phone,
            'role': staff.role.dbValue,
            'is_active': staff.isActive,
            'deactivated_at': staff.isActive ? null : DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', staff.id));

      if (newPassword != null && newPassword.isNotEmpty) {
        if (staff.userId == null) {
          return Result.failure(const AuthException(
            code: 'auth/no-user-id',
            message: 'Cannot update password: Staff member has no associated user ID.',
          ));
        }
        await _service.guardQuery(() => _service.rpc(
          'update_user_password',
          params: {
            'target_user_id': staff.userId,
            'new_password': newPassword,
          },
        ));
      }

      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  /// Counts upcoming appointments where [staffId] is an active assignee.
  ///
  /// Used by the staff form to show a soft warning before deactivation.
  /// Does NOT block — the admin decides whether to proceed.
  @override
  Future<Result<int>> countUpcomingAppointments(String staffId) async {
    try {
      final String nowStr = DateTime.now().toUtc().toIso8601String();
      final rows = await _service.guardQuery(() => _service
          .from('appointment_doctors')
          .select('appointment_id, appointments!inner(scheduled_at)')
          .eq('doctor_id', staffId)
          .eq('is_active', true)
          .gte('appointments.scheduled_at', nowStr),
        );
      return Result.success(rows.length);
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }
}
