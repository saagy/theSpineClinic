/// Centralised route path constants for the GoRouter configuration.
///
/// All route path strings are defined here to avoid hardcoding
/// across the router, navigation actions, and deep-link handlers.
/// Rule 7 — no hardcoded strings.
library;

/// Static route path constants used by [GoRouter].
abstract final class AppRoutes {
  /// Authentication entry point for all roles.
  static const String login = '/login';

  /// Public doctor self-registration form.
  static const String register = '/register';

  /// Legacy receptionist landing route.
  static const String home = '/home';

  /// Landing screen for doctors (daily schedule view).
  static const String schedule = '/doctor/schedule';

  /// Boot-time loading overlay during auth resolution.
  static const String splash = '/splash';

  /// Patient search screen (protected, full-screen without shell).
  static const String search = '/search';

  /// Patient detail screen (protected, shell sub-page with its own AppBar).
  static const String patientDetail = '/patient/:id';

  /// Full-screen patient document viewer nested under patient detail.
  static const String patientDocumentViewer = 'document/:documentId';

  /// Builds the browser-safe location for a patient document viewer.
  static String patientDocumentViewerLocation({
    required String patientId,
    required String documentId,
  }) {
    final String patientLocation = patientDetail.replaceFirst(
      ':id',
      Uri.encodeComponent(patientId),
    );
    final String documentLocation = patientDocumentViewer.replaceFirst(
      ':documentId',
      Uri.encodeComponent(documentId),
    );
    return '$patientLocation/$documentLocation';
  }

  /// Edit patient screen (protected, full-screen without shell).
  static const String editPatient = '/patient/:id/edit';

  /// New patient rehabilitation program (protected, full-screen without shell).
  static const String newPatientProgram = '/patient/:id/programs/new';

  /// Patient rehabilitation program detail screen.
  static const String patientProgramDetail = '/patient/:id/programs/:programId';

  /// Program gallery lightbox viewer for clinical scans.
  static const String programGallery = 'gallery';

  /// Builds the location for a program gallery lightbox viewer.
  static String programGalleryLocation({
    required String patientId,
    required String programId,
    int initialIndex = 0,
  }) {
    final String patientLocation = patientDetail.replaceFirst(
      ':id',
      Uri.encodeComponent(patientId),
    );
    final String programLocation =
        'programs/${Uri.encodeComponent(programId)}/$programGallery';
    return initialIndex > 0
        ? '$patientLocation/$programLocation?index=$initialIndex'
        : '$patientLocation/$programLocation';
  }

  /// Edit patient rehabilitation program screen.
  static const String editPatientProgram =
      '/patient/:id/programs/:programId/edit';

  /// Record payment screen (protected, full-screen without shell).
  static const String recordPayment = '/patient/:id/pay';

  /// New patient registration screen (protected, full-screen without shell).
  static const String newPatient = '/new-patient';

  /// New appointment booking screen (protected, full-screen without shell).
  static const String newAppointment = '/new-appointment';

  /// Appointment detail screen (protected, shell sub-page with its own AppBar).
  static const String appointmentDetail = '/appointment/:id';

  /// Edit appointment screen (protected, full-screen without shell).
  static const String editAppointment = '/appointment/:id/edit';

  /// Add/edit visit notes screen (protected, full-screen without shell).
  static const String addVisitNotes = '/appointment/:id/notes';

  /// Doctor replacement screen (protected, full-screen without shell).
  static const String doctorReplacement = '/appointment/replace';

  /// Builds the location for the doctor replacement screen.
  static String doctorReplacementLocation({
    String? absentDoctorId,
    DateTime? date,
  }) {
    final Map<String, String> queryParams = {};
    if (absentDoctorId != null) {
      queryParams['absentDoctorId'] = absentDoctorId;
    }
    if (date != null) {
      queryParams['date'] =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    }
    if (queryParams.isEmpty) return doctorReplacement;
    return Uri(path: doctorReplacement, queryParameters: queryParams).toString();
  }

  /// Visit detail screen (protected, shell sub-page with its own AppBar).
  static const String visitDetail = '/visit/:id';

  /// Doctor's assigned patients roster view.
  static const String myPatients = '/doctor/my-patients';

  /// All-appointments management screen (admin & receptionist).
  static const String allAppointments = '/appointments';

  /// Patient list shell route for receptionist and admin roles.
  static const String patientList = '/patients';

  /// Receptionist profile/settings shell route.
  static const String receptionistProfile = '/receptionist/profile';

  /// Doctor profile shell route.
  static const String doctorProfile = '/doctor/profile';

  /// Doctor historic appointments view (shell sub-page with its own AppBar).
  static const String doctorHistory = '/doctor/history';

  /// Admin staff list screen (shell sub-page with its own AppBar).
  static const String staffList = '/admin/staff';

  /// Admin staff form screen (create/edit).
  static const String staffForm = '/admin/staff/form';

  /// Admin central hub dashboard.
  static const String adminHub = '/admin';

  /// Clinic statistical reports and analytics dashboard.
  static const String reports = '/admin/reports';
}
