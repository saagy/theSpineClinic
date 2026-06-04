/// Static form validation functions for the authentication screens.
///
/// Centralised here to keep [LoginScreen] and [DoctorRegisterScreen]
/// under the 200-line boundary. All user-facing messages come from
/// [AppStringsAuth] (Rule 7).
library;

import 'package:spine_clinic_app/core/constants/app_strings_auth.dart';

/// Reusable validator functions for auth form fields.
abstract final class AuthValidators {
  /// Validates that a value is present and non-empty.
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStringsAuth.validationRequired;
    }
    return null;
  }

  /// Validates full name: required, minimum 3 characters.
  static String? fullName(String? value) {
    final String? base = required(value);
    if (base != null) return base;
    if (value!.trim().length < 3) {
      return AppStringsAuth.validationMinThreeChars;
    }
    return null;
  }

  /// Validates email: required, valid format.
  static String? email(String? value) {
    final String? base = required(value);
    if (base != null) return base;
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value!.trim())) {
      return AppStringsAuth.validationEmailInvalid;
    }
    return null;
  }

  /// Validates phone: required, digits only.
  static String? phone(String? value) {
    final String? base = required(value);
    if (base != null) return base;
    final RegExp phoneRegex = RegExp(r'^[0-9]+$');
    if (!phoneRegex.hasMatch(value!.trim())) {
      return AppStringsAuth.validationPhoneInvalid;
    }
    return null;
  }

  /// Validates password: required, minimum 8 characters.
  static String? password(String? value) {
    final String? base = required(value);
    if (base != null) return base;
    if (value!.length < 8) {
      return AppStringsAuth.validationMinEightChars;
    }
    return null;
  }

  /// Returns a validator that checks confirm-password matches [getPassword].
  ///
  /// [getPassword] is a closure capturing the password controller so that
  /// cross-field validation works without passing controllers around.
  static String? Function(String?) confirmPassword(
    String Function() getPassword,
  ) {
    return (String? value) {
      final String? base = required(value);
      if (base != null) return base;
      if (value != getPassword()) {
        return AppStringsAuth.validationPasswordsDoNotMatch;
      }
      return null;
    };
  }
}
