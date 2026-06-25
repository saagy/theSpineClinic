/// Authentication flow and form validation string constants.
///
/// Split from [AppStrings] to respect the 200-line boundary (Rule 1).
/// Rule 7 — no hardcoded strings anywhere outside constants files.
library;

/// Auth-specific and form validation string constants.
abstract final class AppStringsAuth {
  // ──────────────────── Auth Flow ────────────────────

  static const String welcomeBack = 'Yeay! Welcome Back';
  static const String signInToContinue = 'Sign in to continue';
  static const String signIn = 'Sign In';
  static const String signOut = 'Sign Out';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String register = 'Register';
  static const String doctorRegistration = 'Doctor Registration';
  static const String registration = 'Registration';
  static const String accountType = 'Account Type';
  static const String pendingApproval =
      'Your account is pending admin approval.';
  static const String registrationSuccess =
      'Registration submitted. Please wait for admin approval.';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String registerAsDoctor = 'Register as a Doctor';
  static const String registerAsReceptionist = 'Register as a Receptionist';
  static const String registrationSubmittedTitle = 'Application Submitted';
  static const String registrationSubmittedMessage =
      'Your application has been submitted. '
      'You will be notified once it is reviewed.';
  static const String backToLogin = 'Back to Login';

  // ──────────────────── Form Validation ────────────────────

  static const String validationRequired = 'This field is required.';
  static const String validationMinThreeChars =
      'Must be at least 3 characters.';
  static const String validationMinEightChars =
      'Must be at least 8 characters.';
  static const String validationEmailInvalid =
      'Please enter a valid email address.';
  static const String validationPasswordsDoNotMatch =
      'Passwords do not match.';
  static const String validationPhoneInvalid =
      'Please enter a valid phone number (digits only).';
  static const String validationDoctorRequired =
      'At least one doctor must be assigned.';
  static const String patientUpdatedSuccess =
      'Patient updated successfully.';
}
