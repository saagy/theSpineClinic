/// Context menu for payment rows styled consistently with appointment cards.
///
/// Rule 1 — under 200 lines.
/// Rule 15/16 — colorScheme and AppTextStyles tokens.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Trailing popup menu for payment actions (Edit / Delete).
class PaymentActionsMenu extends StatelessWidget {
  const PaymentActionsMenu({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz_rounded,
        color: cs.onSurfaceVariant,
        size: AppSizes.iconDefault,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      splashRadius: AppSizes.iconDefault,
      color: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r12)),
      ),
      elevation: 2,
      position: PopupMenuPosition.under,
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'edit',
          height: AppSizes.buttonHeightSmall,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit_outlined,
                color: cs.primary,
                size: AppSizes.iconSmall,
              ),
              const SizedBox(width: AppSizes.p8),
              Text(
                AppStrings.edit,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          height: AppSizes.buttonHeightSmall,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delete_outline_rounded,
                color: cs.error,
                size: AppSizes.iconSmall,
              ),
              const SizedBox(width: AppSizes.p8),
              Text(
                AppStrings.delete,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: cs.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
