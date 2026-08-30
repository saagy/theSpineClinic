part of 'router.dart';

List<RouteBase> _buildRoutes(Ref ref) => [
  GoRoute(
    path: AppRoutes.splash,
    pageBuilder: (_, state) => fadePage(key: state.pageKey, child: const SplashScreen()),
  ),
  GoRoute(
    path: AppRoutes.login,
    pageBuilder: (_, state) => fadePage(key: state.pageKey, child: const LoginScreen()),
  ),
  GoRoute(
    path: AppRoutes.register,
    pageBuilder: (_, state) => appPage(key: state.pageKey, child: const RegisterScreen()),
  ),
  GoRoute(
    path: AppRoutes.search,
    pageBuilder: (_, state) =>
        appPage(key: state.pageKey, child: const PatientSearchScreen()),
  ),
  GoRoute(
    path: AppRoutes.editPatient,
    pageBuilder: (_, state) => appPage(
      key: state.pageKey,
      child: EditPatientScreen(
        patientId: state.pathParameters['id'] ?? '',
        patient: state.extra as Patient?,
      ),
    ),
  ),
  GoRoute(
    path: AppRoutes.newPatientProgram,
    pageBuilder: (_, state) => appPage(
      key: state.pageKey,
      child: ProgramFormScreen(
        patientId: state.pathParameters['id'] ?? '',
      ),
    ),
  ),
  GoRoute(
    path: AppRoutes.patientProgramDetail,
    pageBuilder: (_, state) => appPage(
      key: state.pageKey,
      child: ProgramDetailScreen(
        patientId: state.pathParameters['id'] ?? '',
        programId: state.pathParameters['programId'] ?? '',
        initialProgram: state.extra as PatientProgram?,
      ),
    ),
  ),
  GoRoute(
    path: AppRoutes.editPatientProgram,
    pageBuilder: (_, state) => appPage(
      key: state.pageKey,
      child: ProgramFormScreen(
        patientId: state.pathParameters['id'] ?? '',
        program: state.extra as PatientProgram?,
      ),
    ),
  ),
  GoRoute(
    path: AppRoutes.recordPayment,
    pageBuilder: (_, state) => appPage(
      key: state.pageKey,
      child: RecordPaymentScreen(patientId: state.pathParameters['id'] ?? ''),
    ),
  ),
  GoRoute(
    path: AppRoutes.newPatient,
    pageBuilder: (_, state) =>
        appPage(key: state.pageKey, child: const NewPatientScreen()),
  ),
  GoRoute(
    path: AppRoutes.newAppointment,
    pageBuilder: (_, state) => appPage(
      key: state.pageKey,
      child: NewAppointmentScreen(
        preselectedPatientId: state.uri.queryParameters['patientId'] ??
            (state.extra is Patient
                ? (state.extra as Patient).id
                : (state.extra is String ? state.extra as String : null)),
        preselectedDate: DateTime.tryParse(state.uri.queryParameters['date'] ?? ''),
        preselectedDoctorId: state.uri.queryParameters['doctorId'],
        expectedNextVisitDate:
            DateTime.tryParse(state.uri.queryParameters['dueDate'] ?? ''),
      ),
    ),
  ),
  GoRoute(
    path: AppRoutes.editAppointment,
    pageBuilder: (_, state) => appPage(
      key: state.pageKey,
      child: EditAppointmentScreen(
        appointmentId: state.pathParameters['id'] ?? '',
      ),
    ),
  ),
  GoRoute(
    path: AppRoutes.addVisitNotes,
    pageBuilder: (_, state) => appPage(
      key: state.pageKey,
      child: AddVisitNotesScreen(appointmentId: state.pathParameters['id'] ?? ''),
    ),
  ),
  GoRoute(
    path: AppRoutes.doctorReplacement,
    pageBuilder: (_, state) => appPage(
      key: state.pageKey,
      child: DoctorReplacementScreen(
        args: state.extra as DoctorReplacementArgs?,
        absentDoctorId: state.uri.queryParameters['absentDoctorId'],
        date: DateTime.tryParse(state.uri.queryParameters['date'] ?? ''),
      ),
    ),
  ),
  GoRoute(
    path: AppRoutes.staffForm,
    pageBuilder: (_, state) => appPage(
      key: state.pageKey,
      child: StaffFormScreen(staff: state.extra as Staff?),
    ),
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
    pageBuilder: (_, GoRouterState state) => appPage(
      key: state.pageKey,
      child: PatientDetailScreen(patientId: state.pathParameters['id'] ?? ''),
    ),
    routes: [
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.patientDocumentViewer,
        pageBuilder: (_, GoRouterState state) => appPage(
          key: state.pageKey,
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
    pageBuilder: (_, GoRouterState state) => appPage(
      key: state.pageKey,
      child: AppointmentDetailScreen(
        appointmentId: state.pathParameters['id'] ?? '',
      ),
    ),
  ),
  GoRoute(
    path: AppRoutes.visitDetail,
    pageBuilder: (_, GoRouterState state) => appPage(
      key: state.pageKey,
      child: VisitDetailScreen(appointmentId: state.pathParameters['id'] ?? ''),
    ),
  ),
  GoRoute(
    path: AppRoutes.doctorHistory,
    pageBuilder: (_, state) => appPage(
      key: state.pageKey,
      child: const DoctorHistoryScreen(),
    ),
  ),
  GoRoute(
    path: AppRoutes.staffList,
    pageBuilder: (_, state) => appPage(
      key: state.pageKey,
      child: const StaffListScreen(),
    ),
  ),
];
