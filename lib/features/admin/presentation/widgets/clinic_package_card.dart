import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/payments/domain/clinic_package.dart';
import 'package:spine_clinic_app/features/payments/domain/package_kind.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Displays a configured clinic package with kind label, count summary,
/// price, and Edit / Delete actions.
class ClinicPackageCard extends StatelessWidget {
  /// Creates a [ClinicPackageCard].
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

  String _kindLabel() => switch (package.kind) {
        PackageKind.session => AppStrings.packageKindSession,
        PackageKind.traction => AppStrings.packageKindTraction,
        PackageKind.combined => AppStrings.packageKindCombined,
      };

  Color _kindColor() => switch (package.kind) {
        PackageKind.session => AppColors.primary,
        PackageKind.traction => AppColors.warning,
        PackageKind.combined => AppColors.info,
      };

  String _countSummary() {
    final List<String> parts = [];
    if (package.kind != PackageKind.traction && package.sessionCount > 0) {
      parts.add('${package.sessionCount} ${AppStrings.packageSummarySessions}');
    }
    if (package.kind != PackageKind.session && package.tractionsCount > 0) {
      parts.add('${package.tractionsCount} ${AppStrings.packageSummaryTractions}');
    }
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        package.name,
                        style: AppTextStyles.bodyBold.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSizes.p8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p8,
                        vertical: AppSizes.p2,
                      ),
                      decoration: BoxDecoration(
                        color: _kindColor().withAlpha(20),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(AppSizes.r999)),
                      ),
                      child: Text(
                        _kindLabel(),
                        style: AppTextStyles.caption.copyWith(
                          color: _kindColor(),
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.p4),
                Text(
                  _countSummary(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.p2),
                Text(
                  package.price.toCurrencyString(),
                  style: AppTextStyles.captionMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
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
