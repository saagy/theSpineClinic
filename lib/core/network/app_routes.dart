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
  static const String schedule = '/schedule';

  /// Boot-time loading overlay during auth resolution.
  static const String splash = '/splash';

  /// Patient search screen (protected, full-screen without shell).
  static const String search = '/search';

  /// Patient detail screen (protected, full-screen without shell).
  static const String patientDetail = '/patient/:id';
}
