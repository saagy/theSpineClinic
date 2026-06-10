/// Centralised string constants for the Spine Clinic application.
/// Rule 7 — no hardcoded strings anywhere outside this file.
library;

/// Application-wide string constants.
abstract final class AppStrings {
  // App Identity
  static const String appName = 'Spine Clinic';
  static const String appTagline = 'Patient & Appointment Manager';

  // Error Messages (userMessageKey)
  static const String errorAuthGeneric = 'Authentication failed. Please try again.';
  static const String errorAuthInvalidCredentials = 'Invalid email or password.';
  static const String errorAuthEmailNotConfirmed = 'Email not confirmed. Check your inbox.';
  static const String errorAuthUserAlreadyExists = 'An account with this email already exists.';
  static const String errorAuthSessionExpired = 'Your session has expired. Sign in again.';
  static const String errorAuthRateLimited = 'Too many attempts. Please wait a moment and try again.';

  static const String errorDatabaseGeneric = 'A database error occurred. Try again.';
  static const String errorDatabasePermissionDenied = 'You do not have permission.';
  static const String errorDatabaseReferenceNotFound = 'Referenced record not found.';
  static const String errorDatabaseDuplicateRecord = 'Record already exists.';
  static const String errorDatabaseRequiredFieldMissing = 'Required field is missing.';
  static const String errorDatabaseValidationFailed = 'Data validation failed.';
  static const String errorDatabaseQueryFailed = 'Database query failed. Try again.';
  static const String errorNetworkGeneric = 'Unable to reach server. Check connection.';
  static const String errorUnknown = 'An unexpected error occurred. Try again.';

  static String fromKey(String key) => _keyMap[key] ?? errorUnknown;

  static const Map<String, String> _keyMap = {
    'error_auth_generic': errorAuthGeneric,
    'error_auth_invalid_credentials': errorAuthInvalidCredentials,
    'error_auth_email_not_confirmed': errorAuthEmailNotConfirmed,
    'error_auth_user_already_exists': errorAuthUserAlreadyExists,
    'error_auth_session_expired': errorAuthSessionExpired,
    'error_auth_rate_limited': errorAuthRateLimited,
    'error_database_generic': errorDatabaseGeneric,
    'error_database_permission_denied': errorDatabasePermissionDenied,
    'error_database_reference_not_found': errorDatabaseReferenceNotFound,
    'error_database_duplicate_record': errorDatabaseDuplicateRecord,
    'error_database_required_field_missing': errorDatabaseRequiredFieldMissing,
    'error_database_validation_failed': errorDatabaseValidationFailed,
    'error_database_query_failed': errorDatabaseQueryFailed,
    'error_network_generic': errorNetworkGeneric,
    'error_unknown': errorUnknown,
  };

  // Form Labels & Search
  static const String email = 'Email';
  static const String fullName = 'Full Name';
  static const String phone = 'Phone Number';
  static const String searchPatients = 'Search patients\u2026';
  static const String searchPatientsPrompt = 'Search by name or phone number';
  static const String all = 'All';

  // Navigation / Sections
  static const String patients = 'Patients';
  static const String appointments = 'Appointments';
  static const String payments = 'Payments';
  static const String staff = 'Staff';
  static const String settings = 'Settings';
  static const String reports = 'Reports';
  static const String replacements = 'Replacements';
  static const String dashboard = 'Dashboard';
  static const String medicalRecords = 'Medical Records';

  // Actions
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

  // State Messages
  static const String loading = 'Loading…';
  static const String noData = 'No data available.';
  static const String noResults = 'No results found.';
  static const String noPatients = 'No patients registered yet.';
  static const String noAppointments = 'No appointments scheduled.';
  static const String noPayments = 'No payment records found.';
  static const String noStaff = 'No staff members found.';
  static const String noReplacements = 'No replacements for today.';
  static const String noDocuments = 'No documents uploaded.';

  // Patient
  static const String registerPatient = 'Register Patient';
  static const String editPatient = 'Edit Patient';
  static const String patientDetails = 'Patient Details';
  static const String program = 'Program';
  static const String clinic = 'Clinic';
  static const String clinicTagamoa = 'Tagamoa';
  static const String clinicMasrElgedida = 'Masr El-Gedida';
  static const String packageBalance = 'Package Balance';
  static const String assignedDoctors = 'Assigned Doctors';

  // Appointment
  static const String bookAppointment = 'Book Appointment';
  static const String appointmentDetails = 'Appointment Details';
  static const String session = 'Session';
  static const String gehazShadFakarat = 'Spinal Traction';
  static const String checkUp = 'Check-up';
  static const String scheduled = 'Scheduled';
  static const String checkedIn = 'Checked In';
  static const String completed = 'Completed';
  static const String cancelled = 'Cancelled';
  static const String noShow = 'No Show';
  static const String usePackage = 'Use Package';
  static const String notes = 'Notes';
  static const String checkIn = 'Check In';
  static const String markComplete = 'Mark Complete';
  static const String originalDoctors = 'Original Doctors';
  static const String coveringDr = 'Covering Dr.';
  static const String confirmCheckIn =
      'Check in this patient for their appointment?';
  static const String confirmMarkComplete =
      'Mark this appointment as completed?';
  static const String appointmentNotFound = 'Appointment not found.';
  static const String date = 'Date';
  static const String time = 'Time';
  static const String type = 'Type';
  static const String doctors = 'Doctors';
  static const String yes = 'Yes';
  static const String no = 'No';

  // Replacement
  static const String initiateReplacement = 'Initiate Replacement';
  static const String absentDoctor = 'Absent Doctor';
  static const String coveringDoctor = 'Covering Doctor';
  static const String replacementDate = 'Replacement Date';
  static const String swapDoctors = 'Swap Doctors';
  static const String manageReplacement = 'Manage Replacement';
  static const String selectAbsentDoctor = 'Select absent doctor';
  static const String selectCoveringDoctor = 'Select covering doctor';
  static const String confirmReplacement = 'Confirm Replacement';
  static const String replacementAccessDenied =
      'Doctors cannot access this screen. Receptionist/Admin only.';
  static const String affectedAppointmentsHeader = 'Affected Appointments';
  static const String replacementSwapSuccess =
      'Appointments swapped successfully.';
  static const String skipManualSwap = "Skip, I'll handle manually";
  static const String selectAll = 'Select All';
  static const String applyToSelected = 'Apply to Selected';
  static const String noAffectedAppointments =
      'No appointments found for this doctor on this date.';

  // Confirmation Dialogs
  static const String confirmDelete = 'Are you sure you want to delete this record?';
  static const String confirmCancel = 'Are you sure you want to cancel this appointment?';
  static const String confirmSignOut = 'Are you sure you want to sign out?';
  static const String actionCannotBeUndone = 'This action cannot be undone.';

  // New Booking Screen Strings
  static const String newAppointment = 'New Appointment';
  static const String patientId = 'Patient ID';
  static const String appointmentType = 'Appointment Type';
  static const String single = 'Single';
  static const String recurring = 'Recurring';
  static const String isRecurring = 'Is Recurring?';
  static const String selectDays = 'Select Days of Week';
  static const String numberOfSessions = 'Number of Sessions';
  static const String scheduledSlots = 'Scheduled Slots Preview';
  static const String bookingSuccess = 'Appointment booked successfully.';
  static const String bookingRecurringSuccess = 'Recurring appointments booked successfully.';
  static const String bookingError = 'Failed to book appointment.';
  static const String accessDenied = 'Access denied. Receptionist/Admin only.';
  static const String patientRequired = 'Patient ID is required.';
  static const String dateRequired = 'Date is required.';
  static const String timeRequired = 'Time is required.';
  static const String sessionsRequired = 'Number of sessions is required.';
  static const String daysRequired = 'At least one day must be selected.';
  static const String noAssignedDoctors = 'No assigned doctors found for this patient.';
  static const String selectDate = 'Select Date';
  static const String selectTime = 'Select Time';
  static const String checkInPatient = 'Check In Patient';
  static const String cancelAppointment = 'Cancel Appointment';
  static const String markAsCompleted = 'Mark as Completed';
  static const String historicalNote = 'This appointment is read-only.';
  static const String statusUpdateSuccess = 'Status updated successfully.';
  static const String statusUpdateError = 'Failed to update status.';

  // Payment Screen Strings
  static const String recordPayment = 'Record Payment';
  static const String paymentAmount = 'Amount';
  static const String amountRequired = 'Amount is required';
  static const String amountMustBePositive = 'Amount must be greater than zero';
  static const String reasonRequired = 'Reason is required';
  static const String paymentReason = 'Reason';
  static const String paymentReasonPackage = 'Package';
  static const String paymentReasonSession = 'Session';
  static const String paymentReasonGehaz = 'Gehaz';
  static const String paymentReasonOther = 'Other';
  static const String customReason = 'Custom Reason';
  static const String customReasonRequired = 'Custom reason is required';
  static const String paymentRecordedSuccess = 'Payment recorded successfully.';
  static const String selectPackage = 'Select Package';
  static const String patientDisplayName = 'Patient';
  static const String doctorAccessBlocked = 'Doctors are completely restricted from modifying payment databases.';

  // Package Balance Edit Strings
  static const String editPackageBalance = 'Edit Package Balance';
  static const String enterNewPackageBalance = 'Enter new package balance';
  static const String balanceRequired = 'Please enter a balance';
  static const String balanceMustBeInteger = 'Must be a valid integer';
  static const String packageBalanceUpdatedSuccess = 'Package balance updated successfully.';
  static const String editPackageBalanceAccessDenied = 'Only super admins and receptionists can edit package balance.';

  // Appointment Recovery Strings
  static const String revertToScheduled = 'Revert to Scheduled';
  static const String restoreToScheduled = 'Restore to Scheduled';
  static const String confirmRevert = 'Are you sure you want to revert this appointment to scheduled?';
  static const String confirmRestore = 'Are you sure you want to restore this appointment to scheduled?';

  // Staff Management Strings
  static const String staffManagement = 'Staff Management';
  static const String addStaff = 'Add Staff';
  static const String editStaff = 'Edit Staff';
  static const String superAdmin = 'Super Admin';
  static const String receptionist = 'Receptionist';
  static const String role = 'Role';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String isActive = 'Is Active';
  static const String changePassword = 'Change Password';
  static const String deactivateStaffConfirm = 'Deactivate this staff member? They will no longer be able to log in.';
  static const String selfDeactivationError = 'You cannot deactivate your own account.';
  static const String staffCreateSuccess = 'Staff member created successfully.';
  static const String staffUpdateSuccess = 'Staff member updated successfully.';
  static const String passwordRequired = 'Password is required';
  static const String passwordsDoNotMatch = 'Passwords do not match';
  static const String passwordMinLength = 'Password must be at least 8 characters';
  static const String emailRequired = 'Email is required';
  static const String emailInvalid = 'Invalid email format';
  static const String fullNameRequired = 'Full name is required';
  static const String roleRequired = 'Role is required';

  // Admin Hub Strings
  static const String adminHub = 'Admin Hub';
  static const String doctorApplications = 'Doctor Applications';
  static const String clinicSettings = 'Clinic Settings';
  static const String reportsAndAnalytics = 'Reports & Analytics';
  static const String manageDoctorsLabel = 'Review and approve new doctors';
  static const String manageStaffLabel = 'Manage receptionist and admin accounts';
  static const String configureClinicLabel = 'Set up session packages and pricing';
  static const String viewReportsLabel = 'Check clinic statistics and performance';
  static const String noPendingApplications = 'No pending applications found.';
  static const String pending = 'Pending';
  static const String allApplications = 'All Applications';

  // Clinic Packages Strings
  static const String addPackage = 'Add Package';
  static const String editPackage = 'Edit Package';
  static const String packageName = 'Package Name';
  static const String sessionCount = 'Session Count';
  static const String price = 'Price';
  static const String nameRequired = 'Package name is required';
  static const String sessionCountRequired = 'Session count is required';
  static const String sessionCountPositive = 'Session count must be an integer greater than zero';
  static const String priceRequired = 'Price is required';
  static const String pricePositive = 'Price must be greater than zero';
  static const String packageCreatedSuccess = 'Package added successfully.';
  static const String packageUpdatedSuccess = 'Package updated successfully.';
  static const String packageDeletedSuccess = 'Package deleted successfully.';
  static const String deletePackageConfirm = 'Are you sure you want to delete this package? This action cannot be undone.';
  static const String noPackages = 'No clinic packages configured yet.';
  static const String doctor = 'Doctor';

  // Profile / Settings
  static const String profile = 'Profile';
  static const String activeBranch = 'Active Branch';
  static const String selectBranch = 'Select Branch';
  static const String signOut = 'Sign Out';
  static const String historicAppointments = 'Historic Appointments';
  static const String noHistoricAppointments = 'No past appointments found.';
  static const String branchSelectionHint = 'Select your active branch';
  static const String profileSettingsDescription = 'Manage your preferences and account settings.';

  // Patient List
  static const String allPatients = 'All Patients';
  static const String filterByDoctor = 'Filter by Doctor';
  static const String filterByBranch = 'Filter by Branch';
  static const String allDoctors = 'All Doctors';
  static const String allBranches = 'All Branches';
  static const String loadMore = 'Load More';
  static const String registerNewPatient = 'Register New Patient';
  static const String patientRegisteredSuccess = 'Patient registered successfully.';
  static const String quickPayment = 'Quick Payment';
  static const String paymentAmountHint = 'Enter amount';
  static const String paymentReasonHint = 'Enter reason';
  static const String confirmPayment = 'Confirm Payment';
  static const String confirmPaymentMessage = 'Record a payment of %s for this patient?';

  // Note deletion
  static const String deleteNote = 'Delete Note';
  static const String confirmDeleteNote = 'Are you sure you want to delete this note?';
  static const String noteDeleted = 'Note deleted successfully.';

  // Payment CRUD
  static const String deletePayment = 'Delete Payment';
  static const String confirmDeletePayment = 'Are you sure you want to delete this payment record?';
  static const String paymentDeleted = 'Payment deleted successfully.';
  static const String editPayment = 'Edit Payment';
  static const String paymentUpdated = 'Payment updated successfully.';

  // Role display labels
  static const String adminRoleLabel = 'Admin';
  static const String receptionistRoleLabel = 'Receptionist';
  static const String doctorRoleLabel = 'Doctor';

  // Profile / Edit
  static const String editProfile = 'Edit Profile';
  static const String recentAppointments = 'Recent Appointments';
  static const String changePasswordOptional = 'Change Password (optional)';
  static const String newPasswordHint = 'New Password';
  static const String profileUpdatedSuccess = 'Profile updated successfully.';
  static const String searchByPatientNameHint = 'Search by patient name...';

  // Filter labels
  static const String fromDate = 'From';
  static const String toDate = 'To';
  static const String clearFilters = 'Clear';

  // Quick Payment
  static const String fillAmountAndReason = 'Please fill in amount and reason.';
  static const String packageBalanceMustBeInteger = 'Package balance must be a valid integer.';
  static const String addPackageBalanceOptional = 'Add Package Balance (optional)';
  static const String packageBalanceHint = 'E.g. 5 to add 5 sessions';

  // Note / Appointment labels
  static const String loadingAuthor = 'Loading...';
  static const String unknownAuthor = 'Unknown Author';
  static const String onAppointmentPrefix = 'On appointment: ';
  static const String loadingDetails = 'Loading details...';
  static const String linkedAppointmentLabel = 'Linked Appointment';

  // ── Admin Reports / Analytics ──
  static const String totalPatients = 'Total Patients';
  static const String newPatients = 'New Patients';
  static const String appointmentsCount = 'Appointments';
  static const String activeDoctorsCount = 'Active Doctors';
  static const String registeredInPeriod = 'Registered in period';
  static const String bookedInPeriod = 'Booked in period';
  static const String assignedInPeriod = 'Assigned in period';
  static const String allClinics = 'All Clinics';
  static const String today = 'Today';
  static const String thisWeek = 'This Week';
  static const String thisMonth = 'This Month';
  static const String custom = 'Custom';
  static const String customRange = 'Custom Range';
  static const String noRecordsInWindow = 'No records in this window.';
  static const String appointmentsByStatus = 'Appointments by Status';
  static const String appointmentsByType = 'Appointments by Type';
  static const String appointmentsPerDoctor = 'Appointments per Doctor';

  // Revenue & Balance
  static const String grossIncome = 'Gross Income';
  static const String totalPackageBalances = 'Total Package Balances';
  static const String activeSessions = 'Active Sessions';
  static const String revenue = 'Revenue';
  static const String visits = 'Visits';
  static const String monthlyTrends = 'Monthly Trends';
  static const String yearlyTrends = 'Yearly Trends';
  static const String branchComparison = 'Branch Comparison';
  static const String yearLabel = 'Year';
  static const String egpPrefix = 'EGP ';
  static const String noTrendData = 'No trend data for this period.';
}
