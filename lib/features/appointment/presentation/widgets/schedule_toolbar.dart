import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_search_field.dart';

/// Clean search and filter toolbar for the appointments schedule tab,
/// mirroring the structure and elegance of [PatientListHeader].
class ScheduleToolbar extends StatelessWidget {
  const ScheduleToolbar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.activeFiltersCount,
    required this.onFilterTap,
  });

  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final int activeFiltersCount;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool hasActiveFilter = activeFiltersCount > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p16,
        AppSizes.p4,
        AppSizes.p16,
        AppSizes.p8,
      ),
      child: Row(
        children: [
          Expanded(
            child: AppointmentSearchField(
              initialValue: searchQuery,
              onChanged: onSearchChanged,
            ),
          ),
          const SizedBox(width: AppSizes.p8),
          OutlinedButton.icon(
            onPressed: onFilterTap,
            icon: Icon(
              LucideIcons.sliders_horizontal,
              size: 16.0,
              color: hasActiveFilter ? cs.primary : cs.onSurfaceVariant,
            ),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.filtersButton,
                  style: AppTextStyles.captionBold.copyWith(
                    color: hasActiveFilter ? cs.primary : cs.onSurface,
                  ),
                ),
                if (hasActiveFilter) ...[
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
                color: hasActiveFilter ? cs.primary : cs.outlineVariant,
                width: AppSizes.borderWidth,
              ),
              backgroundColor: hasActiveFilter
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
      ),
    );
  }
}
