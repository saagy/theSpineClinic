part of 'router.dart';

List<RouteBase> _buildRoutes(Ref ref) => [
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
    pageBuilder: (_, __) =>
        const NoTransitionPage(child: PatientSearchScreen()),
  ),
  GoRoute(
    path: AppRoutes.editPatient,
    pageBuilder: (_, GoRouterState state) {
      final String patientId = state.pathParameters['id'] ?? '';
      final Patient? patient = state.extra as Patient?;
      return NoTransitionPage(
        child: EditPatientScreen(patientId: patientId, patient: patient),
      );
    },
  ),
  GoRoute(
    path: AppRoutes.recordPayment,
    pageBuilder: (_, GoRouterState state) => NoTransitionPage(
      child: RecordPaymentScreen(patientId: state.pathParameters['id'] ?? ''),
    ),
  ),
  GoRoute(
    path: AppRoutes.newPatient,
    pageBuilder: (_, __) => const NoTransitionPage(child: NewPatientScreen()),
  ),
  GoRoute(
    path: AppRoutes.newAppointment,
    pageBuilder: (_, GoRouterState state) {
      final String? patientId =
          state.uri.queryParameters['patientId'] ??
          (state.extra is Patient
              ? (state.extra as Patient).id
              : (state.extra is String ? state.extra as String : null));
      final DateTime? date = DateTime.tryParse(
        state.uri.queryParameters['date'] ?? '',
      );
      final DateTime? expectedNextVisitDate = DateTime.tryParse(
        state.uri.queryParameters['dueDate'] ?? '',
      );
      return NoTransitionPage(
        child: NewAppointmentScreen(
          preselectedPatientId: patientId,
          preselectedDate: date,
          preselectedDoctorId: state.uri.queryParameters['doctorId'],
          expectedNextVisitDate: expectedNextVisitDate,
        ),
      );
    },
  ),
  GoRoute(
    path: AppRoutes.editAppointment,
    pageBuilder: (_, GoRouterState state) => NoTransitionPage(
      child: EditAppointmentScreen(
        appointmentId: state.pathParameters['id'] ?? '',
      ),
    ),
  ),
  GoRoute(
    path: AppRoutes.addVisitNotes,
    pageBuilder: (_, GoRouterState state) => NoTransitionPage(
      child: AddVisitNotesScreen(
        appointmentId: state.pathParameters['id'] ?? '',
      ),
    ),
  ),
  GoRoute(
    path: AppRoutes.staffForm,
    pageBuilder: (_, GoRouterState state) =>
        NoTransitionPage(child: StaffFormScreen(staff: state.extra as Staff?)),
  ),
  ShellRoute(
    pageBuilder: (BuildContext context, GoRouterState state, Widget child) {
      final String role =
          ref.read(currentUserProvider).value?.role.dbValue ??
          UserRole.receptionist.dbValue;
      return NoTransitionPage(
        child: _SessionGuard(
          child: AppShell(
            userRole: role,
            currentTabIndex: _resolveActiveIndex(role, state.uri.path),
            onTabSelected: (int index) => _onTabSelected(context, role, index),
            child: child,
          ),
        ),
      );
    },
    routes: _shellRoutes,
  ),
];

final List<RouteBase> _shellRoutes = [
  GoRoute(
    path: AppRoutes.home,
    pageBuilder: (_, __) =>
        const NoTransitionPage(child: ReceptionistAppointmentsScreen()),
  ),
  GoRoute(
    path: AppRoutes.adminHub,
    pageBuilder: (_, __) => const NoTransitionPage(child: AdminHubScreen()),
  ),
  GoRoute(
    path: AppRoutes.schedule,
    pageBuilder: (_, __) =>
        const NoTransitionPage(child: DoctorScheduleScreen()),
  ),
  GoRoute(
    path: AppRoutes.myPatients,
    pageBuilder: (_, __) => const NoTransitionPage(child: MyPatientsScreen()),
  ),
  GoRoute(
    path: AppRoutes.patientList,
    pageBuilder: (_, __) => const NoTransitionPage(child: PatientListScreen()),
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
    pageBuilder: (_, __) => const NoTransitionPage(child: AnalyticsScreen()),
  ),
  GoRoute(
    path: AppRoutes.patientDetail,
    pageBuilder: (_, GoRouterState state) => NoTransitionPage(
      child: PatientDetailScreen(patientId: state.pathParameters['id'] ?? ''),
    ),
    routes: [
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.patientDocumentViewer,
        pageBuilder: (_, GoRouterState state) => NoTransitionPage(
          child: PatientDocumentViewerScreen(
            patientId: state.pathParameters['id'] ?? '',
            documentId: state.pathParameters['documentId'] ?? '',
          ),
        ),
      ),
    ],
  ),
  GoRoute(
    path: AppRoutes.appointmentDetail,
    pageBuilder: (_, GoRouterState state) => NoTransitionPage(
      child: AppointmentDetailScreen(
        appointmentId: state.pathParameters['id'] ?? '',
      ),
    ),
  ),
  GoRoute(
    path: AppRoutes.visitDetail,
    pageBuilder: (_, GoRouterState state) => NoTransitionPage(
      child: VisitDetailScreen(appointmentId: state.pathParameters['id'] ?? ''),
    ),
  ),
  GoRoute(
    path: AppRoutes.doctorHistory,
    pageBuilder: (_, __) =>
        const NoTransitionPage(child: DoctorHistoryScreen()),
  ),
  GoRoute(
    path: AppRoutes.staffList,
    pageBuilder: (_, __) => const NoTransitionPage(child: StaffListScreen()),
  ),
];
