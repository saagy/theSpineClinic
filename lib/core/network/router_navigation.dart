part of 'router.dart';

int _resolveActiveIndex(String role, String location) {
  switch (role) {
    case 'doctor':
      if (location == AppRoutes.doctorProfile ||
          location == AppRoutes.doctorHistory) {
        return 2;
      }
      if (location == AppRoutes.myPatients ||
          location == AppRoutes.patientList ||
          location.startsWith('/patient/')) {
        return 1;
      }
      return 0;
    case 'super_admin':
      if (location == AppRoutes.reports) return 0;
      if (location == AppRoutes.allAppointments ||
          location.startsWith('/appointment/') ||
          location.startsWith('/visit/')) {
        return 1;
      }
      if (location == AppRoutes.patientList ||
          location.startsWith('/patient/')) {
        return 2;
      }
      return 3;
    case 'receptionist':
    default:
      if (location == AppRoutes.receptionistProfile) return 2;
      if (location == AppRoutes.patientList ||
          location.startsWith('/patient/')) {
        return 1;
      }
      return 0;
  }
}

bool _isSubPage(String location) {
  if (location.startsWith('/appointment/') &&
      !location.endsWith('/edit') &&
      !location.endsWith('/notes')) {
    return true;
  }
  if (location.startsWith('/visit/')) return true;
  if (location.startsWith('/patient/') &&
      !location.endsWith('/edit') &&
      !location.endsWith('/pay')) {
    return true;
  }
  return location == AppRoutes.doctorHistory || location == AppRoutes.staffList;
}

void _onTabSelected(BuildContext context, String role, int index) {
  switch (role) {
    case 'doctor':
      switch (index) {
        case 0:
          context.go(AppRoutes.schedule);
        case 1:
          context.go(AppRoutes.myPatients);
        case 2:
          context.go(AppRoutes.doctorProfile);
      }
    case 'super_admin':
      switch (index) {
        case 0:
          context.go(AppRoutes.reports);
        case 1:
          context.go(AppRoutes.allAppointments);
        case 2:
          context.go(AppRoutes.patientList);
        case 3:
          context.go(AppRoutes.adminHub);
      }
    case 'receptionist':
    default:
      switch (index) {
        case 0:
          context.go(AppRoutes.allAppointments);
        case 1:
          context.go(AppRoutes.patientList);
        case 2:
          context.go(AppRoutes.receptionistProfile);
      }
  }
}
