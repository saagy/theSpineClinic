import '../../auth/domain/staff.dart';
import '../../auth/domain/user_role.dart';
import '../../patient/domain/clinic_location.dart';

/// Client-side mirror of the database `invoice_can` capabilities. The
/// database enforces the same rules on every command.
abstract final class InvoiceAccess {
  /// Any active receptionist or super admin: view, invoice and collect.
  static bool canIssue(Staff? user) =>
      user != null &&
      user.isActive &&
      (user.role == UserRole.superAdmin || user.role == UserRole.receptionist);

  /// Payment receptionists and super admins: discounts, voids, corrections,
  /// refunds, the service catalog and reports.
  static bool canManage(Staff? user) => user != null && user.isActive && user.canHandlePayments;

  /// The one branch a receptionist bills and reports for; null lets the
  /// user choose (super admins, or a receptionist with no branch set).
  static ClinicLocation? fixedBranch(Staff? user) =>
      user?.role == UserRole.receptionist ? user?.branch : null;
}
