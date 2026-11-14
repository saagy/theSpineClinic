import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';

/// The patient workspace's tabs. A link can open one by its [name] in the
/// `tab` query parameter.
enum PatientWorkspaceTab {
  overview,
  programs,
  appointments,
  notes,
  documents,
  payments;

  String get label => switch (this) {
    PatientWorkspaceTab.overview => AppStrings.patientOverview,
    PatientWorkspaceTab.programs => AppStrings.programs,
    PatientWorkspaceTab.appointments => AppStrings.appointments,
    PatientWorkspaceTab.notes => AppStrings.notes,
    PatientWorkspaceTab.documents => AppStrings.tabDocuments,
    PatientWorkspaceTab.payments => AppStrings.payments,
  };

  static PatientWorkspaceTab? fromQuery(String? value) =>
      values.where((tab) => tab.name == value).firstOrNull;

  /// The tabs [role] sees, in order. Receptionists mostly open a patient to
  /// bill, so Payments follows Overview for them; clinical staff keep the
  /// clinical order and doctors have no Payments tab.
  static List<PatientWorkspaceTab> forRole(UserRole? role) => [
    overview,
    if (role == UserRole.receptionist) payments,
    programs,
    appointments,
    notes,
    documents,
    if (role != UserRole.doctor && role != UserRole.receptionist) payments,
  ];
}
