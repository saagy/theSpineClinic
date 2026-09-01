import 'package:supabase_flutter/supabase_flutter.dart' show CountOption;

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/staff/data/staff_repository_queries.dart';
import 'package:spine_clinic_app/features/staff/data/staff_write_queries.dart';

abstract class StaffRepository {
  Future<Result<List<Staff>>> getActiveDoctors();
  Future<Result<List<Patient>>> getAssignedPatients({
    required String doctorId,
    String? query,
    ClinicLocation? clinic,
    int offset = 0,
    int limit = 30,
    String orderBy = 'full_name',
    bool ascending = true,
  });
  Future<Result<int>> countAssignedPatients({
    required String doctorId,
    String? query,
    ClinicLocation? clinic,
  });
  Future<Result<List<Staff>>> getAllStaff();
  Future<Result<void>> createStaff({
    required String fullName,
    required String email,
    required UserRole role,
    required String password,
    required bool canManagePayments,
    String? phone,
    ClinicLocation? branch,
  });
  Future<Result<void>> updateStaff({required Staff staff, String? newPassword});
  Future<Result<int>> countUpcomingAppointments(String staffId);
}

class StaffRepositoryImpl implements StaffRepository {
  StaffRepositoryImpl({required SupabaseService supabaseService})
    : _service = supabaseService;
  final SupabaseService _service;

  @override
  Future<Result<List<Staff>>> getActiveDoctors() async {
    try {
      final rows = await _service.guardQuery(
        () => _service
            .from('staff')
            .select()
            .eq('role', UserRole.doctor.dbValue)
            .eq('is_active', true)
            .order('full_name'),
      );
      return Result.success(rows.map(Staff.fromJson).toList());
    } on AppException catch (e) {
      return Result.failure(e);
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  @override
  Future<Result<List<Patient>>> getAssignedPatients({
    required String doctorId,
    String? query,
    ClinicLocation? clinic,
    int offset = 0,
    int limit = 30,
    String orderBy = 'full_name',
    bool ascending = true,
  }) async {
    try {
      var builder = _service
          .from('patients')
          .select('*, patient_doctors!inner(doctor_id)')
          .eq('patient_doctors.doctor_id', doctorId);
      if (clinic != null) {
        builder = builder.eq('clinic', clinic.dbValue);
      }
      if (query != null && query.trim().isNotEmpty) {
        for (final token in query.trim().split(RegExp(r'\s+'))) {
          if (token.isNotEmpty) {
            builder = builder.or(
              'full_name.ilike.%$token%,phone_number.ilike.%$token%',
            );
          }
        }
      }
      final rows = await _service.guardQuery(
        () => builder
            .order(orderBy, ascending: ascending)
            .range(offset, offset + limit - 1),
      );
      return Result.success(rows.map(Patient.fromJson).toList());
    } on AppException catch (e) {
      return Result.failure(e);
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  @override
  Future<Result<int>> countAssignedPatients({
    required String doctorId,
    String? query,
    ClinicLocation? clinic,
  }) async {
    try {
      final int count = await _service.guardQuery(() async {
        var builder = _service
            .from('patient_doctors')
            .count(CountOption.exact)
            .eq('doctor_id', doctorId);
        if (clinic != null) {
          builder = builder.eq('patients.clinic', clinic.dbValue);
        }
        if (query != null && query.trim().isNotEmpty) {
          for (final token in query.trim().split(RegExp(r'\s+'))) {
            if (token.isNotEmpty) {
              builder = builder.or(
                'full_name.ilike.%$token%,phone_number.ilike.%$token%',
                referencedTable: 'patients',
              );
            }
          }
        }
        return await builder;
      });
      return Result.success(count);
    } on AppException catch (e) {
      return Result.failure(e);
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  @override
  Future<Result<List<Staff>>> getAllStaff() async {
    try {
      final rows = await _service.guardQuery(
        () => _service.from('staff').select().order('full_name'),
      );
      return Result.success(rows.map(Staff.fromJson).toList());
    } on AppException catch (e) {
      return Result.failure(e);
    } on Exception catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  @override
  Future<Result<void>> createStaff({
    required String fullName,
    required String email,
    required UserRole role,
    required String password,
    required bool canManagePayments,
    String? phone,
    ClinicLocation? branch,
  }) async {
    return createStaffAccount(
      _service,
      fullName: fullName,
      email: email,
      role: role,
      password: password,
      canManagePayments: canManagePayments,
      phone: phone,
      branch: branch,
    );
  }

  @override
  Future<Result<void>> updateStaff({
    required Staff staff,
    String? newPassword,
  }) async {
    return updateStaffAccount(_service, staff: staff, newPassword: newPassword);
  }

  /// Counts upcoming appointments where [staffId] is an active assignee.
  ///
  /// Used by the staff form to show a soft warning before deactivation.
  /// Does NOT block — the admin decides whether to proceed.
  @override
  Future<Result<int>> countUpcomingAppointments(String staffId) async {
    return countUpcomingStaffAppointments(_service, staffId);
  }
}
