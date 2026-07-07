import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_account_status.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_list_filter_models.dart';
import 'package:spine_clinic_app/shared/widgets/active_filter_chips_row.dart';

List<ActiveFilterChip> staffActiveFilterChips({
  required StaffListFilters filters,
  required void Function(UserRole?) onRole,
  required void Function(StaffAccountStatus?) onStatus,
  required void Function(ClinicLocation?) onBranch,
}) {
  return [
    if (filters.role != null)
      ActiveFilterChip(
        label: _roleLabel(filters.role!),
        onRemove: () => onRole(null),
      ),
    if (filters.status != null)
      ActiveFilterChip(
        label: filters.status!.label,
        onRemove: () => onStatus(null),
      ),
    if (filters.branch != null)
      ActiveFilterChip(
        label: filters.branch!.displayLabel,
        onRemove: () => onBranch(null),
      ),
  ];
}

String _roleLabel(UserRole role) => switch (role) {
  UserRole.superAdmin => AppStrings.superAdmin,
  UserRole.receptionist => AppStrings.receptionist,
  UserRole.doctor => AppStrings.doctor,
};
