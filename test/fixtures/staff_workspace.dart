import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_management_controller.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_applications_controller.dart';

final staffAdmin = Staff(id: 'admin', fullName: 'Mariam Khaled',
  email: 'mariam@example.invalid', role: UserRole.superAdmin, createdAt: DateTime(2026));
final staffRoster = [
  staffAdmin,
  staffAdmin.copyWith(id: 'doctor', fullName: 'Ahmed Hassan', role: UserRole.doctor,
    email: 'ahmed.hassan@example.invalid', phone: '01012345678'),
  staffAdmin.copyWith(id: 'reception', fullName: 'Nour Mahmoud', role: UserRole.receptionist,
    branch: ClinicLocation.tagamoa, email: 'nour@example.invalid', phone: '01098765432'),
  staffAdmin.copyWith(id: 'inactive', fullName: 'Salma Ibrahim', role: UserRole.doctor,
    email: 'salma@example.invalid', isActive: false, deactivatedAt: DateTime(2026, 10)),
  staffAdmin.copyWith(id: 'long', fullName: 'Youssef Abdelrahman Mohamed Hassan', role: UserRole.doctor,
    email: 'youssef.abdelrahman@example.invalid'),
];
final pendingStaff = [
  staffRoster[2].copyWith(id: 'pending1', isActive: false),
  staffRoster[4].copyWith(id: 'pending2', isActive: false),
];

class StaffWorkspaceUser extends CurrentUser {
  @override
  Future<Staff?> build() async => staffAdmin;
}
class StaffWorkspaceRoster extends StaffList {
  @override
  Future<List<Staff>> build() async => staffRoster;
}
class StaffWorkspacePending extends PendingStaffApplications {
  @override
  Future<List<Staff>> build() async => pendingStaff;
}
