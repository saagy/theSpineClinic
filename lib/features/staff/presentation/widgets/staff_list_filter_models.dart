import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_account_status.dart';

enum StaffSortOption {
  nameAsc,
  nameDesc,
  roleAsc,
  newest;

  String get displayLabel => switch (this) {
    StaffSortOption.nameAsc => AppStrings.sortNameAsc,
    StaffSortOption.nameDesc => AppStrings.sortNameDesc,
    StaffSortOption.roleAsc => AppStrings.sortRole,
    StaffSortOption.newest => AppStrings.sortNewest,
  };
}

class StaffListFilters {
  const StaffListFilters({this.role, this.status, this.branch});

  final UserRole? role;
  final StaffAccountStatus? status;
  final ClinicLocation? branch;

  int get activeCount =>
      (role == null ? 0 : 1) +
      (status == null ? 0 : 1) +
      (branch == null ? 0 : 1);

  /// [branchesOf] gives a person's assigned branches; a branch filter
  /// matches anyone assigned there.
  bool matches(Staff staff, List<ClinicLocation> Function(String staffId) branchesOf) {
    if (role != null && staff.role != role) return false;
    if (status != null && staff.accountStatus != status) return false;
    if (branch != null && !branchesOf(staff.id).contains(branch) && staff.branch != branch) return false;
    return true;
  }

  StaffListFilters copyWith({
    UserRole? Function()? role,
    StaffAccountStatus? Function()? status,
    ClinicLocation? Function()? branch,
  }) {
    return StaffListFilters(
      role: role == null ? this.role : role(),
      status: status == null ? this.status : status(),
      branch: branch == null ? this.branch : branch(),
    );
  }
}
