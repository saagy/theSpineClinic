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
  static const String errorDatabaseRecordNotFound = 'The requested record was deleted or does not exist.';
  static const String errorDatabaseDuplicateRecord = 'Record already exists.';
  static const String errorDatabaseRequiredFieldMissing = 'Required field is missing.';
  static const String errorDatabaseValidationFailed = 'Data validation failed.';
  static const String errorDatabaseQueryFailed = 'Database query failed. Try again.';
  static const String errorNetworkGeneric = 'Unable to reach server. Check connection.';
  static const String errorUnknown = 'An unexpected error occurred. Try again.';

  // Document upload size guards
  static const String errorDocFileTooLarge = 'File is too large to upload. Maximum size is 10 MB.';
  static const String errorDocImageTooLarge = 'Image is too large to upload. Maximum size is 10 MB.';
  static const String errorDocPdfTooLarge = 'PDF is too large to upload. Maximum size is 10 MB.';
  static const String errorAttachmentPartialFail =
      'Patient was saved but some attachments failed to upload. Open the patient to retry them.';

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
    'error_database_record_not_found': errorDatabaseRecordNotFound,
    'error_database_duplicate_record': errorDatabaseDuplicateRecord,
    'error_database_required_field_missing': errorDatabaseRequiredFieldMissing,
    'error_database_validation_failed': errorDatabaseValidationFailed,
    'error_database_query_failed': errorDatabaseQueryFailed,
    'error_network_generic': errorNetworkGeneric,
    'error_unknown': errorUnknown,
    'error_doc_image_too_large': errorDocImageTooLarge,
    'error_doc_pdf_too_large': errorDocPdfTooLarge,
    'error_doc_file_too_large': errorDocFileTooLarge,
    'error_attachment_partial_fail': errorAttachmentPartialFail,
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
  static const String appointmentHistory = 'Appointment History';
  static const String appointmentHistorySubtitle = 'View all of your appointments';
  static const String editProfileTooltip = 'Edit Profile';

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
  static const String noDocumentsYet = 'No documents uploaded yet';
  static const String addDocument = 'Add Document';
  static const String documentUploaded = 'Document uploaded.';
  static const String openingDocument = 'Opening document…';
  static const String documentDeleted = 'Document deleted successfully.';
  static const String deleteDocumentTitle = 'Delete Document';
  static const String confirmDeleteDocument =
      'Are you sure you want to permanently delete this document?';

  // Patient
  static const String registerPatient = 'Register Patient';
  static const String editPatient = 'Edit Patient';
  static const String patientDetails = 'Patient Details';
  static const String program = 'Program';
  static const String clinic = 'Clinic';
  static const String clinicTagamoa = 'Tagamoa';
  static const String clinicMasrElgedida = 'Masr El-Gedida';
  static const String packageBalance = 'Package Balance';
  static const String sessionBalance = 'PT Session Balance';
  static const String tractionBalance = 'Spinal Traction Balance';
  static const String packageBalances = 'Package Balances';
  static const String assignedDoctors = 'Assigned Doctors';

  // Appointment
  static const String bookAppointment = 'Book Appointment';
  static const String appointmentDetails = 'Appointment Details';
  static const String session = 'Session';
  static const String gehazShadFakarat = 'Spinal Traction';
  static const String checkUp = 'Check-up';
  static const String normalPtSession = 'PT Session';
  static const String spinalTractionSession = 'Spinal Traction';
  static const String initialAssessment = 'Assessment';
  static const String reassessment = 'Reassessment';
  static const String paidSeparately = 'Paid separately';
  static const String assessmentPaidSeparatelyCaption =
      'Assessments are billed independently — no package deduction.';
  static const String scheduled = 'Scheduled';
  static const String checkedIn = 'Checked In';
  static const String completed = 'Completed';
  static const String cancelled = 'Cancelled';
  static const String noShow = 'No Show';
  static const String usePackage = 'Use Package';
  static const String notes = 'Notes';
  static const String checkIn = 'Check In';
  static const String statusScheduled = 'Scheduled';
  static const String statusCheckedIn = 'Checked In';
  static const String statusCancelled = 'Cancelled';
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
  static const String editAppointment = 'Edit Appointment';
  static const String editDetails = 'Edit Details';
  static const String deleteAppointment = 'Delete Appointment';
  static const String appointmentDeleted = 'Appointment deleted successfully.';
  static const String appointmentUpdated = 'Appointment updated successfully.';
  static const String deleteAppointmentWarning = 'This will permanently remove the appointment record and doctor assignments. This action cannot be undone.';
  static const String usePackageChangeWarning = 'Cannot change package deduction. This option can only be edited for "Scheduled" appointments, not for checked-in or completed sessions.';
  static const String deletePatient = 'Delete Patient';
  static const String deletePatientWarning = 'This will permanently remove this patient record. This action cannot be undone.';
  static const String patientDeleted = 'Patient deleted successfully.';


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

  // ── Booking Balance Diagnostics ──
  static const String insufficientPackageBalance =
      'Insufficient package balance. Toggle off \'Use Package\' to book as a paid session.';
  static const String negativeBalanceOutstanding =
      'Outstanding balance — patient owes sessions from previous bookings.';
  static const String errorLoadingPackageMetrics = 'Error loading package metrics.';
  static const String liveLedgerPreview = 'Live Ledger Preview';
  static const String ptSessionsBucket = 'PT Sessions';
  static const String tractionSessionsBucket = 'Traction Sessions';
  static const String currentBucket = 'Current Bucket';
  static const String upcomingInBucket = 'Upcoming in this bucket';
  static const String netAvailableLabel = 'Net Available';
  static const String thisOrderCount = 'This Order Count';

  /// Deficit message shown when requested sessions exceed available balance.
  static String packageDeficitMessage(int deficit) =>
      'Package Deficit: $deficit session(s) overdrawn.';

  /// Leftover message shown when booking leaves a positive remainder.
  static String projectedLeftoverMessage(int leftover) =>
      'Projected Leftover Balance: $leftover session(s).';

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
  static const String paymentReasonNormalPtSession = 'PT Session';
  static const String paymentReasonSpinalTraction = 'Spinal Traction Session';
  static const String paymentReasonInitialAssessment = 'Initial Assessment';
  static const String paymentReasonReassessment = 'Reassessment';
  static const String paymentReasonOther = 'Other';
  static const String customReason = 'Custom Reason';
  static const String customReasonRequired = 'Custom reason is required';
  static const String paymentRecordedSuccess = 'Payment recorded successfully.';
  static const String selectPackage = 'Select Package';
  static const String patientDisplayName = 'Patient';
  static const String doctorAccessBlocked = 'Doctors are completely restricted from modifying payment databases.';
  static const String sessionBalanceAddedField = 'PT Sessions Added';
  static const String tractionBalanceAddedField = 'Traction Sessions Added';
  static const String packageContentsLabelPrefix = 'Includes';

  // Package Balance Edit Strings
  static const String editPackageBalance = 'Edit Package Balances';
  static const String enterNewPackageBalance = 'Enter new package balance';
  static const String balanceRequired = 'Please enter a balance';
  static const String balanceMustBeInteger = 'Must be a valid integer';
  static const String packageBalanceUpdatedSuccess = 'Package balances updated successfully.';
  static const String editPackageBalanceAccessDenied = 'Only super admins and receptionists can edit package balances.';
  static const String sessionBalanceHint = 'Sets the new total for PT sessions';
  static const String tractionBalanceHint = 'Sets the new total for traction sessions';
  static const String currentBalancePrefix = 'Current: ';
  static const String addBalanceToggleTitle = 'Add to package balances';
  static const String addBalanceBothZero = 'Leave any field empty to skip that bucket';
  static const String editReplacesExplanation =
      'Sets the new totals. Editing this way replaces the previous values.';

  // Appointment Recovery Strings
  static const String revertToScheduled = 'Revert to Scheduled';
  static const String undoCheckIn = 'Undo Check-In';
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
  static const String active = 'Active';
  static const String deactivated = 'Deactivated';
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
  static const String noPendingApplications = 'No pending applications found.';
  static const String pending = 'Pending';
  static const String allApplications = 'All Applications';

  // Clinic Packages Strings
  static const String addPackage = 'Add Package';
  static const String editPackage = 'Edit Package';
  static const String packageName = 'Package Name';
  static const String sessionCount = 'Session Count';
  static const String tractionsCount = 'Traction Count';
  static const String price = 'Price';
  static const String packageKindSession = 'Session';
  static const String packageKindTraction = 'Spinal Traction';
  static const String packageKindCombined = 'Combined';
  static const String packageKindLabel = 'Package Type';
  static const String nameRequired = 'Package name is required';
  static const String sessionCountRequired = 'Session count is required';
  static const String sessionCountPositive = 'Session count must be an integer greater than zero';
  static const String tractionsCountPositive = 'Traction count must be an integer greater than zero';
  static const String packageCountsAtLeastOne = 'At least one of PT sessions or traction count must be greater than zero';
  static const String priceRequired = 'Price is required';
  static const String pricePositive = 'Price must be greater than zero';
  static const String packageCreatedSuccess = 'Package added successfully.';
  static const String packageUpdatedSuccess = 'Package updated successfully.';
  static const String packageDeletedSuccess = 'Package deleted successfully.';
  static const String deletePackageConfirm = 'Are you sure you want to delete this package? This action cannot be undone.';
  static const String noPackages = 'No clinic packages configured yet.';
  static const String doctor = 'Doctor';
  static const String packageSummarySessions = 'PT Package Sessions';
  static const String packageSummaryTractions = 'Spinal Traction Package Sessions';

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
  static const String searchDoctors = 'Search doctors...';
  static const String noDoctorsMatch = 'No matching doctors';
  static const String allBranches = 'All Branches';
  static const String filters = 'Filters';
  static const String sort = 'Sort';
  static const String sortByName = 'Name';
  static const String sortByRecent = 'Recent';
  static const String applyFilters = 'Apply';
  static const String branch = 'Branch';
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
  static const String cannotSaveEmptyNote = 'Note text cannot be empty. If you want to remove the note, please delete it instead.';

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
  static const String changePasswordOptional = 'Change Password (optional)';
  static const String newPasswordHint = 'New Password';
  static const String profileUpdatedSuccess = 'Profile updated successfully.';
  static const String searchByPatientNameHint = 'Search by patient name...';

  // Filter labels
  static const String fromDate = 'From';
  static const String toDate = 'To';
  static const String filterByType = 'Filter by Type';
  static const String allTypes = 'All Types';
  static const String clearFilters = 'Clear';

  // Quick Payment
  static const String fillAmountAndReason = 'Please fill in amount and reason.';
  static const String packageBalanceMustBeInteger = 'Package balance must be a valid integer.';
  static const String addPackageBalanceOptional = 'Add Package Balances (optional)';
  static const String packageBalanceHint = 'E.g. 5 to add 5 sessions';
  static const String zeroIsAllowed = 'Leave at 0 to skip';

  // Note / Appointment labels
  static const String loadingAuthor = 'Loading...';
  static const String unknownAuthor = 'Unknown Author';
  static const String onAppointmentPrefix = 'On appointment: ';
  static const String loadingDetails = 'Loading details...';
  static const String linkedAppointmentLabel = 'Linked Appointment';

  // ── All Appointments ──
  static const String allAppointments = 'All Appointments';
  static const String filterByStatus = 'Filter by Status';
  static const String allStatuses = 'All Statuses';
  static const String filterByDate = 'Filter by Date';
  static const String noAppointmentsFound = 'No appointments found.';
  static const String allDoctorsAppts = 'All Doctors';
  static const String accessDeniedAdminReceptionOnly = 'Access denied. Receptionist/Admin only.';

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

  // ── Navigation Tab Labels ──
  static const String navMySchedule = 'My Schedule';
  static const String navMyPatients = 'My Patients';
  static const String navCoverageLogs = 'Coverage Logs';
  static const String navCalendar = 'Calendar';
  static const String navAnalytics = 'Analytics';
  static const String navAppts = 'Appts';
  static const String navAdmin = 'Admin';

  // ── Misc Labels ──
  static const String backTooltip = 'Back';
  static const String unknownDoctorFallback = 'Doctor';
  static const String unknownFallback = 'Unknown';

  // ── My Patients ──
  static const String noAssignedPatientsYet = 'No patients assigned to you yet';

  // ── Parameterized Messages ──

  /// Returns a formatted "Covering [name]" label for replacement doctor display.
  static String coveringDoctorLabel(String name) => 'Covering $name';

  /// Returns formatted "No patients found for '[query]'" message.
  static String noPatientsFoundFor(String query) => "No patients found for '$query'";

  /// Returns formatted "You are covering for [name] today" banner message.
  static String coveringForDoctorToday(String name) => 'You are covering for $name today';

  /// Returns formatted "Today, [date]" header string.
  static String todayWithDate(String dateStr) => 'Today, $dateStr';

  // ── Visit Notes ──
  static const String addVisitNotes = 'Add Visit Notes';
  static const String visitDetails = 'Visit Details';
  static const String editNotesTooltip = 'Edit Notes';
  static const String noStaffAssignedToSession = 'No staff assigned to this session.';

  // ── Doctor Overlay ──
  static const String selectDoctors = 'Select Doctors';
  static const String searchDoctorsHint = 'Search doctors…';
  static const String searchAndAssignDoctors = 'Search & Assign Doctors';
  static const String typeDoctorName = 'Type doctor name...';
  static const String noMatchingDoctorsFound = 'No matching doctors found.';
  static const String errorLoadingDoctors = 'Error loading doctors.';
  static const String atLeastOneDoctorRequired =
      'At least one doctor is required.';
  static const String unableToLoadDoctors =
      'Unable to load doctors — tap refresh icon to retry';

  // ── Patient Tabs ──
  static const String usePackageBalance = 'Use Package Balance';
  static const String noPaymentsRecorded = 'No payments recorded';
  static const String totalPaid = 'Total Paid';
  static const String noDoctorsAssigned = 'No doctors assigned';
  static const String errorLoadingAssignedDoctors = 'Error loading assigned doctors';
  static const String tabInfo = 'Info';
  static const String tabRecords = 'Records';
  static const String tabDocuments = 'Documents';
  static const String sortOptions = 'Sort Options';
  static const String totalNotes = 'Total Notes';
  static const String addNote = 'Add Note';
  static const String noNotesRecorded = 'No notes recorded yet';
  static const String quickActions = 'Quick Actions';
  static const String collectPayment = 'Collect Payment';
  static const String contact = 'Contact';
  static const String lastVisit = 'Last Visit';
  static const String programNone = 'None';
  static const String recordedBy = 'Recorded by';

  // ── Document Actions ──
  static const String openTooltip = 'Open';

  // ── Payment Tabs ──
  static const String paymentHistory = 'Payment History';
  static const String paymentSummary = 'Payment Summary';

  // ── Visit Detail ──
  static const String attendingStaff = 'Attending Staff';

  // ── Analytics Dashboard ──
  static const String analyticsDashboard = 'Analytics';
  static const String financialOverview = 'Financial Overview';
  static const String appointmentAnalytics = 'Appointment Analytics';
  static const String staffPerformance = 'Staff Performance';
  static const String patientDemographics = 'Patient Demographics';
  static const String totalAppointments = 'Total Appointments';
  static const String totalRevenue = 'Total Revenue';
  static const String completionRate = 'Completion Rate';
  static const String cancellationRate = 'Cancellation Rate';
  static const String revenueByPaymentType = 'Revenue by Payment Type';
  static const String revenueByBranch = 'Revenue by Branch';
  static const String outstandingBalances = 'Outstanding Balances';
  static const String packageSales = 'Package Sales';
  static const String appointmentsByDay = 'Appointments by Day';
  static const String topPerformingDoctors = 'Top Performing Doctors';
  static const String newStaffInPeriod = 'New Staff in Period';
  static const String newRegistrations = 'New Registrations';
  static const String activePatients = 'Active Patients';
  static const String patientsByBranch = 'Patients by Branch';
  static const String returningVsNew = 'Returning vs New';
  static const String lastMonth = 'Last Month';
  static const String yearToDate = 'Year to Date';
  static const String busiestDay = 'Busiest Day';
  static const String noFinancialData = 'No financial data for this period.';
  static const String noAppointmentData = 'No appointment data for this period.';
  static const String noStaffData = 'No staff data for this period.';
  static const String noPatientData = 'No patient data for this period.';
  static const String cashPayments = 'Cash / Card';
  static const String packageRedemptions = 'Package Redemptions';
  static const String patientsWithNegativeBalance = 'Patients with negative balance';
  static const String packagesSold = 'Packages Sold';
  static const String packagesSoldValue = 'Packages Sold Value';
  static const String sessionsCompleted = 'Sessions Completed';

  // Package usage filter labels
  static const String packageFilterAll = 'All';
  static const String packageFilterPackage = 'Package';
  static const String packageFilterNoPackage = 'No Package';

  // ── Patient Pill Access (appointment detail header) ──
  static const String patientPillAccessExpired =
      'Access to this patient has expired. Tap is only allowed within '
      '7 days before or 1 day after a shared appointment.';
  static const String patientPillAccessNotAuthenticated =
      'Sign in to view this patient.';

  static const String collapse = 'Collapse';
}

