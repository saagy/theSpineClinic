/// Data formatting and validator utility functions.
///
/// Provides strict, clean formatting for currencies, dates, and phone numbers,
/// alongside standard validations tailored for high-density dashboard layouts.
///
/// Rule 1 — keep files compact and clean.
library;

import 'package:intl/intl.dart';

/// Central utility class for layout-safe data formatting.
abstract final class Formatters {
  // ──────────────────── Currency Formatting ────────────────────

  /// Formats a balance amount into a Stripe-style Egyptian Pound (EGP) string.
  ///
  /// Whole numbers: `5,000 EGP`
  /// Numbers with decimals: `5,000.50 EGP`
  static String formatCurrency(num amount) {
    // If the number has no decimal part, format as integer
    final bool hasDecimals = amount % 1 != 0;
    final String pattern = hasDecimals ? '#,##0.00' : '#,##0';
    final NumberFormat formatter = NumberFormat(pattern, 'en_US');
    return '${formatter.format(amount)} EGP';
  }

  // ──────────────────── Date & Time Formatting ────────────────────

  /// Formats a [DateTime] into a clean short table-row numeric string: `dd/MM/yyyy`.
  ///
  /// Always converts to local time before formatting so that UTC timestamps
  /// from Supabase display in Cairo local time.
  ///
  /// Example: `24/10/2026`
  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date.toLocal());
  }

  /// Formats a [DateTime] into a human-readable medium structure: `MMM d, yyyy`.
  ///
  /// Always converts to local time before formatting so that UTC timestamps
  /// from Supabase display in Cairo local time.
  ///
  /// Example: `Oct 24, 2026`
  static String formatDateMedium(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date.toLocal());
  }

  /// Formats a [DateTime] with hour and minute resolution: `MMM d, yyyy, hh:mm a`.
  ///
  /// Always converts to local time before formatting so that UTC timestamps
  /// from Supabase display in Cairo local time.
  ///
  /// Example: `Oct 24, 2026, 04:30 PM`
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM d, yyyy, hh:mm a').format(date.toLocal());
  }

  /// Formats a [DateTime] into a short time-only layout: `hh:mm a`.
  ///
  /// Always converts to local time before formatting so that UTC timestamps
  /// from Supabase display in Cairo local time.
  ///
  /// Example: `04:30 PM`
  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date.toLocal());
  }

  // ──────────────────── Phone Formatting ────────────────────

  /// Formats a raw phone string into a standardized Egyptian mobile structure.
  ///
  /// Target: `+20 1XX XXX XXXX`
  ///
  /// Inputs like `01012345678`, `1012345678`, or `+201012345678` are all cleaned
  /// and standardized.
  static String formatPhone(String rawPhone) {
    // Keep only digits
    String digits = rawPhone.replaceAll(RegExp(r'\D'), '');

    // Strip leading country code or zero if present
    if (digits.startsWith('20')) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    // Egyptian mobile numbers have 10 digits after stripping leading 0 (e.g. 1012345678)
    if (digits.length == 10) {
      final String carrierCode = digits.substring(0, 3); // 101, 111, 121, 151 etc.
      final String group1 = digits.substring(3, 6);
      final String group2 = digits.substring(6);
      return '+20 $carrierCode $group1 $group2';
    }

    // Fallback if formatting doesn't fit standard structure
    return rawPhone.trim();
  }
}

/// Helper extension on DateTime for clean styling layout chains.
extension DateTimeFormatting on DateTime {
  /// Resolves to table-row short structure `24/10/2026`.
  String toShortDateString() => Formatters.formatDateShort(this);

  /// Resolves to dashboard medium structure `Oct 24, 2026`.
  String toMediumDateString() => Formatters.formatDateMedium(this);

  /// Resolves to full timestamp structure `Oct 24, 2026, 04:30 PM`.
  String toDateTimeString() => Formatters.formatDateTime(this);

  /// Resolves to compact time structure `04:30 PM`.
  String toTimeString() => Formatters.formatTime(this);
}

/// Helper extension on num for inline price printing.
extension NumFormatting on num {
  /// Formats numeric value as currency. E.g. `5,000 EGP`
  String toCurrencyString() => Formatters.formatCurrency(this);
}

/// Form Validation Schemas and Parsing Utilities.
abstract final class Validators {
  /// Matches RFC 5322 official standard for email addresses.
  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$",
  );

  /// Matches valid Egyptian mobile numbers (10 digits starting with 10, 11, 12, 15, or 11 digits starting with 010, 011, 012, 015).
  static final RegExp _egyptianPhoneRegex = RegExp(
    r'^(?:\+?20|0)?1[0125]\d{8}$',
  );

  /// Evaluates if email matches correct parsing scheme.
  static bool isValidEmail(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    return _emailRegex.hasMatch(email.trim());
  }

  /// Validates Egyptian mobile phone syntax.
  static bool isValidPhone(String? phone) {
    if (phone == null || phone.replaceAll(RegExp(r'\s'), '').isEmpty) return false;
    final String clean = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return _egyptianPhoneRegex.hasMatch(clean);
  }

  /// Checks if value is a valid positive/negative integer or float value.
  static bool isNumeric(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    return double.tryParse(value.trim()) != null;
  }
}
