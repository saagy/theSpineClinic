import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';

void main() {
  Staff staff(UserRole role, {bool canManagePayments = false}) => Staff(
    id: role.dbValue,
    fullName: role.dbValue,
    email: '${role.dbValue}@example.test',
    role: role,
    canManagePayments: canManagePayments,
    createdAt: DateTime(2026),
  );

  test('canHandlePayments gates receptionists with explicit permission', () {
    expect(staff(UserRole.superAdmin).canHandlePayments, isTrue);
    expect(staff(UserRole.receptionist).canHandlePayments, isFalse);
    expect(
      staff(UserRole.receptionist, canManagePayments: true).canHandlePayments,
      isTrue,
    );
    expect(
      staff(UserRole.doctor, canManagePayments: true).canHandlePayments,
      isFalse,
    );
  });
}
