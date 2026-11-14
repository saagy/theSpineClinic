/// Centralised route path constants for the GoRouter configuration.
///
/// All route path strings are defined here to avoid hardcoding
/// across the router, navigation actions, and deep-link handlers.
/// Rule 7 — no hardcoded strings.
library;

/// Static route path constants used by [GoRouter].
abstract final class AppRoutes {
  static const String billing = '/billing';

  /// Service catalog for payment receptionists and admins (full screen).
  static const String serviceCatalog = '/billing/services';

  /// Add (`new`) or edit a catalog service.
  static const String serviceForm = '/billing/services/:id';

  /// New invoice for a patient (full screen).
  static const String newInvoice = '/patient/:id/invoices/new';

  /// Location of the new-invoice form for [patientId].
  static String newInvoiceLocation(String patientId) =>
      newInvoice.replaceFirst(':id', Uri.encodeComponent(patientId));

  /// One invoice: a side panel on wide windows, a full screen on narrow ones.
  static const String invoiceDetail = '/patient/:id/invoices/:invoiceId';

  /// Refund form for an invoice (full screen).
  static const String invoiceRefund = '/patient/:id/invoices/:invoiceId/refund';

  /// Discount form for an issued invoice (full screen).
  static const String invoiceDiscount = '/patient/:id/invoices/:invoiceId/discount';

  /// Correction form that replaces an invoice (full screen).
  static const String invoiceCorrect = '/patient/:id/invoices/:invoiceId/correct';

  static String invoiceDetailLocation(String patientId, String invoiceId) =>
      '/patient/${Uri.encodeComponent(patientId)}/invoices/${Uri.encodeComponent(invoiceId)}';

  static String invoiceRefundLocation(String patientId, String invoiceId) =>
      '${invoiceDetailLocation(patientId, invoiceId)}/refund';

  static String invoiceDiscountLocation(String patientId, String invoiceId) =>
      '${invoiceDetailLocation(patientId, invoiceId)}/discount';

  static String invoiceCorrectLocation(String patientId, String invoiceId) =>
      '${invoiceDetailLocation(patientId, invoiceId)}/correct';

  /// Location of the service editor; pass null to add a service.
  static String serviceFormLocation(String? serviceId) =>
      '$serviceCatalog/${Uri.encodeComponent(serviceId ?? 'new')}';
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

  /// Location of a patient's record, opened on [tab] (a workspace tab name
  /// such as `payments`) when given.
  static String patientLocation(String patientId, {String? tab}) {
    final String location = patientDetail.replaceFirst(':id', Uri.encodeComponent(patientId));
    return tab == null ? location : '$location?tab=${Uri.encodeQueryComponent(tab)}';
  }

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

  /// Self-service profile editing for every authenticated staff role.
  static const String editProfile = '/profile/edit';

  /// Separate password step under the account editor.
  static const String profilePassword = '/profile/edit/password';

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

  /// Retired Analytics URL; redirects to Admin for saved links.
  static const String reports = '/admin/reports';
}
