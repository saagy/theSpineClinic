/// A CircleAvatar that derives initials from a name string.
///
/// Edge cases (Rule 20): names starting with numbers, single-character
/// names, and empty names all fall back to [Icons.person].
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';

/// A dynamic avatar that extracts up to two letter initials from [name].
///
/// When valid letter initials cannot be derived the widget renders
/// [Icons.person] as a fallback.
class AppAvatar extends StatelessWidget {
  /// Creates an [AppAvatar].
  const AppAvatar({
    super.key,
    required this.name,
    this.radius,
    this.color,
  });

  /// The full name to derive initials from (e.g. "Hassan Shaker" → "HS").
  final String name;

  /// Avatar radius. Defaults to 23 (matching [AppSizes.avatarTile] / 2).
  final double? radius;

  /// Avatar background color. Defaults to [AppColors.primary].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final double r = radius ?? 23;
    final String? initials = _deriveInitials(name);

    return CircleAvatar(
      radius: r,
      backgroundColor: color ?? AppColors.primary,
      child: initials != null
          ? Text(
              initials,
              style: TextStyle(
                color: AppColors.textOnPrimary,
                fontSize: r * 0.44,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            )
          : Icon(
              Icons.person,
              color: AppColors.textOnPrimary,
              size: r * 0.52,
            ),
    );
  }

  /// Returns one or two uppercase letter initials, or `null` when none
  /// can be derived (empty name, name starts with a digit, etc.).
  String? _deriveInitials(String fullName) {
    final String trimmed = fullName.trim();
    if (trimmed.isEmpty) return null;

    final List<String> parts = trimmed.split(RegExp(r'\s+'));
    if (parts.isEmpty) return null;

    final String first = _firstLetter(parts.first);
    if (first.isEmpty) return null;

    if (parts.length >= 2) {
      final String second = _firstLetter(parts[1]);
      if (second.isNotEmpty) return '$first$second';
    }
    // Single name — just render the first letter.
    return first;
  }

  /// Returns the first character of [word] as uppercase if it is an
  /// ASCII letter, or an empty string otherwise.
  String _firstLetter(String word) {
    if (word.isEmpty) return '';
    final int code = word.codeUnitAt(0);
    if ((code >= 65 && code <= 90) || (code >= 97 && code <= 122)) {
      return word[0].toUpperCase();
    }
    return '';
  }
}
