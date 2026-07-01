/// Eyebrow label — uppercase, letter-spaced, secondary colour.
///
/// Used as a section header in cardless document layouts
/// (appointment detail, patient info tab).
///
/// Rule 15/16 — colours via Theme.of(context).colorScheme.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

class EyebrowLabel extends StatelessWidget {
  const EyebrowLabel({
    super.key,
    required this.text,
    this.action,
    this.isUppercase = true,
    this.fontSize,
  });

  final String text;
  final Widget? action;
  final bool isUppercase;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            isUppercase ? text.toUpperCase() : text,
            style: AppTextStyles.captionMedium.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: fontSize ?? (isUppercase ? 12.0 : 14.0),
              letterSpacing: isUppercase ? 1.2 : 0.0,
            ),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}
