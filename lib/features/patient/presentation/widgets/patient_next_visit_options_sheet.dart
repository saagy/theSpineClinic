/// Bottom-sheet body used by the patient detail Next-visit stat when a
/// follow-up date is already set. Lets the user either change the date
/// or clear it. Emits the chosen action through Navigator.pop.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Selection surfaced via Navigator.pop when the user taps an option row.
enum NextVisitAction { change, clear }

/// Bottom-sheet contents for the patient-detail next-visit options.
class NextVisitOptionsSheet extends StatelessWidget {
  const NextVisitOptionsSheet({
    super.key,
    required this.onChange,
    required this.onClear,
  });

  final VoidCallback onChange;
  final VoidCallback onClear;

  static Future<NextVisitAction?> show(BuildContext context) {
    return showModalBottomSheet<NextVisitAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface.withAlpha(0),
      elevation: 0,
      builder: (sheetContext) => _SheetChrome(
        onChange: () =>
            Navigator.of(sheetContext).pop(NextVisitAction.change),
        onClear: () =>
            Navigator.of(sheetContext).pop(NextVisitAction.clear),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _SheetChrome(
        onChange: onChange,
        onClear: onClear,
      );
}

class _SheetChrome extends StatelessWidget {
  const _SheetChrome({required this.onChange, required this.onClear});

  final VoidCallback onChange;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.r16),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p20,
          vertical: AppSizes.p16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: AppSizes.handleWidth,
                height: AppSizes.handleHeight,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius:
                      const BorderRadius.all(Radius.circular(AppSizes.p2)),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.p12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
              child: Text(
                AppStrings.nextVisitOptions,
                style: AppTextStyles.bodyBold.copyWith(color: cs.onSurface),
              ),
            ),
            const SizedBox(height: AppSizes.p8),
            _NextVisitOption(
              icon: Icons.edit_outlined,
              label: AppStrings.nextVisitChangeAction,
              onTap: onChange,
              iconColor: cs.primary,
            ),
            const SizedBox(height: AppSizes.p8),
            _NextVisitOption(
              icon: Icons.delete_outline_rounded,
              label: AppStrings.nextVisitClearAction,
              onTap: onClear,
              iconColor: cs.error,
            ),
          ],
        ),
      ),
    );
  }
}

class _NextVisitOption extends StatelessWidget {
  const _NextVisitOption({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.tappableMin),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p16,
            vertical: AppSizes.p12,
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: AppSizes.iconDefault),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyBold.copyWith(color: cs.onSurface),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: AppSizes.iconDefault,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
