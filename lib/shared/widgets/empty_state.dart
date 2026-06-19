/// Custom empty state placeholder widget matching the Medics design tokens.
///
/// Renders a large teal-tinted icon and warm, human-friendly descriptive
/// text when list queries or searches return zero active records.
/// Touch-neutral.
///
/// All colours are resolved from [Theme.of(context).colorScheme] for
/// automatic dark-mode compatibility.
///
/// Rule 1 — keep files under 200 lines.
/// Rule 16 — zero hardcoded colours, all via theme.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

/// A centered layout placeholder for empty data states styled with
/// Medics design tokens.
class EmptyState extends StatelessWidget {
  /// Creates an [EmptyState].
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_rounded,
    this.secondaryMessage,
    this.actionLabel,
    this.onActionPressed,
  });

  /// The descriptive string explaining why the view is blank.
  final String message;

  /// The line-art icon indicating an empty data bucket state.
  final IconData icon;

  /// Optional secondary message below the primary one.
  final String? secondaryMessage;

  /// Optional label for the action button.
  final String? actionLabel;

  /// Optional callback when action button is pressed.
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Large teal-tinted icon in a soft circle background
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: AppSizes.p20),
            // Primary empty message
            Text(
              message,
              style: AppTextStyles.bodyLarge.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (secondaryMessage != null) ...[
              const SizedBox(height: AppSizes.p8),
              Text(
                secondaryMessage!,
                style: AppTextStyles.caption.copyWith(
                  color: cs.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: AppSizes.p20),
              AppButton(
                labelText: actionLabel!,
                onPressed: onActionPressed,
                fullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
