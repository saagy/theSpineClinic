import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_search_field.dart';

/// Top header bar for the patients screen featuring title, search,
/// filter button with active count indicator, and "+ New Patient" CTA.
class PatientListHeader extends StatelessWidget {
  const PatientListHeader({
    super.key,
    required this.totalCount,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onFilterTap,
    required this.activeFiltersCount,
    required this.canCreatePatient,
    required this.onNewPatientTap,
  });

  final int? totalCount;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterTap;
  final int activeFiltersCount;
  final bool canCreatePatient;
  final VoidCallback onNewPatientTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p20,
        AppSizes.p16,
        AppSizes.p20,
        AppSizes.p12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    AppStrings.patients,
                    style: AppTextStyles.headingLarge.copyWith(
                      color: cs.onSurface,
                    ),
                  ),
                  if (totalCount != null) ...[
                    const SizedBox(width: AppSizes.p10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p8,
                        vertical: AppSizes.p2,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppSizes.r12),
                      ),
                      child: Text(
                        '$totalCount',
                        style: AppTextStyles.captionBold.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 12.0,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (canCreatePatient)
                FilledButton.icon(
                  onPressed: onNewPatientTap,
                  icon: const Icon(LucideIcons.plus, size: 16.0),
                  label: Text(
                    AppStrings.newPatientButton,
                    style: AppTextStyles.bodyBold,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p16,
                      vertical: AppSizes.p10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.r8),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.p4),
          Text(
            AppStrings.patientsSubtitle,
            style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: AppSizes.p16),
          _buildControlsRow(context),
        ],
      ),
    );
  }

  Widget _buildControlsRow(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(child: PatientSearchField(onChanged: onSearchChanged)),
        const SizedBox(width: AppSizes.p8),
        OutlinedButton.icon(
          onPressed: onFilterTap,
          icon: Icon(
            LucideIcons.sliders_horizontal,
            size: 16.0,
            color: activeFiltersCount > 0 ? cs.primary : cs.onSurfaceVariant,
          ),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.filtersButton,
                style: AppTextStyles.captionBold.copyWith(
                  color: activeFiltersCount > 0 ? cs.primary : cs.onSurface,
                ),
              ),
              if (activeFiltersCount > 0) ...[
                const SizedBox(width: AppSizes.p6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$activeFiltersCount',
                    style: AppTextStyles.captionBold.copyWith(
                      color: cs.onPrimary,
                      fontSize: 10.0,
                    ),
                  ),
                ),
              ],
            ],
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: activeFiltersCount > 0 ? cs.primary : cs.outlineVariant,
              width: AppSizes.borderWidth,
            ),
            backgroundColor: activeFiltersCount > 0
                ? cs.primaryContainer.withAlpha(80)
                : cs.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p12,
              vertical: AppSizes.p10,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.r8),
            ),
            minimumSize: const Size(0, AppSizes.tappableMin),
          ),
        ),
      ],
    );
  }
}
