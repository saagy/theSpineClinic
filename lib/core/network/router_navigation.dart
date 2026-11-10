part of 'router.dart';

int _resolveActiveIndex(String role, String location, List<NavTab> tabs) {
  final directIndex = tabs.indexWhere((tab) => tab.path == location);
  if (directIndex >= 0) return directIndex;
  if (location.startsWith('/patient/') ||
      location == AppRoutes.patientList ||
      location == AppRoutes.myPatients) {
    return 1;
  }
  if ((role == 'doctor' || role == 'senior_doctor') &&
      location == AppRoutes.doctorHistory) {
    return 2;
  }
  if (role == 'super_admin' &&
      !location.startsWith('/appointment/') &&
      !location.startsWith('/visit/')) {
    return 2;
  }
  return 0;
}
