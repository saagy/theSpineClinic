/// A CircleAvatar that derives initials from a name string.
///
/// Edge cases (Rule 20): names starting with numbers, single-character
/// names, and empty names all fall back to [Icons.person].
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

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
    this.icon,
  });

  /// The full name to derive initials from (e.g. "Hassan Shaker" → "HS").
  final String name;

  /// Avatar radius. Defaults to 23 (matching [AppSizes.avatarTile] / 2).
  final double? radius;

  /// Avatar background color. Defaults to the active theme primary color.
  final Color? color;

  /// Optional icon to display instead of initials or default person icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final double r = radius ?? 23;
    final String? initials = icon != null ? null : _deriveInitials(name);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double fontSize = initials != null
        ? (initials.length == 1 ? r * 0.90 : r * 0.78)
        : r * 0.78;

    return CircleAvatar(
      radius: r,
      backgroundColor: color ?? cs.primary,
      child: icon != null
          ? Icon(icon, color: cs.onPrimary, size: r * 1.1)
          : initials != null
              ? Text(
                  initials,
                  style: AppTextStyles.avatarInitials(
                    fontSize: fontSize,
                    color: cs.onPrimary,
                  ),
                )
              : Icon(Icons.person, color: cs.onPrimary, size: r * 1.1),
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
