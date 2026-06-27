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
  });

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            text.toUpperCase(),
            style: AppTextStyles.captionMedium.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}
