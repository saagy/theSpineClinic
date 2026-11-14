import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_assignments.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_details.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_shift.dart';

Future<Result<T>> _guard<T>(Future<T> Function() run) async {
  try {
    return Result.success(await run());
  } on AppException catch (e) {
    return Result.failure(e);
  } on Exception catch (e) {
    return Result.failure(AppException.fromSupabaseException(e));
  }
}

/// One staff member's employment details; empty when none were saved or the
/// caller may not read them (row-level security returns no row).
Future<Result<StaffDetails>> fetchStaffDetails(SupabaseService service, String staffId) => _guard(() async {
  final Map<String, dynamic>? row = await service.guardQuery(
    () => service.from('staff_details').select().eq('staff_id', staffId).maybeSingle(),
  );
  return row == null ? StaffDetails.empty : StaffDetails.fromJson(row);
});

/// Every staff member's branches and shifts. Both tables are small and
/// readable by all active staff.
Future<Result<StaffAssignments>> fetchStaffAssignments(SupabaseService service) => _guard(() async {
  final List<Map<String, dynamic>> branchRows = await service.guardQuery(
    () => service.from('staff_branches').select('staff_id, branch'),
  );
  final List<Map<String, dynamic>> shiftRows = await service.guardQuery(
    () => service.from('staff_shifts').select('staff_id, branch, weekday, starts_at, ends_at'),
  );
  final Map<String, List<ClinicLocation>> branches = {};
  for (final row in branchRows) {
    final ClinicLocation? branch = ClinicLocation.fromDbValue(row['branch'] as String?);
    if (branch != null) (branches[row['staff_id'] as String] ??= []).add(branch);
  }
  final Map<String, List<StaffShift>> shifts = {};
  for (final row in shiftRows) {
    final StaffShift? shift = StaffShift.tryFromJson(row);
    if (shift != null) (shifts[row['staff_id'] as String] ??= []).add(shift);
  }
  return StaffAssignments(
    branches: {
      for (final entry in branches.entries)
        entry.key: ClinicLocation.values.where(entry.value.contains).toList(growable: false),
    },
    shifts: {
      for (final entry in shifts.entries) entry.key: (entry.value..sort(StaffShift.compare)),
    },
  );
});

/// Upcoming scheduled visits [staffId] has at [branch] (super admins only).
Future<Result<int>> fetchUpcomingAtBranch(SupabaseService service, String staffId, ClinicLocation branch) =>
    _guard(() async {
      final Object? count = await service.rpc<Object?>(
        'staff_upcoming_at_branch',
        params: {'p_staff': staffId, 'p_branch': branch.dbValue},
      );
      return (count as num?)?.toInt() ?? 0;
    });
