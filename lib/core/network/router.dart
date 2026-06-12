/// Centralized GoRouter configuration with role-based redirect guards.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/doctor_history_screen.dart';
import 'package:spine_clinic_app/features/auth/presentation/doctor_profile_screen.dart';
import 'package:spine_clinic_app/features/auth/presentation/doctor_register_screen.dart';
import 'package:spine_clinic_app/features/auth/presentation/login_screen.dart';
import 'package:spine_clinic_app/features/auth/presentation/receptionist_profile_screen.dart';
import 'package:spine_clinic_app/features/auth/presentation/splash_screen.dart';
import 'package:spine_clinic_app/features/appointment/presentation/home_screen.dart';
import 'package:spine_clinic_app/features/appointment/presentation/new_appointment_screen.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_detail_screen.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/edit_patient_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/my_patients_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/new_patient_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_detail_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_list_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_search_screen.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_screen.dart';
import 'package:spine_clinic_app/features/appointment/presentation/my_schedule_screen.dart';
import 'package:spine_clinic_app/features/replacements/presentation/replacement_patients_screen.dart';
import 'package:spine_clinic_app/shared/widgets/app_shell.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/add_visit_notes_screen.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/visit_detail_screen.dart';
import 'package:spine_clinic_app/features/replacements/presentation/manage_replacement_screen.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_form_screen.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_list_screen.dart';
import 'package:spine_clinic_app/features/admin/presentation/admin_hub_screen.dart';
import 'package:spine_clinic_app/features/admin/presentation/analytics_screen.dart';
import 'package:spine_clinic_app/features/admin/presentation/doctor_applications_screen.dart';
import 'package:spine_clinic_app/features/admin/presentation/clinic_settings_screen.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointments_shell.dart';

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
      UserRole.superAdmin => AppRoutes.allAppointments,
    };

List<RouteBase> _buildRoutes(Ref ref) {
  return [
    GoRoute(
      path: AppRoutes.splash,
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (_, __) => const DoctorRegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.search,
      builder: (_, __) => const PatientSearchScreen(),
    ),
    GoRoute(
      path: AppRoutes.patientDetail,
      builder: (_, GoRouterState state) {
        final String patientId = state.pathParameters['id'] ?? '';
        return PatientDetailScreen(patientId: patientId);
      },
    ),
    GoRoute(
      path: AppRoutes.editPatient,
      builder: (_, GoRouterState state) {
        final String patientId = state.pathParameters['id'] ?? '';
        final Patient? patient = state.extra as Patient?;
        return EditPatientScreen(patientId: patientId, patient: patient);
      },
    ),
    GoRoute(
      path: AppRoutes.recordPayment,
      builder: (_, GoRouterState state) {
        final String patientId = state.pathParameters['id'] ?? '';
        return RecordPaymentScreen(patientId: patientId);
      },
    ),
    GoRoute(
      path: AppRoutes.newPatient,
      builder: (_, __) => const NewPatientScreen(),
    ),
    GoRoute(
      path: AppRoutes.newAppointment,
      builder: (_, GoRouterState state) {
        final String? patientId = state.uri.queryParameters['patientId'];
        return NewAppointmentScreen(preselectedPatientId: patientId);
      },
    ),
    GoRoute(
      path: AppRoutes.appointmentDetail,
      builder: (_, GoRouterState state) {
        final String appointmentId = state.pathParameters['id'] ?? '';
        return AppointmentDetailScreen(appointmentId: appointmentId);
      },
    ),
    GoRoute(
      path: AppRoutes.addVisitNotes,
      builder: (_, GoRouterState state) {
        final String appointmentId = state.pathParameters['id'] ?? '';
        return AddVisitNotesScreen(appointmentId: appointmentId);
      },
    ),
    GoRoute(
      path: AppRoutes.visitDetail,
      builder: (_, GoRouterState state) {
        final String appointmentId = state.pathParameters['id'] ?? '';
        return VisitDetailScreen(appointmentId: appointmentId);
      },
    ),
    GoRoute(
      path: AppRoutes.doctorHistory,
      builder: (_, __) => const DoctorHistoryScreen(),
    ),
    GoRoute(
      path: AppRoutes.manageReplacement,
      builder: (_, __) => const ManageReplacementScreen(),
    ),
    GoRoute(
      path: AppRoutes.staffList,
      builder: (_, __) => const StaffListScreen(),
    ),
    GoRoute(
      path: AppRoutes.staffForm,
      builder: (_, GoRouterState state) {
        final Staff? staff = state.extra as Staff?;
        return StaffFormScreen(staff: staff);
      },
    ),
    GoRoute(
      path: AppRoutes.doctorApplications,
      builder: (_, __) => const DoctorApplicationsScreen(),
    ),
    GoRoute(
      path: AppRoutes.clinicSettings,
      builder: (_, __) => const ClinicSettingsScreen(),
    ),
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        final Staff? user = ref.read(currentUserProvider).value;
        final String role = user?.role.dbValue ?? 'receptionist';
        final int activeIndex = _resolveActiveIndex(role, state.matchedLocation);

        return AppShell(
          title: AppStrings.appName,
          userRole: role,
          currentTabIndex: activeIndex,
          onTabSelected: (int index) => _onTabSelected(context, role, index),
          actions: state.matchedLocation == AppRoutes.allAppointments
              ? [
                  IconButton(
                    icon: const Icon(Icons.search_rounded),
                    onPressed: () => context.push(AppRoutes.search),
                  ),
                ]
              : null,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (_, __) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminHub,
          builder: (_, __) => const AdminHubScreen(),
        ),
        GoRoute(
          path: AppRoutes.schedule,
          builder: (_, __) => const MyScheduleScreen(),
        ),
        GoRoute(
          path: AppRoutes.myPatients,
          builder: (_, __) => const MyPatientsScreen(),
        ),
        GoRoute(
          path: AppRoutes.replacements,
          builder: (_, __) => const ReplacementPatientsScreen(),
        ),
        GoRoute(
          path: AppRoutes.patientList,
          builder: (_, __) => const PatientListScreen(),
        ),
        GoRoute(
          path: AppRoutes.allAppointments,
          builder: (_, __) => const AppointmentsShell(),
        ),
        GoRoute(
          path: AppRoutes.receptionistProfile,
          builder: (_, __) => const ReceptionistProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.doctorProfile,
          builder: (_, __) => const DoctorProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.reports,
          builder: (_, __) => const AnalyticsScreen(),
        ),
      ],
    ),
  ];
}

int _resolveActiveIndex(String role, String location) {
  switch (role) {
    case 'doctor':
      if (location == AppRoutes.doctorProfile) return 2;
      if (location == AppRoutes.myPatients) return 1;
      return 0; // my schedule
    case 'super_admin':
      if (location == AppRoutes.adminHub) return 4;
      if (location == AppRoutes.patientList) return 3;
      if (location == AppRoutes.schedule) return 2;
      if (location == AppRoutes.allAppointments) return 1;
      if (location == AppRoutes.reports) return 0;
      return 0;
    case 'receptionist':
    default:
      if (location == AppRoutes.receptionistProfile) return 2;
      if (location == AppRoutes.patientList) return 1;
      return 0; // appts (allAppointments)
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
