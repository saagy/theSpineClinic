/// Delegate class for paginated patient list queries extracted from
/// [PatientRepositoryImpl] to keep the main file under 200 lines.
library;

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/core/utils/patient_helpers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';

class PatientRepositoryQueries {
  PatientRepositoryQueries(this._service);
  final SupabaseService _service;
  static const String _table = 'patients';

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
            ? _service.from(_table).select('*, patient_doctors!inner(), appointments(scheduled_at, status)').eq('patient_doctors.doctor_id', doctorId)
            : _service.from(_table).select('*, appointments(scheduled_at, status)');
        final withClinic = clinic != null ? base.eq('clinic', clinic.dbValue) : base;
        if (query != null && query.trim().isNotEmpty) {
          final tokens = query.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
          final built = tokens.fold(withClinic, (q, t) => q.or('full_name.ilike.%$t%,phone_number.ilike.%$t%'));
          return built.order(orderBy, ascending: ascending).range(offset, offset + limit - 1);
        }
        return withClinic.order(orderBy, ascending: ascending).range(offset, offset + limit - 1);
      });
      return Result.success(rows.map(parsePatientRowWithLastAppt).toList());
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
      final List<Map<String, dynamic>> rows = await _service.guardQuery(() {
        final base = doctorId != null
            ? _service.from(_table).select('id, patient_doctors!inner(doctor_id)').eq('patient_doctors.doctor_id', doctorId)
            : _service.from(_table).select('id');
        final withClinic = clinic != null ? base.eq('clinic', clinic.dbValue) : base;
        if (query != null && query.trim().isNotEmpty) {
          final tokens = query.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
          final dynamic queryBuilder = withClinic;
          return tokens.fold<dynamic>(queryBuilder, (q, t) => q.or('full_name.ilike.%$t%,phone_number.ilike.%$t%'));
        }
        return withClinic;
      });
      return Result.success(rows.length);
    } on AppException catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(AppException.fromSupabaseException(e));
    }
  }
}
