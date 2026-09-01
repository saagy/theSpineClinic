/// Delegate class for paginated patient list queries extracted from
/// [PatientRepositoryImpl] to keep the main file under 200 lines.
library;

import 'package:supabase_flutter/supabase_flutter.dart' show CountOption;

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';

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

  Future<Result<List<Patient>>> getAllPatients({
    String? query,
    String? doctorId,
    ClinicLocation? clinic,
    int offset = 0,
    int limit = 30,
    String orderBy = 'full_name',
    bool ascending = true,
  }) async {
    try {
      final List<Map<String, dynamic>> rows = await _service.guardQuery(() {
        final base = doctorId != null
            ? _service
                  .from(_table)
                  .select('*, patient_doctors!inner(doctor_id)')
                  .eq('patient_doctors.doctor_id', doctorId)
            : _service.from(_table).select('*');
        final withClinic = clinic != null
            ? base.eq('clinic', clinic.dbValue)
            : base;
        if (query != null && query.trim().isNotEmpty) {
          final tokens = query
              .trim()
              .split(RegExp(r'\s+'))
              .where((t) => t.isNotEmpty);
          final built = tokens.fold(
            withClinic,
            (q, t) => q.or('full_name.ilike.%$t%,phone_number.ilike.%$t%'),
          );
          return built
              .order(orderBy, ascending: ascending)
              .range(offset, offset + limit - 1);
        }
        return withClinic
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
    String? query,
    String? doctorId,
    ClinicLocation? clinic,
  }) async {
    try {
      final int count = await _service.guardQuery(() async {
        if (doctorId != null) {
          var base = _service
              .from('patient_doctors')
              .count(CountOption.exact)
              .eq('doctor_id', doctorId);
          if (clinic != null) {
            base = base.eq('patients.clinic', clinic.dbValue);
          }
          if (query != null && query.trim().isNotEmpty) {
            for (final token in query.trim().split(RegExp(r'\s+'))) {
              if (token.isNotEmpty) {
                base = base.or(
                  'full_name.ilike.%$token%,phone_number.ilike.%$token%',
                  referencedTable: 'patients',
                );
              }
            }
          }
          return await base;
        }

        var base = _service.from(_table).count(CountOption.exact);
        if (clinic != null) {
          base = base.eq('clinic', clinic.dbValue);
        }
        if (query != null && query.trim().isNotEmpty) {
          for (final token in query.trim().split(RegExp(r'\s+'))) {
            if (token.isNotEmpty) {
              base = base.or(
                'full_name.ilike.%$token%,phone_number.ilike.%$token%',
              );
            }
          }
        }
        return await base;
      });
      return Result.success(count);
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }
}
