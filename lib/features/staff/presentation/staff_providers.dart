/// Riverpod providers for the staff controllers.
///
/// Exposes:
/// - [staffRepositoryProvider] — singleton repository access.
/// - [activeDoctorsProvider] — active doctors (includes super admins).
/// - [MyPatientsController] — patients assigned to the current doctor.
///
/// Rule 3 — all state via Riverpod.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/staff/data/staff_repository.dart';

part 'staff_providers.g.dart';

/// Provides a singleton [StaffRepository] instance.
@Riverpod(keepAlive: true)
StaffRepository staffRepository(Ref ref) {
  return StaffRepositoryImpl(
    supabaseService: SupabaseService.instance,
  );
}

/// Fetches all active/approved staff members with the role of doctor or super admin.
@riverpod
Future<List<Staff>> activeDoctors(Ref ref) async {
  final StaffRepository repo = ref.read(staffRepositoryProvider);
  final Result<List<Staff>> result = await repo.getActiveDoctors();
  return result.when(
    success: (List<Staff> data) => data,
    failure: (AppException exception) => throw exception,
  );
}

/// Fetches all doctors and super admins regardless of active status.
///
/// Used by filter/search dropdowns (PatientListFilters, UnifiedFilterSheet)
/// where users need to filter by historical records tied to deactivated staff.
/// Inactive doctors are visually distinguished with an "(Inactive)" badge in
/// the UI. Operational dropdowns (creating/editing) continue to use
/// [activeDoctorsProvider] which strictly excludes inactive staff.
@riverpod
Future<List<Staff>> allDoctorsForFilter(Ref ref) async {
  final StaffRepository repo = ref.read(staffRepositoryProvider);
  final Result<List<Staff>> result = await repo.getAllStaff();
  return result.when(
    success: (List<Staff> data) => data
        .where((s) => s.role == UserRole.doctor || s.role == UserRole.superAdmin)
        .toList(),
    failure: (AppException exception) => throw exception,
  );
}

/// Controller managing the roster of patients assigned to the logged-in doctor.
@riverpod
class MyPatientsController extends _$MyPatientsController {
  @override
  Future<List<Patient>> build() async {
    final Staff? user = ref.watch(currentUserProvider).value;
    if (user == null) return const [];
    final StaffRepository repo = ref.read(staffRepositoryProvider);
    final Result<List<Patient>> result =
        await repo.getAssignedPatients(doctorId: user.id);
    return result.when(
      success: (List<Patient> data) => data,
      failure: (AppException exception) => throw exception,
    );
  }

  /// Searches assigned patients by name or phone number.
  Future<void> search(String query) async {
    final Staff? user = ref.read(currentUserProvider).value;
    if (user == null) return;
    state = const AsyncValue.loading();
    final StaffRepository repo = ref.read(staffRepositoryProvider);
    final Result<List<Patient>> result = await repo.getAssignedPatients(
      doctorId: user.id,
      query: query,
    );
    result.when(
      success: (List<Patient> data) => state = AsyncValue.data(data),
      failure: (AppException exception) =>
          state = AsyncValue.error(exception, StackTrace.current),
    );
  }
}
