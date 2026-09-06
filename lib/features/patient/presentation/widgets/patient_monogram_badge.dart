import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// A compact, muted circular badge displaying patient initials.
///
/// Tinted subtly from the brand color palette (#2B4D73) with
/// robust fallback to [LucideIcons.user] when letters are unavailable.
/// Conforms to Rule 1 (<200 lines), Rule 15/16 (Theme colors only),
/// and Rule 20 (Initials Avatar Fallback).
class PatientMonogramBadge extends StatelessWidget {
  const PatientMonogramBadge({
    super.key,
    required this.name,
    this.size = 32.0,
  });

  final String name;
  final double size;

  static final RegExp _alpha = RegExp(r'[a-zA-Z]');

  String? _deriveInitials(String rawName) {
    final trimmed = rawName.trim();
    if (trimmed.isEmpty) return null;

    final parts = trimmed
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty && _alpha.hasMatch(part[0]))
        .toList();

    if (parts.isEmpty) return null;
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initials = _deriveInitials(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        shape: BoxShape.circle,
        border: Border.all(
          color: cs.outlineVariant.withAlpha(120),
          width: AppSizes.borderWidth,
        ),
      ),
      alignment: Alignment.center,
      child: initials != null
          ? Text(
              initials,
              style: AppTextStyles.captionBold.copyWith(
                color: cs.onPrimaryContainer,
                fontSize: size * 0.4,
                letterSpacing: 0.5,
              ),
            )
          : Icon(
              LucideIcons.user,
              size: size * 0.5,
              color: cs.onPrimaryContainer,
            ),
    );
  }
}
