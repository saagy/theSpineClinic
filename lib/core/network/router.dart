/// Centralized GoRouter configuration with role-based redirect guards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/doctor_history_screen.dart';
import 'package:spine_clinic_app/features/auth/presentation/doctor_profile_screen.dart';
import 'package:spine_clinic_app/features/auth/presentation/register_screen.dart';
import 'package:spine_clinic_app/features/auth/presentation/login_screen.dart';
import 'package:spine_clinic_app/features/auth/presentation/receptionist_profile_screen.dart';
import 'package:spine_clinic_app/features/auth/presentation/splash_screen.dart';
import 'package:spine_clinic_app/features/appointment/presentation/new_appointment_screen.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_screen.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_detail_screen.dart';
import 'package:spine_clinic_app/features/appointment/presentation/edit_appointment_screen.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/edit_patient_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/my_patients_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/new_patient_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_detail_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_list_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_search_screen.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_screen.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_schedule_screen.dart';
import 'package:spine_clinic_app/shared/widgets/app_shell.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/add_visit_notes_screen.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/visit_detail_screen.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_form_screen.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_list_screen.dart';
import 'package:spine_clinic_app/features/admin/presentation/admin_hub_screen.dart';
import 'package:spine_clinic_app/features/admin/presentation/analytics_screen.dart';
import 'package:spine_clinic_app/features/admin/presentation/doctor_applications_screen.dart';
import 'package:spine_clinic_app/features/admin/presentation/clinic_settings_screen.dart';

part 'router.g.dart';

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AsyncValue<Staff?>>(
      currentUserProvider,
      (_, __) => notifyListeners(),
    );
  }
}

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final _RouterRefreshNotifier refreshNotifier = _RouterRefreshNotifier(ref);
  final GoRouter goRouter = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (BuildContext context, GoRouterState state) => _redirect(ref, state),
    routes: _buildRoutes(ref),
  );
  ref.onDispose(() {
    refreshNotifier.dispose();
    goRouter.dispose();
  });
  return goRouter;
}

String? _redirect(Ref ref, GoRouterState state) {
  final AsyncValue<Staff?> asyncUser = ref.read(currentUserProvider);
  final String location = state.matchedLocation;

  if (asyncUser.isLoading) {
    if (location == AppRoutes.login || location == AppRoutes.register) {
      return null;
    }
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }

  if (asyncUser.hasError) {
    if (location == AppRoutes.login || location == AppRoutes.register) {
      return null;
    }
    return AppRoutes.login;
  }

  final Staff? user = asyncUser.value;
  if (user == null || !user.isActive) {
    return (location == AppRoutes.login || location == AppRoutes.register) ? null : AppRoutes.login;
  }

  if (_isPublicRoute(location)) {
    return _homeRouteForRole(user.role);
  }

  // Centralized role-based route authorization — defense in depth.
  if (_isAdminRoute(location) && user.role != UserRole.superAdmin) {
    return _homeRouteForRole(user.role);
  }

  return null;
}

bool _isPublicRoute(String location) =>
    location == AppRoutes.login ||
    location == AppRoutes.register ||
    location == AppRoutes.splash;

bool _isAdminRoute(String location) =>
    location.startsWith('/admin');

String _homeRouteForRole(UserRole role) => switch (role) {
      UserRole.doctor => AppRoutes.schedule,
      UserRole.receptionist => AppRoutes.allAppointments,
      UserRole.superAdmin => AppRoutes.schedule,
    };

List<RouteBase> _buildRoutes(Ref ref) {
  return [
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (_, __) => const NoTransitionPage(child: SplashScreen()),
    ),
    GoRoute(
      path: AppRoutes.login,
      pageBuilder: (_, __) => const NoTransitionPage(child: LoginScreen()),
    ),
    GoRoute(
      path: AppRoutes.register,
      pageBuilder: (_, __) => const NoTransitionPage(child: RegisterScreen()),
    ),
    GoRoute(
      path: AppRoutes.search,
      pageBuilder: (_, __) => const NoTransitionPage(child: PatientSearchScreen()),
    ),

    GoRoute(
      path: AppRoutes.editPatient,
      pageBuilder: (_, GoRouterState state) {
        final String patientId = state.pathParameters['id'] ?? '';
        final Patient? patient = state.extra as Patient?;
        return NoTransitionPage(child: EditPatientScreen(patientId: patientId, patient: patient));
      },
    ),
    GoRoute(
      path: AppRoutes.recordPayment,
      pageBuilder: (_, GoRouterState state) {
        final String patientId = state.pathParameters['id'] ?? '';
        return NoTransitionPage(child: RecordPaymentScreen(patientId: patientId));
      },
    ),
    GoRoute(
      path: AppRoutes.newPatient,
      pageBuilder: (_, __) => const NoTransitionPage(child: NewPatientScreen()),
    ),
    GoRoute(
      path: AppRoutes.newAppointment,
      pageBuilder: (_, GoRouterState state) {
        final String? patientId = state.uri.queryParameters['patientId'] ??
            (state.extra is Patient
                ? (state.extra as Patient).id
                : (state.extra is String ? state.extra as String : null));
        return NoTransitionPage(child: NewAppointmentScreen(preselectedPatientId: patientId));
      },
    ),

    GoRoute(
      path: AppRoutes.editAppointment,
      pageBuilder: (_, GoRouterState state) {
        final String appointmentId = state.pathParameters['id'] ?? '';
        return NoTransitionPage(child: EditAppointmentScreen(appointmentId: appointmentId));
      },
    ),
    GoRoute(
      path: AppRoutes.addVisitNotes,
      pageBuilder: (_, GoRouterState state) {
        final String appointmentId = state.pathParameters['id'] ?? '';
        return NoTransitionPage(child: AddVisitNotesScreen(appointmentId: appointmentId));
      },
    ),

    GoRoute(
      path: AppRoutes.staffForm,
      pageBuilder: (_, GoRouterState state) {
        final Staff? staff = state.extra as Staff?;
        return NoTransitionPage(child: StaffFormScreen(staff: staff));
      },
    ),
    ShellRoute(
      pageBuilder: (BuildContext context, GoRouterState state, Widget child) {
        final Staff? user = ref.read(currentUserProvider).value;
        final String role = user?.role.dbValue ?? 'receptionist';
        final int activeIndex = _resolveActiveIndex(role, state.matchedLocation);
        final bool isSubPage = _isSubPage(state.matchedLocation);

        return NoTransitionPage(
          child: _SessionGuard(
            child: AppShell(
              userRole: role,
              currentTabIndex: activeIndex,
              onTabSelected: (int index) => _onTabSelected(context, role, index),
              showBrandedAppBar: !isSubPage,
              child: child,
            ),
          ),
        );
      },
      routes: [
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: ReceptionistAppointmentsScreen()),
        ),
        GoRoute(
          path: AppRoutes.adminHub,
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: AdminHubScreen()),
        ),
        GoRoute(
          path: AppRoutes.schedule,
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: DoctorScheduleScreen()),
        ),
        GoRoute(
          path: AppRoutes.myPatients,
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: MyPatientsScreen()),
        ),
        GoRoute(
          path: AppRoutes.patientList,
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: PatientListScreen()),
        ),
        GoRoute(
          path: AppRoutes.allAppointments,
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: ReceptionistAppointmentsScreen()),
        ),
        GoRoute(
          path: AppRoutes.receptionistProfile,
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: ReceptionistProfileScreen()),
        ),
        GoRoute(
          path: AppRoutes.doctorProfile,
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: DoctorProfileScreen()),
        ),
        GoRoute(
          path: AppRoutes.reports,
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: AnalyticsScreen()),
        ),
        GoRoute(
          path: AppRoutes.patientDetail,
          pageBuilder: (_, GoRouterState state) {
            final String patientId = state.pathParameters['id'] ?? '';
            return NoTransitionPage(child: PatientDetailScreen(patientId: patientId));
          },
        ),
        GoRoute(
          path: AppRoutes.appointmentDetail,
          pageBuilder: (_, GoRouterState state) {
            final String appointmentId = state.pathParameters['id'] ?? '';
            return NoTransitionPage(child: AppointmentDetailScreen(appointmentId: appointmentId));
          },
        ),
        GoRoute(
          path: AppRoutes.visitDetail,
          pageBuilder: (_, GoRouterState state) {
            final String appointmentId = state.pathParameters['id'] ?? '';
            return NoTransitionPage(child: VisitDetailScreen(appointmentId: appointmentId));
          },
        ),
        GoRoute(
          path: AppRoutes.doctorHistory,
          pageBuilder: (_, __) => const NoTransitionPage(child: DoctorHistoryScreen()),
        ),
        GoRoute(
          path: AppRoutes.staffList,
          pageBuilder: (_, __) => const NoTransitionPage(child: StaffListScreen()),
        ),
        GoRoute(
          path: AppRoutes.doctorApplications,
          pageBuilder: (_, __) => const NoTransitionPage(child: DoctorApplicationsScreen()),
        ),
        GoRoute(
          path: AppRoutes.clinicSettings,
          pageBuilder: (_, __) => const NoTransitionPage(child: ClinicSettingsScreen()),
        ),
      ],
    ),
  ];
}

int _resolveActiveIndex(String role, String location) {
  switch (role) {
    case 'doctor':
      if (location == AppRoutes.doctorProfile || location == AppRoutes.doctorHistory) return 2;
      if (location == AppRoutes.myPatients || location == AppRoutes.patientList || location.startsWith('/patient/')) return 1;
      if (location == AppRoutes.schedule || location.startsWith('/appointment/') || location.startsWith('/visit/')) return 0;
      return 0; // my schedule
    case 'super_admin':
      if (location == AppRoutes.reports) return 0;
      if (location == AppRoutes.adminHub ||
          location == AppRoutes.doctorHistory ||
          location == AppRoutes.staffList ||
          location == AppRoutes.doctorApplications ||
          location == AppRoutes.clinicSettings ||
          location.startsWith('/admin/')) {
        return 4;
      }
      if (location == AppRoutes.patientList || location.startsWith('/patient/')) return 3;
      if (location == AppRoutes.schedule) return 2;
      if (location == AppRoutes.allAppointments ||
          location.startsWith('/appointment/') ||
          location.startsWith('/visit/')) {
        return 1;
      }
      return 0;
    case 'receptionist':
    default:
      if (location == AppRoutes.receptionistProfile) return 2;
      if (location == AppRoutes.patientList || location.startsWith('/patient/')) return 1;
      if (location == AppRoutes.allAppointments ||
          location.startsWith('/appointment/') ||
          location.startsWith('/visit/')) {
        return 0;
      }
      return 0; // appts (allAppointments)
  }
}

/// Returns true when the matched route renders inside the shell but carries
/// its own [Scaffold] + [AppBar] (i.e. detail/management sub-pages). The shell
/// hides its branded AppBar for these so the two do not stack.
bool _isSubPage(String location) {
  if (location.startsWith('/appointment/') &&
      !location.endsWith('/edit') &&
      !location.endsWith('/notes')) {
    return true;
  }
  if (location.startsWith('/visit/')) {
    return true;
  }
  if (location.startsWith('/patient/') &&
      !location.endsWith('/edit') &&
      !location.endsWith('/pay')) {
    return true;
  }
  if (location == AppRoutes.doctorHistory ||
      location == AppRoutes.staffList ||
      location == AppRoutes.doctorApplications ||
      location == AppRoutes.clinicSettings) {
    return true;
  }
  return false;
}

/// Watches [currentUserProvider] and force-redirects to login when the
/// current user's account is deactivated mid-session.
///
/// The GoRouter redirect guard (line 88) already catches inactive users on
/// navigation transitions. This widget catches the transition itself — when
/// an admin deactivates an account and the provider rebuilds with
/// `isActive == false`, we push the user to login immediately without
/// waiting for the next navigation event.
class _SessionGuard extends ConsumerWidget {
  const _SessionGuard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<Staff?>>(currentUserProvider, (previous, next) {
      final Staff? prevUser = previous?.value;
      final Staff? nextUser = next.value;
      // Only redirect when a previously-active user becomes inactive.
      // Don't redirect during initial load (prevUser null) or when the
      // user was already null/inactive.
      if (prevUser != null &&
          prevUser.isActive &&
          nextUser != null &&
          !nextUser.isActive) {
        context.go(AppRoutes.login);
      }
    });
    return child;
  }
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
          context.go(AppRoutes.schedule);
        case 3:
          context.go(AppRoutes.patientList);
        case 4:
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
