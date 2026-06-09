import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/payments/domain/clinic_package.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Presentation card displaying package details with Edit and Delete controls.
class ClinicPackageCard extends StatelessWidget {
  /// Creates a [ClinicPackageCard] instance.
  const ClinicPackageCard({
    super.key,
    required this.package,
    required this.onEdit,
    required this.onDelete,
  });

  /// The clinic package details to display.
  final ClinicPackage package;

  /// Callback triggered when edit action is tapped.
  final VoidCallback onEdit;

  /// Callback triggered when delete action is tapped.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package.name,
                  style: AppTextStyles.bodyBold.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.p4),
                Row(
                  children: [
                    Text(
                      '${package.sessionCount} Sessions',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSizes.p8),
                    Text(
                      '•',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: AppSizes.p8),
                    Text(
                      package.price.toCurrencyString(),
                      style: AppTextStyles.captionMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit_rounded,
                  color: AppColors.textSecondary,
                  size: AppSizes.iconDefault,
                ),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                  size: AppSizes.iconDefault,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
