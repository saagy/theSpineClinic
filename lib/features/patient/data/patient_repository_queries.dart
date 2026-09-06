/// Delegate class for paginated patient list queries extracted from
/// [PatientRepositoryImpl] to keep the main file under 200 lines.
library;

import 'package:supabase_flutter/supabase_flutter.dart'
    show CountOption, PostgrestFilterBuilder;

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_filters.dart';

class PatientRepositoryQueries {
  PatientRepositoryQueries(this._service);
  final SupabaseService _service;
  static const String _table = 'patients';

  Future<Result<List<Patient>>> getDuePatients({
    required DateTime date,
    String? doctorId,
    required ClinicLocation clinic,
  }) async {
    try {
      final List<Map<String, dynamic>> rows = await _service.guardQuery(
        () => _service.rpc(
          'get_due_patients',
          params: <String, dynamic>{
            'p_due_on': _dateOnly(date),
            'p_doctor_id': doctorId,
            'p_clinic': clinic.dbValue,
          },
        ),
      );
      return Result.success(rows.map(Patient.fromJson).toList());
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  PostgrestFilterBuilder<List<Map<String, dynamic>>> _buildFilteredQuery(
    PatientFilters filters, {
    required String selectColumns,
  }) {
    final String querySelect = filters.doctorId != null
        ? '$selectColumns, patient_doctors!inner(doctor_id)'
        : selectColumns;
    var query = _service.from(_table).select(querySelect);

    if (filters.doctorId != null) {
      query = query.eq('patient_doctors.doctor_id', filters.doctorId!);
    }
    if (filters.clinic != null) {
      query = query.eq('clinic', filters.clinic!.dbValue);
    }
    final search = filters.search?.trim();
    if (search != null && search.isNotEmpty) {
      final tokens = search.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
      for (final token in tokens) {
        query = query.or('full_name.ilike.%$token%,phone_number.ilike.%$token%');
      }
    }
    return query;
  }

  Future<Result<List<Patient>>> getAllPatients({
    PatientFilters filters = const PatientFilters(),
    String? query,
    String? doctorId,
    ClinicLocation? clinic,
    int offset = 0,
    int limit = 30,
    String orderBy = 'full_name',
    bool ascending = true,
  }) async {
    try {
      final effective = filters.isNotEmpty
          ? filters
          : PatientFilters(clinic: clinic, doctorId: doctorId, search: query);
      final List<Map<String, dynamic>> rows = await _service.guardQuery(() {
        return _buildFilteredQuery(effective, selectColumns: '*')
            .order(orderBy, ascending: ascending)
            .range(offset, offset + limit - 1);
      });
      return Result.success(rows.map(Patient.fromJson).toList());
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }

  Future<Result<int>> countAllPatients({
    PatientFilters filters = const PatientFilters(),
    String? query,
    String? doctorId,
    ClinicLocation? clinic,
  }) async {
    try {
      final effective = filters.isNotEmpty
          ? filters
          : PatientFilters(clinic: clinic, doctorId: doctorId, search: query);
      final int count = await _service.guardQuery(() async {
        final res = await _buildFilteredQuery(effective, selectColumns: 'id')
            .limit(1)
            .count(CountOption.exact);
        return res.count;
      });
      return Result.success(count);
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }
}
