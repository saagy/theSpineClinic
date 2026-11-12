import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_details.dart';

/// One staff member's reference details; empty when none were saved.
/// Row-level security returns nothing to anyone but active super admins.
Future<Result<StaffDetails>> fetchStaffDetails(SupabaseService service, String staffId) async {
  try {
    final Map<String, dynamic>? row = await service.guardQuery(
      () => service.from('staff_details').select().eq('staff_id', staffId).maybeSingle(),
    );
    return Result.success(row == null ? StaffDetails.empty : StaffDetails.fromJson(row));
  } on AppException catch (e) {
    return Result.failure(e);
  } on Exception catch (e) {
    return Result.failure(AppException.fromSupabaseException(e));
  }
}

/// Working days and hours for every staff member, for the directory.
Future<Result<Map<String, StaffDetails>>> fetchStaffSchedules(SupabaseService service) async {
  try {
    final List<Map<String, dynamic>> rows = await service.guardQuery(
      () => service.from('staff_details').select('staff_id, working_days, work_starts_at, work_ends_at'),
    );
    return Result.success({
      for (final row in rows) row['staff_id'] as String: StaffDetails.fromJson(row),
    });
  } on AppException catch (e) {
    return Result.failure(e);
  } on Exception catch (e) {
    return Result.failure(AppException.fromSupabaseException(e));
  }
}
