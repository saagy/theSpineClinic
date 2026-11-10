import '../../auth/domain/staff.dart';
import '../../auth/domain/user_role.dart';

abstract final class BillingAccess {
  static const enabled = bool.fromEnvironment('BILLING_PILOT', defaultValue: true);
  static bool canTransact(Staff? user) =>
      enabled && user != null && user.isActive && user.canHandlePayments;
  static bool canManageCatalog(Staff? user) =>
      canTransact(user) && user?.role == UserRole.superAdmin;
}
