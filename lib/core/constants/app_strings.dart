/// Centralised string constants for the Spine Clinic application.
///
/// Rule 7 — no hardcoded strings anywhere outside this file.
///
/// ## Error-message keys
///
/// Every `userMessageKey` emitted by [AppException] subtypes has a
/// matching entry here so that the presentation layer can resolve
/// a human-readable message via [AppStrings.fromKey].
library;

/// Application-wide string constants.
abstract final class AppStrings {
  // ──────────────────── App Identity ────────────────────

  static const String appName = 'Spine Clinic';
  static const String appTagline = 'Patient & Appointment Manager';

  // ──────────────────── Error Messages (userMessageKey) ─────
  //
  // Keys MUST stay in sync with the `userMessageKey` values in
  // `lib/core/errors/app_exception.dart`.

  // Auth errors
  static const String errorAuthGeneric =
      'Authentication failed. Please try again.';
  static const String errorAuthInvalidCredentials =
      'Invalid email or password. Please check your credentials.';
  static const String errorAuthEmailNotConfirmed =
      'Your email has not been confirmed yet. Please check your inbox.';
  static const String errorAuthUserAlreadyExists =
      'An account with this email already exists.';
  static const String errorAuthSessionExpired =
      'Your session has expired. Please sign in again.';

  // Database errors
  static const String errorDatabaseGeneric =
      'A database error occurred. Please try again later.';
  static const String errorDatabasePermissionDenied =
      'You do not have permission to perform this action.';
  static const String errorDatabaseReferenceNotFound =
      'The referenced record could not be found.';
  static const String errorDatabaseDuplicateRecord =
      'This record already exists. Duplicates are not allowed.';
  static const String errorDatabaseRequiredFieldMissing =
      'A required field is missing. Please fill in all fields.';
  static const String errorDatabaseValidationFailed =
      'Data validation failed. Please check your input.';
  static const String errorDatabaseQueryFailed =
      'The database query failed. Please try again.';

  // Network errors
  static const String errorNetworkGeneric =
      'Unable to reach the server. Check your internet connection.';

  // Unknown / catch-all
  static const String errorUnknown =
      'An unexpected error occurred. Please try again.';

  /// Maps a `userMessageKey` string (from [AppException]) to its
  /// user-facing message.
  ///
  /// Returns [errorUnknown] when the key is not recognised.
  static String fromKey(String key) => _keyMap[key] ?? errorUnknown;

  static const Map<String, String> _keyMap = {
    // Auth
    'error_auth_generic': errorAuthGeneric,
    'error_auth_invalid_credentials': errorAuthInvalidCredentials,
    'error_auth_email_not_confirmed': errorAuthEmailNotConfirmed,
    'error_auth_user_already_exists': errorAuthUserAlreadyExists,
    'error_auth_session_expired': errorAuthSessionExpired,
    // Database
    'error_database_generic': errorDatabaseGeneric,
    'error_database_permission_denied': errorDatabasePermissionDenied,
    'error_database_reference_not_found': errorDatabaseReferenceNotFound,
    'error_database_duplicate_record': errorDatabaseDuplicateRecord,
    'error_database_required_field_missing': errorDatabaseRequiredFieldMissing,
    'error_database_validation_failed': errorDatabaseValidationFailed,
    'error_database_query_failed': errorDatabaseQueryFailed,
    // Network
    'error_network_generic': errorNetworkGeneric,
    // Unknown
    'error_unknown': errorUnknown,
  };

  // ──────────────────── Common Form Labels ────────────────────

  static const String email = 'Email';
  static const String fullName = 'Full Name';
  static const String phone = 'Phone Number';

  // ──────────────────── Patient Search ────────────────────

  static const String searchPatients = 'Search patients\u2026';
  static const String searchPatientsPrompt =
      'Search by name or phone number';
  static const String all = 'All';

  // ──────────────────── Navigation / Sections ────────────────

  static const String patients = 'Patients';
  static const String appointments = 'Appointments';
  static const String payments = 'Payments';
  static const String staff = 'Staff';
  static const String settings = 'Settings';
  static const String reports = 'Reports';
  static const String replacements = 'Replacements';
  static const String dashboard = 'Dashboard';
  static const String medicalRecords = 'Medical Records';

  // ──────────────────── Common Actions ────────────────────

  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String add = 'Add';
  static const String search = 'Search';
  static const String filter = 'Filter';
  static const String retry = 'Retry';
  static const String confirm = 'Confirm';
  static const String close = 'Close';
  static const String submit = 'Submit';
  static const String upload = 'Upload';
  static const String download = 'Download';
  static const String approve = 'Approve';
  static const String reject = 'Reject';
  static const String viewDetails = 'View Details';
  static const String viewAll = 'View All';

  // ──────────────────── State Messages ────────────────────

  static const String loading = 'Loading…';
  static const String noData = 'No data available.';
  static const String noResults = 'No results found.';
  static const String noPatients = 'No patients registered yet.';
  static const String noAppointments = 'No appointments scheduled.';
  static const String noPayments = 'No payment records found.';
  static const String noStaff = 'No staff members found.';
  static const String noReplacements = 'No replacements for today.';
  static const String noDocuments = 'No documents uploaded.';

  // ──────────────────── Patient ────────────────────

  static const String registerPatient = 'Register Patient';
  static const String editPatient = 'Edit Patient';
  static const String patientDetails = 'Patient Details';
  static const String program = 'Program';
  static const String clinic = 'Clinic';
  static const String clinicTagamoa = 'Tagamoa';
  static const String clinicMasrElgedida = 'Masr El-Gedida';
  static const String packageBalance = 'Package Balance';
  static const String assignedDoctors = 'Assigned Doctors';

  // ──────────────────── Appointment ────────────────────

  static const String bookAppointment = 'Book Appointment';
  static const String appointmentDetails = 'Appointment Details';
  static const String session = 'Session';
  static const String gehazShadFakarat = 'Gehaz Shad Fakarat';
  static const String scheduled = 'Scheduled';
  static const String checkedIn = 'Checked In';
  static const String completed = 'Completed';
  static const String cancelled = 'Cancelled';
  static const String noShow = 'No Show';
  static const String usePackage = 'Use Package';
  static const String notes = 'Notes';
  static const String checkIn = 'Check In';
  static const String markComplete = 'Mark Complete';

  // ──────────────────── Replacement ────────────────────

  static const String initiateReplacement = 'Initiate Replacement';
  static const String absentDoctor = 'Absent Doctor';
  static const String coveringDoctor = 'Covering Doctor';
  static const String replacementDate = 'Replacement Date';
  static const String swapDoctors = 'Swap Doctors';

  // ──────────────────── Confirmation Dialogs ────────────────

  static const String confirmDelete =
      'Are you sure you want to delete this record?';
  static const String confirmCancel =
      'Are you sure you want to cancel this appointment?';
  static const String confirmSignOut =
      'Are you sure you want to sign out?';
  static const String actionCannotBeUndone = 'This action cannot be undone.';
}
