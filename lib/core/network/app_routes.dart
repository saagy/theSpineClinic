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
}
