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

  /// Landing screen for receptionists and super admins.
  static const String home = '/home';

  /// Landing screen for doctors (daily schedule view).
  static const String schedule = '/doctor/schedule';

  /// Boot-time loading overlay during auth resolution.
  static const String splash = '/splash';

  /// Patient search screen (protected, full-screen without shell).
  static const String search = '/search';

  /// Patient detail screen (protected, full-screen without shell).
  static const String patientDetail = '/patient/:id';

  /// Edit patient screen (protected, full-screen without shell).
  static const String editPatient = '/patient/:id/edit';

  /// Record payment screen (protected, full-screen without shell).
  static const String recordPayment = '/patient/:id/pay';

  /// New patient registration screen (protected, full-screen without shell).
  static const String newPatient = '/new-patient';

  /// New appointment booking screen (protected, full-screen without shell).
  static const String newAppointment = '/new-appointment';

  /// Appointment detail screen (protected, full-screen without shell).
  static const String appointmentDetail = '/appointment/:id';

  /// Add/edit visit notes screen (protected, full-screen without shell).
  static const String addVisitNotes = '/appointment/:id/notes';

  /// Visit detail screen (protected, full-screen without shell).
  static const String visitDetail = '/visit/:id';

  /// Doctor's assigned patients roster view.
  static const String myPatients = '/doctor/my-patients';

  /// Doctor's coverage patients view.
  static const String replacements = '/doctor/replacements';

  /// Admin/receptionist doctor replacement management wizard.
  static const String manageReplacement = '/admin/replacements/manage';

  /// All-appointments management screen (admin & receptionist).
  static const String allAppointments = '/appointments';

  /// Patient list shell route for receptionist and admin roles.
  static const String patientList = '/patients';

  /// Receptionist profile/settings shell route.
  static const String receptionistProfile = '/receptionist/profile';

  /// Doctor profile shell route.
  static const String doctorProfile = '/doctor/profile';

  /// Doctor historic appointments full history view.
  static const String doctorHistory = '/doctor/history';

  /// Admin staff list screen.
  static const String staffList = '/admin/staff';

  /// Admin staff form screen (create/edit).
  static const String staffForm = '/admin/staff/form';

  /// Admin central hub dashboard.
  static const String adminHub = '/admin';

  /// Doctor registration applications management.
  static const String doctorApplications = '/admin/doctor-applications';

  /// Clinic global packages and configuration settings.
  static const String clinicSettings = '/admin/clinic-settings';

  /// Clinic statistical reports and analytics dashboard.
  static const String reports = '/admin/reports';
}
