import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';

enum StaffAccountStatus {
  pending,
  active,
  deactivated;

  String get label => switch (this) {
    StaffAccountStatus.pending => AppStrings.pendingApproval,
    StaffAccountStatus.active => AppStrings.active,
    StaffAccountStatus.deactivated => AppStrings.deactivated,
  };
}

extension StaffAccountStatusX on Staff {
  StaffAccountStatus get accountStatus {
    if (isActive) return StaffAccountStatus.active;
    if (deactivatedAt == null) return StaffAccountStatus.pending;
    return StaffAccountStatus.deactivated;
  }

  bool get isPendingApplication => accountStatus == StaffAccountStatus.pending;
}
