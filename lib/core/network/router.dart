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
import 'package:spine_clinic_app/features/auth/presentation/doctor_register_screen.dart';
import 'package:spine_clinic_app/features/auth/presentation/login_screen.dart';
import 'package:spine_clinic_app/features/auth/presentation/splash_screen.dart';
import 'package:spine_clinic_app/features/appointment/presentation/home_screen.dart';
import 'package:spine_clinic_app/features/appointment/presentation/new_appointment_screen.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_detail_screen.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/edit_patient_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/my_patients_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/new_patient_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_detail_screen.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_search_screen.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_screen.dart';
import 'package:spine_clinic_app/features/appointment/presentation/my_schedule_screen.dart';
import 'package:spine_clinic_app/features/replacements/presentation/replacement_patients_screen.dart';
import 'package:spine_clinic_app/shared/widgets/app_shell.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/add_visit_notes_screen.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/visit_detail_screen.dart';
import 'package:spine_clinic_app/features/replacements/presentation/manage_replacement_screen.dart';

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
    // If we're already on login/register, stay there and let the screen show its loading overlay.
    if (location == AppRoutes.login || location == AppRoutes.register) {
      return null;
    }
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }

  if (asyncUser.hasError) {
    // If there is an auth error, redirect to login unless already on a public form page.
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
  return null;
}

bool _isPublicRoute(String location) =>
    location == AppRoutes.login ||
    location == AppRoutes.register ||
    location == AppRoutes.splash;

String _homeRouteForRole(UserRole role) => switch (role) {
      UserRole.doctor => AppRoutes.schedule,
      UserRole.receptionist => AppRoutes.home,
      UserRole.superAdmin => AppRoutes.home,
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
      path: AppRoutes.manageReplacement,
      builder: (_, __) => const ManageReplacementScreen(),
    ),
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        final Staff? user = ref.read(currentUserProvider).value;
        final String role = user?.role.dbValue ?? 'receptionist';
        final int activeIndex = role == 'doctor'
            ? (state.matchedLocation == AppRoutes.myPatients
                ? 1
                : (state.matchedLocation == AppRoutes.replacements ? 2 : 0))
            : 0;

        return AppShell(
          title: AppStrings.appName,
          userRole: role,
          currentTabIndex: activeIndex,
          onTabSelected: (int index) {
            if (role == 'doctor') {
              switch (index) {
                case 0:
                  context.go(AppRoutes.schedule);
                  break;
                case 1:
                  context.go(AppRoutes.myPatients);
                  break;
                case 2:
                  context.go(AppRoutes.replacements);
                  break;
              }
            } else {
              switch (index) {
                case 0:
                  context.go(AppRoutes.home);
                  break;
              }
            }
          },
          actions: state.matchedLocation == AppRoutes.home
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
      ],
    ),
  ];
}
