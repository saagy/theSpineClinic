/// Centralised string constants for the Spine Clinic application.
/// Rule 7 — no hardcoded strings anywhere outside this file.
library;

/// Application-wide string constants.
abstract final class AppStrings {
  // App Identity
  static const String appName = 'Spine Clinic';
  static const String home = 'Home';
  static const String appTagline = 'Patient & Appointment Manager';

  // Error Messages (userMessageKey)
  static const String errorAuthGeneric =
      'Authentication failed. Please try again.';
  static const String errorAuthInvalidCredentials =
      'Invalid email or password.';
  static const String errorAuthEmailNotConfirmed =
      'Email not confirmed. Check your inbox.';
  static const String errorAuthUserAlreadyExists =
      'An account with this email already exists.';
  static const String errorAuthSessionExpired =
      'Your session has expired. Sign in again.';
  static const String errorAuthRateLimited =
      'Too many attempts. Please wait a moment and try again.';

  static const String errorDatabaseGeneric =
      'A database error occurred. Try again.';
  static const String errorDatabasePermissionDenied =
      'You do not have permission.';
  static const String errorDatabaseReferenceNotFound =
      'Referenced record not found.';
  static const String errorDatabaseRecordNotFound =
      'The requested record was deleted or does not exist.';
  static const String errorDatabaseDuplicateRecord = 'Record already exists.';
  static const String errorDatabaseRequiredFieldMissing =
      'Required field is missing.';
  static const String errorDatabaseValidationFailed = 'Data validation failed.';
  static const String errorDatabaseQueryFailed =
      'Database query failed. Try again.';
  static const String errorNetworkGeneric =
      'Unable to reach server. Check connection.';
  static const String errorUnknown = 'An unexpected error occurred. Try again.';

  // Document upload size guards
  static const String errorDocFileTooLarge =
      'File is too large to upload. Maximum size is 10 MB.';
  static const String errorDocImageTooLarge =
      'Image is too large to upload. Maximum size is 10 MB.';
  static const String errorDocPdfTooLarge =
      'PDF is too large to upload. Maximum size is 10 MB.';
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
    'due_booking_changed': dueBookingChanged,
    'insufficient_package_balance': insufficientPackageBalance,
  };

  // Form Labels & Search
  static const String email = 'Email';
  static const String fullName = 'Full Name';
  static const String phone = 'Phone';
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
  static const String dashboard = 'Dashboard';
  static const String medicalRecords = 'Medical Records';

  // Actions
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String showCancelled = 'Show Cancelled';
  static const String hideCancelled = 'Hide Cancelled';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String rename = 'Rename';
  static const String moreActions = 'More actions';
  static const String add = 'Add';
  static const String search = 'Search';
  static const String filter = 'Filter';
  static const String retry = 'Retry';
  static const String confirm = 'Confirm';
  static const String apply = 'Apply';
  static const String close = 'Close';
  static const String submit = 'Submit';
  static const String upload = 'Upload';
  static const String download = 'Download';
  static const String approve = 'Approve';
  static const String reject = 'Reject';
  static const String viewDetails = 'View Details';
  static const String appointmentHistory = 'Appointment History';
  static const String appointmentHistorySubtitle =
      'View all of your appointments';
  static const String editProfileTooltip = 'Edit Profile';

  // State Messages
  static const String loading = 'Loading…';
  static const String noData = 'No data available.';
  static const String noResults = 'No results found.';
  static const String noPatients = 'No patients registered yet.';
  static const String noAppointments = 'No appointments scheduled.';
  static const String noPayments = 'No payment records found.';
  static const String noStaff = 'No staff members found.';
  static const String noDocuments = 'No documents uploaded.';
  static const String noDocumentsYet = 'No documents uploaded yet';
  static const String addDocument = 'Add Document';
  static const String documentUploaded = 'Document uploaded.';
  static const String openingDocument = 'Opening document…';
  static const String documentDeleted = 'Document deleted successfully.';
  static const String documentRenamed = 'Document renamed successfully.';
  static const String documentNotFound = 'Document not found.';
  static const String unsupportedDocumentType =
      'This file type is not supported for in-app viewing.';
  static const String renameDocument = 'Rename Document';
  static const String documentName = 'Document name';
  static const String documentNameRequired = 'Enter a document name.';
  static const String documentNameTooLong =
      'Document names cannot exceed 255 characters.';
  static const String deleteDocumentTitle = 'Delete Document';
  static const String confirmDeleteDocument =
      'Are you sure you want to permanently delete this document?';
  static const String doctorPatientEditDenied =
      'Doctors can only edit patients assigned to them or linked by an appointment.';

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
  static const String cancelled = 'Cancelled';
  static const String usePackage = 'Use Package';
  static const String notes = 'Notes';
  static const String checkIn = 'Check In';
  static const String statusScheduled = 'Scheduled';
  static const String statusCheckedIn = 'Checked In';
  static const String statusCancelled = 'Cancelled';
  static const String restoreAppointment = 'Restore Appointment';
  static const String patientExpected = 'Patient expected.';
  static const String patientArrived = 'Patient has arrived.';
  static const String appointmentCancelledDescription =
      'Appointment cancelled.';
  static const String saveNotes = 'Save Notes';
  static const String visitNotesHint = 'Enter visit progress notes...';
  static const String notesSavedSuccess = 'Notes saved successfully.';
  static const String notesSaveFailed = 'Failed to save notes';
  static const String previousDoctors = 'Previous Doctors';
  static const String confirmCheckIn =
      'Check in this patient for their appointment?';
  static const String appointmentNotFound = 'Appointment not found.';
  static const String date = 'Date';
  static const String time = 'Time';
  static const String type = 'Type';
  static const String doctors = 'Doctors';
  static const String packageStatus = 'Package Status';
  static const String usingPackage = 'Using Package';
  static const String noPackage = 'No Package';
  static const String linkedSessionsOnThisDay = 'Linked Sessions on this Day';
  static const String linkedSessions = 'Linked Sessions';
  static const String linkedSession = 'Linked Session';
  static const String addVisitNotePrompt = 'Add visit note...';
  static const String visitNotes = 'Visit Notes';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String editAppointment = 'Edit Appointment';
  static const String editDetails = 'Edit Details';
  static const String deleteAppointment = 'Delete Appointment';
  static const String appointmentDeleted = 'Appointment deleted successfully.';
  static const String appointmentUpdated = 'Appointment updated successfully.';
  static const String deleteAppointmentWarning =
      'This will permanently remove the appointment record and doctor assignments. This action cannot be undone.';
  static const String usePackageChangeWarning =
      'Cannot change package deduction after a patient has checked in.';
  static const String deletePatient = 'Delete Patient';
  static const String deletePatientWarning =
      'This will permanently remove this patient record. This action cannot be undone.';
  static const String patientDeleted = 'Patient deleted successfully.';

  static const String noAffectedAppointments =
      'No appointments found for this doctor on this date.';

  // Confirmation Dialogs
  static const String confirmDelete =
      'Are you sure you want to delete this record?';
  static const String confirmCancel =
      'Are you sure you want to cancel this appointment?';
  static const String confirmSignOut = 'Are you sure you want to sign out?';
  static const String actionCannotBeUndone = 'This action cannot be undone.';

  // New Booking Screen Strings
  static const String newAppointment = 'New Appointment';
  static const String patientId = 'Patient ID';
  static const String appointmentType = 'Appointment Type';
  static const String visitType = 'Visit Type';
  static const String single = 'Single';
  static const String recurring = 'Recurring';
  static const String isRecurring = 'Is Recurring?';
  static const String selectDays = 'Select Days of Week';
  static const String numberOfSessions = 'Number of Sessions';
  static const String scheduledSlots = 'Scheduled Slots Preview';
  static const String bookingSuccess = 'Appointment booked successfully.';
  static const String bookingRecurringSuccess =
      'Recurring appointments booked successfully.';
  static const String bookingError = 'Failed to book appointment.';
  static const String accessDenied = 'Access denied. Receptionist/Admin only.';
  static const String patientRequired = 'Patient ID is required.';
  static const String dateRequired = 'Date is required.';
  static const String timeRequired = 'Time is required.';
  static const String sessionsRequired = 'Number of sessions is required.';
  static const String recurrencePattern = 'Recurrence Pattern';
  static const String sessionsRangeError =
      'Number of sessions must be between 1 and 24.';
  static const String sessionsRangeValidator =
      'Must be between 1 and 24 sessions';
  static const String doctorListTimeout =
      'Doctor list took too long. Select manually.';
  static const String providerAndBilling = 'Provider & Billing';
  static const String loadingAssignedDoctors = 'Loading assigned doctors...';
  static const String daysRequired = 'At least one day must be selected.';
  static const String noAssignedDoctors =
      'No assigned doctors found for this patient.';
  static const String selectDate = 'Select Date';
  static const String selectTime = 'Select Time';
  static const String checkInPatient = 'Check In Patient';
  static const String cancelAppointment = 'Cancel Appointment';
  static const String historicalNote = 'This appointment is read-only.';
  static const String statusUpdateSuccess = 'Status updated successfully.';
  static const String statusUpdateError = 'Failed to update status.';

  // ── Booking Balance Diagnostics ──
  static const String insufficientPackageBalance =
      'Insufficient package balance. Toggle off \'Use Package\' to book as a paid session.';
  static const String negativeBalanceOutstanding =
      'Outstanding balance — patient owes sessions from previous bookings.';
  static const String errorLoadingPackageMetrics =
      'Error loading package metrics.';
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
  static const String patientDisplayName = 'Patient';
  static const String doctorAccessBlocked =
      'Doctors are completely restricted from modifying payment databases.';
  static const String paymentLoginRequired =
      'Must be logged in to manage payments.';
  static const String paymentAccessDenied =
      'Only super admins and payment-enabled receptionists can manage payments.';
  static const String sessionBalanceAddedField = 'PT Sessions Added';
  static const String tractionBalanceAddedField = 'Traction Sessions Added';
  static const String packageContentsLabelPrefix = 'Includes';

  // Partial Payments & Editing
  static const String collectDue = 'Collect Due';
  static const String totalAmount = 'Total Amount';
  static const String serviceTotal = 'Total Amount';
  static const String amountPaidNow = 'Amount paid now';
  static const String amountPaidSoFar = 'Amount paid so far';
  static const String amountToCollect = 'Amount to collect';
  static const String currencyEgp = 'EGP';
  static const String zeroAmountHint = '0.00';
  static const String amountPaid = 'Amount Paid';
  static const String dueBalance = 'Due balance';
  static const String remainingDue = 'Remaining due';
  static const String remainingAfterThis = 'Remaining after this';
  static const String liveSummary = 'Live summary';
  static const String paymentSummaryOf = 'Of';
  static const String paidInFull = 'Fully Paid';
  static const String partialPayment = 'Partial payment';
  static const String paidInFullMode = 'Fully Paid';
  static const String partialPaymentMode = 'Partial payment';
  static const String totalOutstanding = 'Total Outstanding';
  static const String confirmCollection = 'Confirm Collection';
  static const String saveChanges = 'Save Changes';
  static const String editPaymentHint =
      'To record a new collection, use the "Collect Due" button.';
  static const String partialPaymentHelpText =
      'Turn on if the patient paid only part of the total.';
  static const String amountRequiredMessage = 'Please enter an amount.';
  static const String reasonRequiredMessage = 'Please enter a reason.';
  static const String totalAmountRequired = 'Total Amount is required.';
  static const String totalAmountPositive =
      'Total Amount must be greater than zero.';
  static const String amountExceedsServiceTotal =
      'Amount paid cannot exceed Total Amount.';
  static const String amountExceedsRemainingDue =
      'Amount cannot exceed remaining due.';
  static const String customReasonRequiredMessage =
      'Please enter a custom reason.';
  static const String validPtSessionsMessage =
      'Enter a valid PT session amount or leave it empty.';
  static const String validTractionSessionsMessage =
      'Enter a valid traction amount or leave it empty.';
  static const String validNumericAmount = 'Must be a valid numeric amount.';
  static const String specifyReason = 'Specify reason';
  static const String customReasonHint = 'Enter custom payment description';
  static const String leaveEmptyToSkip = 'Blank = 0';
  static const String addBalanceAssessmentDisabled =
      'Assessment payments do not add package balances.';
  static const String noRemainingDueSaved =
      'No remaining due. This payment will be saved as paid in full.';
  static const String collectionRecordedSuccess =
      'Collection recorded successfully.';

  static String recordPaymentCta(String amount) => 'Record $amount';
  static String collectPaymentCta(String amount) => 'Collect $amount';
  static String dueAmountLabel(String amount) => 'Due: $amount';
  static String confirmRecordPayment(String amount, String reason) =>
      'Record $amount for $reason?';
  static String confirmRecordPaymentWithCredits(
    String amount,
    String reason,
    int pt,
    int traction,
  ) => 'Record $amount for $reason and add $pt PT + $traction traction?';
  static String confirmCollectDue(String amount) =>
      'Record collection of $amount for this due payment?';
  static String confirmEditPaymentPaidInFull() =>
      'Save changes? This payment will have no remaining due.';
  static String confirmEditPaymentWithDue(String due) =>
      'Save changes to this payment record? Remaining due will be $due.';

  // Package Balance Edit Strings
  static const String editPackageBalance = 'Edit Package Balances';
  static const String enterNewPackageBalance = 'Enter new package balance';
  static const String balanceRequired = 'Please enter a balance';
  static const String balanceMustBeInteger = 'Must be a valid integer';
  static const String packageBalanceUpdatedSuccess =
      'Package balances updated successfully.';
  static const String editPackageBalanceAccessDenied =
      'Only super admins and receptionists can edit package balances.';
  static const String sessionBalanceHint = 'Sets the new total for PT sessions';
  static const String tractionBalanceHint =
      'Sets the new total for traction sessions';
  static const String currentBalancePrefix = 'Current: ';
  static const String addBalanceToggleTitle = 'Add to package balances';
  static const String addBalanceBothZero =
      'Leave any field empty to skip that bucket';
  static const String editReplacesExplanation =
      'Sets the new totals. Editing this way replaces the previous values.';

  // Appointment Recovery Strings
  static const String revertToScheduled = 'Revert to Scheduled';
  static const String undoCheckIn = 'Undo Check-In';
  static const String restoreToScheduled = 'Restore to Scheduled';
  static const String dualSession = 'Dual Session';
  static const String checkInAllSessions = 'Check In All Sessions';
  static const String revertAllSessions = 'Revert All Sessions';
  static const String cancelAllSessions = 'Cancel All Sessions';
  static const String restoreAllSessions = 'Restore All Sessions';
  static const String confirmCancelAllSessions =
      'Are you sure you want to cancel all sessions for this visit?';
  static const String errorUpdatingSessionStatus =
      'Error updating session status';
  static const String confirmRevert =
      'Are you sure you want to revert this appointment to scheduled?';
  static const String confirmRestore =
      'Are you sure you want to restore this appointment to scheduled?';

  // Staff Management Strings
  static const String staffManagement = 'Staff Management';
  static const String addStaff = 'Add Staff';
  static const String editStaff = 'Edit Staff';
  static const String staffApplications = 'Staff Applications';
  static const String superAdmin = 'Clinic Admin';
  static const String superAdmins = 'Clinic Admins';
  static const String receptionist = 'Receptionist';
  static const String receptionists = 'Receptionists';
  static const String role = 'Role';
  static const String identity = 'Identity';
  static const String access = 'Access';
  static const String account = 'Account';
  static const String accountStatus = 'Account Status';
  static const String accountEnabled = 'Account enabled';
  static const String accountEnabledHint = 'Staff member can sign in';
  static const String accountDisabledHint = 'Staff member cannot sign in';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String isActive = 'Is Active';
  static const String canManagePayments = 'Can manage payments';
  static const String active = 'Active';
  static const String pendingApproval = 'Pending Approval';
  static const String deactivated = 'Deactivated';
  static const String changePassword = 'Change Password';
  static const String staffAdminPermissionDenied =
      'Only super admins can manage staff accounts.';
  static const String staffSearchHint = 'Search staff by name or email';
  static const String noPhone = 'No phone';
  static const String noBranch = 'No branch';
  static const String sortNameAsc = 'Name (A to Z)';
  static const String sortNameDesc = 'Name (Z to A)';
  static const String sortRole = 'Role';
  static const String sortNewest = 'Newest';
  static const String filterByRole = 'Filter by Role';
  static const String allRoles = 'All Roles';
  static const String approveStaff = 'Approve Staff';
  static const String approveApplication = 'Approve Application';
  static const String rejectApplication = 'Reject Application';
  static const String rejectAndDelete = 'Reject & Delete';
  static const String keepActive = 'Keep Active';
  static const String deactivateAccount = 'Deactivate Account';
  static const String staffApprovedSuccess = 'Staff application approved.';
  static const String staffRejectedSuccess =
      'Application rejected and deleted.';
  static const String staffMissingUserId =
      'Cannot reject application: this staff member has no user account.';
  static const String staffPasswordMissingUserId =
      'Cannot update password: this staff member has no user account.';
  static const String deactivateStaffConfirm =
      'Deactivate this staff member? They will no longer be able to log in.';
  static String approveStaffMessage(String name) =>
      'Approve $name? They will be able to sign in immediately.';
  static String rejectStaffMessage(String name) =>
      'Reject and delete $name? This permanently deletes the account and profile.';
  static String deactivateStaffWarning(int count) =>
      'This staff member has $count upcoming appointment(s). '
      'Deactivating will not cancel them, but the account will no longer be able to sign in.';
  static const String selfDeactivationError =
      'You cannot deactivate your own account.';
  static const String staffCreateSuccess = 'Staff member created successfully.';
  static const String staffUpdateSuccess = 'Staff member updated successfully.';
  static const String passwordRequired = 'Password is required';
  static const String passwordsDoNotMatch = 'Passwords do not match';
  static const String passwordMinLength =
      'Password must be at least 8 characters';
  static const String passwordHint = 'Enter password';
  static const String confirmPasswordHint = 'Confirm password';
  static const String emailRequired = 'Email is required';
  static const String emailInvalid = 'Invalid email format';
  static const String emailHint = 'Enter email address';
  static const String fullNameRequired = 'Full name is required';
  static const String fullNameHint = 'Enter full name';
  static const String fullNameMinLength = 'Min 3 characters required';
  static const String phoneOptionalHint = 'Enter phone number (optional)';
  static const String roleHint = 'Select staff role';
  static const String roleRequired = 'Role is required';

  // Admin Hub Strings
  static const String adminHub = 'Admin Hub';
  static const String doctorApplications = 'Doctor Applications';
  static const String reportsAndAnalytics = 'Reports & Analytics';
  static const String manageDoctorsLabel = 'Review and approve staff accounts';
  static const String manageStaffLabel =
      'Manage receptionist and admin accounts';
  static const String configureClinicLabel =
      'Set up session packages and pricing';
  static const String noPendingApplications =
      'No pending staff applications found.';
  static const String pending = 'Pending';
  static const String allApplications = 'All Accounts';

  static const String doctor = 'Doctor';
  static const String packageSummarySessions = 'PT Package Sessions';
  static const String packageSummaryTractions =
      'Spinal Traction Package Sessions';

  // Profile / Settings
  static const String profile = 'Profile';
  static const String activeBranch = 'Active Branch';
  static const String selectBranch = 'Select Branch';
  static const String signOut = 'Sign Out';
  static const String historicAppointments = 'Historic Appointments';
  static const String noHistoricAppointments = 'No past appointments found.';
  static const String branchSelectionHint = 'Select your active branch';
  static const String profileSettingsDescription =
      'Manage your preferences and account settings.';
  static const String theme = 'Theme';
  static const String themeSubtitle = 'Light, dark, or follow system';
  static const String themeModeLight = 'Light';
  static const String themeModeDark = 'Dark';
  static const String themeModeSystem = 'System';
  static const String scheduleDensity = 'Schedule View';
  static const String scheduleDensitySubtitle =
      'Standard or compact schedule and booking cards';
  static const String scheduleDensityStandard = 'Standard';
  static const String scheduleDensityCompact = 'Compact';
  static const String compactSchedule = 'Compact View';

  // Patient List
  static const String allPatients = 'All Patients';
  static const String filterByDoctor = 'Filter by Doctor';
  static const String filterByBranch = 'Filter by Branch';
  static const String allDoctors = 'All Doctors';
  static const String searchDoctors = 'Search doctors...';
  static const String noDoctorsMatch = 'No matching doctors';
  static const String allBranches = 'All Branches';
  static const String filters = 'Filters';
  static const String advancedFilters = 'Advanced Filters';
  static const String sort = 'Sort';
  static const String sortByName = 'Name';
  static const String sortByRecent = 'Recent';
  static const String applyFilters = 'Apply';
  static const String branch = 'Branch';
  static const String loadMore = 'Load More';
  static const String registerNewPatient = 'Register New Patient';
  static const String patientRegisteredSuccess =
      'Patient registered successfully.';
  static const String quickPayment = 'Quick Payment';
  static const String paymentAmountHint = 'Enter amount';
  static const String paymentReasonHint = 'Enter reason';
  static const String confirmPayment = 'Confirm Payment';
  static const String confirmPaymentMessage =
      'Record a payment of %s for this patient?';

  // Note deletion
  static const String deleteNote = 'Delete Note';
  static const String confirmDeleteNote =
      'Are you sure you want to delete this note?';
  static const String noteDeleted = 'Note deleted successfully.';
  static const String cannotSaveEmptyNote =
      'Note text cannot be empty. If you want to remove the note, please delete it instead.';

  // Payment CRUD
  static const String deletePayment = 'Delete Payment';
  static const String confirmDeletePayment =
      'Are you sure you want to delete this payment record?';
  static const String paymentDeleted = 'Payment deleted successfully.';
  static const String editPayment = 'Edit Payment';
  static const String paymentUpdated = 'Payment updated successfully.';

  // Role display labels
  static const String adminRoleLabel = 'Clinic Admin';
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
  static const String clearAll = 'Clear All';

  // Quick Payment
  static const String fillAmountAndReason = 'Please fill in amount and reason.';
  static const String packageBalanceMustBeInteger =
      'Package balance must be a valid integer.';
  static const String addPackageBalanceOptional =
      'Add Package Balances (optional)';
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
  static const String accessDeniedAdminReceptionOnly =
      'Access denied. Receptionist/Admin only.';

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
  static const String previousWeek = 'Previous week';
  static const String nextWeek = 'Next week';
  static const String jumpToDate = 'Jump to date';
  static const String goodMorning = 'Good morning';
  static const String goodAfternoon = 'Good afternoon';
  static const String goodEvening = 'Good evening';

  static String scheduleDaySemantics(
    String date,
    int appointmentCount, {
    required bool selected,
  }) =>
      '$date, $appointmentCount appointment${appointmentCount == 1 ? '' : 's'}${selected ? ', selected' : ''}';

  static String appointmentCountForDate(String date, int count) =>
      '$date  ·  $count appointment${count == 1 ? '' : 's'}';
  static String appointmentCountSummary(int count) =>
      '$count appointment${count == 1 ? '' : 's'}';
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

  /// Returns formatted "No patients found for '[query]'" message.
  static String noPatientsFoundFor(String query) =>
      "No patients found for '$query'";

  /// Returns formatted "Today, [date]" header string.
  static String todayWithDate(String dateStr) => 'Today, $dateStr';

  // ── Visit Notes ──
  static const String addVisitNotes = 'Add Visit Notes';
  static const String visitDetails = 'Visit Details';
  static const String editNotesTooltip = 'Edit Notes';
  static const String noStaffAssignedToSession =
      'No staff assigned to this session.';

  // ── Doctor Overlay & Picker ──
  static const String selectDoctors = 'Select Doctors';
  static const String chooseDoctor = 'Choose Doctor';
  static const String searchDoctorsHint = 'Search doctors…';
  static const String searchAndAssignDoctors = 'Search & Assign Doctors';
  static const String typeDoctorName = 'Type doctor name...';
  static const String noMatchingDoctorsFound = 'No matching doctors found.';
  static const String errorLoadingDoctors = 'Error loading doctors.';
  static const String atLeastOneDoctorRequired =
      'At least one doctor is required.';
  static const String unableToLoadDoctors =
      'Unable to load doctors — tap refresh icon to retry';
  static const String tapToSelectDoctors = 'Tap to select doctors';
  static const String changeDoctor = 'Change Doctor';
  static const String addDoctor = 'Add Doctor';
  static const String done = 'Done';
  static String selectedCount(int count) => '$count selected';
  static String assignedCount(int count) => '$count assigned';

  // ── Patient Tabs ──
  static const String usePackageBalance = 'Use Package Balance';
  static const String noPaymentsRecorded = 'No payments recorded';
  static const String totalPaid = 'Total Paid';
  static const String amountDue = 'Amount Due';
  static const String noDoctorsAssigned = 'No doctors assigned';
  static const String errorLoadingAssignedDoctors =
      'Error loading assigned doctors';
  static const String tabInfo = 'Info';
  static const String tabRecords = 'Notes';
  static const String tabDocuments = 'Documents';
  static const String sortOptions = 'Sort Options';
  static const String totalNotes = 'Total Notes';
  static const String addNote = 'Add Note';
  static const String noNotesRecorded = 'No notes recorded yet';
  static const String quickActions = 'Quick Actions';
  static const String collectPayment = 'Collect Payment';
  static const String contact = 'Contact';
  static const String lastVisit = 'Last Visit';
  static const String lastVisitLabelShort = 'Last:';
  static const String noVisitsYet = 'No visits yet';
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
  static const String attendanceRate = 'Attendance Rate';
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
  static const String noAppointmentData =
      'No appointment data for this period.';
  static const String noStaffData = 'No staff data for this period.';
  static const String noPatientData = 'No patient data for this period.';
  static const String cashPayments = 'Cash / Card';
  static const String packageRedemptions = 'Package Redemptions';
  static const String patientsWithNegativeBalance =
      'Patients with negative balance';
  static const String packagesSold = 'Packages Sold';
  static const String packagesSoldValue = 'Packages Sold Value';
  static const String sessionsCheckedIn = 'Sessions Checked In';
  static const String patientsInOverdraft = 'Patients in Overdraft';
  static const String ptSessionsOwed = 'PT Sessions Owed';
  static const String tractionSessionsOwed = 'Traction Sessions Owed';
  static const String activeDays = 'Active Days';
  static const String doctorLog = 'Doctor Log';
  static const String noActivity = 'No activity recorded';

  // Package usage filter labels
  static const String packageFilterAll = 'All';
  static const String packageFilterPackage = 'Package';
  static const String packageFilterNoPackage = 'No Package';

  // ── Patient Pill Access (appointment detail header) ──
  static const String collapse = 'Collapse';

  // Booking workboard
  static const String booking = 'Booking';
  static const String duePatients = 'Due patients';
  static const String schedule = 'Schedule';
  static const String selectDoctor = 'Select doctor';
  static const String chooseBranchToStart = 'Choose a branch to start booking.';
  static const String noDuePatients = 'No patients are due for this date.';
  static const String noScheduleForDate =
      'No appointments booked for this date.';
  static const String previousDay = 'Previous day';
  static const String nextDay = 'Next day';
  static const String chooseDate = 'Choose date';
  static const String call = 'Call';
  static const String copyPhone = 'Copy phone';
  static const String phoneCopied = 'Phone number copied.';
  static const String book = 'Book';
  static const String remindLater = 'Remind later';
  static const String stopFollowUp = 'Stop follow-up';
  static const String stopFollowUpTitle = 'Stop following up?';
  static const String stopFollowUpMessage =
      'This patient will no longer appear in the booking list.';
  static const String nextVisit = 'Next visit';
  static const String setNextVisit = 'Set next visit';
  static const String clearNextVisit = 'Clear next visit';
  static const String nextVisitUpdated = 'Next visit updated.';
  static const String noNextVisitSet = 'No next visit set.';
  static const String change = 'Change';
  static const String dueBookingChanged =
      'This patient was already booked or their next visit changed. Refresh and try again.';
  static const String pastScheduledNeedsAction =
      'Missed appointment';

  // Doctor replacement
  static const String replaceDoctor = 'Replace doctor';
  static const String replacementDoctors = 'Replacement doctors';
  static const String selectReplacementDoctors = 'Select replacement doctors';
  static const String affectedAppointments = 'Affected appointments';
  static const String selectAll = 'Select all';
  static const String noReplaceableAppointments =
      'No replaceable appointments remain.';
  static const String replacementSelectionRequired =
      'Select at least one doctor and appointment.';
  static String replaceDoctorTitle(String name) => 'Replace $name';
  static String replaceOnAppointments(int count) =>
      'Replace on $count appointment${count == 1 ? '' : 's'}';
  static String replacementSucceeded(int replaced, int remaining) =>
      '$replaced appointment${replaced == 1 ? '' : 's'} reassigned. '
      '$remaining remain.';
  static String dueOn(String date) => 'Due $date';
  static String overdueSince(String date) => 'Overdue $date';
  static String sectionCount(String label, int count) => '$label ($count)';
  static String doctorsSelected(int count) =>
      '$count doctor${count == 1 ? '' : 's'} selected';
  static String replacementSummary(String date, int count) =>
      '$date, $count affected appointment${count == 1 ? '' : 's'}';

  // Doctor replacement — day picker step (added between absent-doctor
  // selection and the appointment fetch).
  static const String replacementDayPickerTitle = 'Which day?';
  static String replacementDayPickerSubtitle(String name) =>
      '$name will be away on:';
  static const String dayToday = 'Today';
  static const String dayTomorrow = 'Tomorrow';
  static const String pickADay = 'Pick a day';
  static const String dayPickerContinue = 'Continue';

  // Next-visit follow-up surface (patient detail + appointment detail)
  static const String manage = 'Manage';
  static const String patientFollowUp = 'Patient\'s next expected visit';
  static const String nextVisitOptions = 'Next visit options';
  static const String nextVisitChangeAction = 'Change date';
  static const String nextVisitClearAction = 'Clear date';
  static const String tapToSetNextVisit = 'Tap to set next visit';
  static const String clearFollowUpTitle = 'Clear follow-up date?';
  static String clearFollowUpConfirmBody(String patientName) =>
      'This will clear the next visit date for $patientName. '
      'They will no longer appear on the booking due list.';

  // Today-tab Replace Doctor banner
  static const String replaceDoctorTodayBannerTitle = 'Replace doctor';
  static const String replaceDoctorTodayBannerSubtitle =
      'Move a doctor\u2019s appointments to another doctor today.';
  static const String selectAbsentDoctor = 'Pick the absent doctor';
  static const String selectAbsentDoctorSubtitle =
      'Choose which doctor\u2019s day you need to reassign.';
  static const String noDoctorsWithTodayLoad =
      'No doctors have appointments today.';
  static const String cannotReplaceWithSelf =
      'A doctor cannot cover for themselves.';

  // Senior Doctor Assessment & Programs
  static const String seniorDoctor = 'Senior Doctor';
  static const String juniorDoctor = 'Junior Doctor';
  static const String isSeniorDoctor = 'Senior Doctor Assessment Role';
  static const String isSeniorDoctorDescription =
      'Allows creating and managing patient assessments, programs, and treatment plans.';

  // Medical History
  static const String medicalHistory = 'Medical History';
  static const String editMedicalHistory = 'Edit Medical History';
  static const String diabetes = 'Diabetes';
  static const String hba1c = 'HbA1c';
  static const String hba1cValue = 'HbA1c Value';
  static const String hba1cHint = 'e.g. 6.5%';
  static const String hypertension = 'Hypertension';
  static const String hyperlipidemia = 'Hyperlipidemia';
  static const String rheumatology = 'Rheumatology';
  static const String rheumatologyDetails = 'Rheumatology Details';
  static const String rheumatologyDetailsHint = 'Condition details, medications\u2026';
  static const String additionalMedicalNotes = 'Additional Medical Notes';
  static const String additionalMedicalNotesHint = 'Other conditions, surgical history\u2026';
  static const String noMedicalHistoryRecorded = 'No medical history recorded yet.';
  static const String medicalHistorySaved = 'Medical history saved.';

  // Body Regions
  static const String regionShoulder = 'Shoulder';
  static const String regionElbow = 'Elbow';
  static const String regionHand = 'Hand';
  static const String regionLumbarSpine = 'Lumbar Spine';
  static const String regionThoracicSpine = 'Thoracic Spine';
  static const String regionCervicalSpine = 'Cervical Spine';
  static const String regionHipJoint = 'Hip Joint';
  static const String regionKneeJoint = 'Knee Joint';
  static const String regionAnkleJoint = 'Ankle Joint';
  static const String regionFoot = 'Foot';

  // Program Lifecycle & Status
  static const String programs = 'Programs';
  static const String newProgram = 'New Program';
  static const String editProgram = 'Edit Program';
  static const String programDetails = 'Program Details';
  static const String programActive = 'Active';
  static const String programCompleted = 'Completed';
  static const String programArchived = 'Archived';
  static const String affectedRegions = 'Affected Regions';
  static const String selectInjuries = 'Select Injuries / Conditions';
  static const String examination = 'Physical Examination';
  static const String examinationHint = 'ROM, special tests, palpation findings\u2026';
  static const String imagingNotes = 'Imaging Findings';
  static const String imagingNotesHint =
      'X-ray, MRI, CT scan interpretation…';
  static const String exaggeratingPositions = 'Exaggerating Positions';
  static const String exaggeratingPositionsHint = 'Positions/movements that worsen pain…';
  static const String relievingPositions = 'Relieving Positions';
  static const String relievingPositionsHint = 'Positions/movements that ease pain…';
  static const String programNotes = 'Program Notes';
  static const String programNotesHint = 'General clinical notes for this program…';
  static const String noProgramsRecorded = 'No rehabilitation programs created yet.';
  static const String programSaved = 'Program saved.';
  static const String deleteProgram = 'Delete Program';
  static const String deleteProgramConfirm =
      'Are you sure you want to delete this program and all its treatment plans?';
  static const String attachImagingFiles = 'Attach Images / Scans';
  static const String imagingAttachments = 'Imaging Attachments';
  static const String scanCount = 'Scans';
  static const String imageLabel = 'Image';
  static const String pdfLabel = 'PDF';
  static const String viewScans = 'View Scans';
  static const String noAttachments = 'No imaging files attached';
  static String scanItemIndex(int current, int total) => '$current of $total';
  static String scanCountLabel(int count) =>
      '$count ${count == 1 ? 'Scan' : 'Scans'}';
  static const String allBodyRegions = 'All Body Regions';
  static const String filterByRegion = 'Filter by Region';

  // Modality Types
  static const String modalityMusclePain = 'Muscle Pain';
  static const String modalityMassBuilt = 'Mass Built';
  static const String modalityTecar = 'TECAR';
  static const String modalityTecarFocal = 'TECAR Focal Technique';
  static const String modalityNeurodynamicNonWb = 'Neurodynamic (Non-WB)';
  static const String modalityNeurodynamicWb = 'Neurodynamic (WB)';

  // Lateralities
  static const String lateralityRight = 'Right';
  static const String lateralityLeft = 'Left';
  static const String lateralityBoth = 'Both';
  static const String lateralityNone = 'General / None';

  // Treatment Plans
  static const String treatmentPlans = 'Treatment Plans';
  static const String treatmentPlan = 'Treatment Plan';
  static const String newTreatmentPlan = 'New Treatment Plan';
  static const String editTreatmentPlan = 'Edit Treatment Plan';
  static const String planName = 'Plan Name';
  static const String planActive = 'Active Plan';
  static const String planArchived = 'Archived Plan';
  static const String addModality = 'Add Modality';
  static const String addRegion = 'Add Target Region';
  static const String targetRegion = 'Target Region';
  static const String durationMinutes = 'Duration (minutes)';
  static const String planSaved = 'Treatment plan saved.';
  static const String noTreatmentPlans = 'No treatment plans in this program.';
  static const String exportProgramPdf = 'Export Program PDF';
  static const String selectModalities = 'Select Modalities';
  static const String configureRegions = 'Configure Target Regions';
  static const String treatmentPlanSaved = 'Treatment plan saved successfully.';
  static const String treatmentPlanDeleted = 'Treatment plan deleted.';
  static const String deleteTreatmentPlan = 'Delete Treatment Plan';
  static const String deleteTreatmentPlanConfirm =
      'Are you sure you want to delete this treatment plan and its configured modalities?';
  static const String noRegionsConfigured = 'No target regions configured.';
  static const String totalDuration = 'Total Duration';
  static const String minutesAbbreviation = 'min';
  static const String planNotes = 'Plan Notes';
  static const String planNotesHint =
      'Enter specific treatment instructions, precautions, or notes...';
  static const String planNameHint = 'e.g. Plan 1 - Acute Phase';
  static const String modalityNotes = 'Modality Notes';
  static const String modalityNotesHint =
      'Intensity, parameters, or specific technique notes...';
  static const String activePlanToggle = 'Set as Active Plan';
  static const String activePlanSubtitle =
      'Active plan will be executed during patient visits';
  static const String noModalitiesSelected =
      'No modalities selected. Tap a modality card above to configure.';
  static const String previousPlans = 'Previous Plan Versions';
  static const String planHistory = 'Plan History';
  static const String setAsActive = 'Set as Active';
  static const String planActivated = 'Plan activated successfully.';
  static const String newPlanVersion = 'New Plan Version';
  static const String activate = 'Activate';
  static const String inactive = 'Inactive';
  static String createdOn(String date) => 'Created $date';
  static String modalitiesCount(int count) =>
      '$count ${count == 1 ? 'Modality' : 'Modalities'}';
  static String regionsCount(int count) =>
      '$count ${count == 1 ? 'Region' : 'Regions'}';
  static String durationFormat(int min) => '$min min';
  static String totalDurationFormat(int min) => '$min min total';
  static String scansCount(int count) => '$count ${count == 1 ? 'Scan' : 'Scans'}';
  static String regionsAndConditionsCount(int regions, int conditions) =>
      '$regions ${regions == 1 ? 'Region' : 'Regions'} · $conditions ${conditions == 1 ? 'Condition' : 'Conditions'}';

  // Program form sections & feedback
  static const String clinicalFindingsSection = 'Clinical Findings';
  static const String positionsSection = 'Positions & Notes';
  static const String noConditionsSelected =
      'Select at least one injury to define the affected regions.';
  static const String programNotFound = 'Program not found.';
  static const String programDeleted = 'Program deleted.';
  static const String setStatus = 'Status';
  static const String conditionUnspecified = 'Condition details';
  static const String noMatchingConditions = 'No matching conditions found.';
  static const String selectConditionRequired =
      'Please select at least one condition/injury.';
  static String conditionsSelected(int count) => '$count selected';
  static String moreConditions(int count) => '+$count more conditions';
  static String createdLabel(String date) => 'Created: $date';
  static String setStatusLabel(String status) => 'Set $status';
}

