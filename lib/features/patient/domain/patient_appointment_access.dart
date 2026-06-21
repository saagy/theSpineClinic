/// Sealed result of a doctor's access evaluation for a patient's pill tap.
///
/// Three branches:
///   - [granted]: doctor may navigate to the patient detail screen.
///   - [expired]: doctor has no current relationship with this patient
///     and no appointments between them fall inside the access window.
///   - [notAuthenticated]: no user session is loaded; the pill is inert.
///
/// Rule 4 — sealed types only, no `dynamic`.
library;

sealed class PatientAppointmentAccess {
  const PatientAppointmentAccess();
}

/// Access is allowed; the screen may navigate.
final class Granted extends PatientAppointmentAccess {
  const Granted();
}

/// Access is denied because no relationship and no recent appointment
/// falls into the window. Shows a tooltip explaining the window.
final class AccessExpired extends PatientAppointmentAccess {
  const AccessExpired();
}

/// Access is denied because no authenticated user is loaded.
final class NotAuthenticated extends PatientAppointmentAccess {
  const NotAuthenticated();
}

PatientAppointmentAccess granted() => const Granted();
PatientAppointmentAccess expired() => const AccessExpired();
PatientAppointmentAccess notAuthenticated() => const NotAuthenticated();
