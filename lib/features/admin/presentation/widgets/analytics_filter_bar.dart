import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/admin/presentation/analytics_providers.dart';

/// Time-range and branch filter bar for the analytics dashboard.
class AnalyticsFilterBar extends ConsumerWidget {
  const AnalyticsFilterBar({super.key});

  Future<void> _selectCustomRange(BuildContext context, WidgetRef ref) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textOnPrimary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(analyticsFilterProvider.notifier).setRange(
        AnalyticsTimeRange.custom,
        start: picked.start,
        end: picked.end.add(const Duration(hours: 23, minutes: 59, seconds: 59)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(analyticsFilterProvider);

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: filter.branchId,
                  decoration: InputDecoration(
                    labelText: AppStrings.clinic,
                    labelStyle: AppTextStyles.captionMedium.copyWith(color: AppColors.textSecondary),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    isDense: true,
                    contentPadding: AppSizes.paddingCell,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(AppSizes.r6)),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text(AppStrings.allClinics)),
                    DropdownMenuItem(value: 'tagamoa', child: Text(AppStrings.clinicTagamoa)),
                    DropdownMenuItem(value: 'masr_elgedida', child: Text(AppStrings.clinicMasrElgedida)),
                  ],
                  onChanged: (val) {
                    ref.read(analyticsFilterProvider.notifier).setBranch(val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _TimeChip(label: AppStrings.today, selected: filter.range == AnalyticsTimeRange.today, onTap: () => ref.read(analyticsFilterProvider.notifier).setRange(AnalyticsTimeRange.today)),
                const SizedBox(width: AppSizes.p8),
                _TimeChip(label: AppStrings.thisWeek, selected: filter.range == AnalyticsTimeRange.thisWeek, onTap: () => ref.read(analyticsFilterProvider.notifier).setRange(AnalyticsTimeRange.thisWeek)),
                const SizedBox(width: AppSizes.p8),
                _TimeChip(label: AppStrings.thisMonth, selected: filter.range == AnalyticsTimeRange.thisMonth, onTap: () => ref.read(analyticsFilterProvider.notifier).setRange(AnalyticsTimeRange.thisMonth)),
                const SizedBox(width: AppSizes.p8),
                _TimeChip(label: AppStrings.lastMonth, selected: filter.range == AnalyticsTimeRange.lastMonth, onTap: () => ref.read(analyticsFilterProvider.notifier).setRange(AnalyticsTimeRange.lastMonth)),
                const SizedBox(width: AppSizes.p8),
                _TimeChip(label: AppStrings.yearToDate, selected: filter.range == AnalyticsTimeRange.yearToDate, onTap: () => ref.read(analyticsFilterProvider.notifier).setRange(AnalyticsTimeRange.yearToDate)),
                const SizedBox(width: AppSizes.p8),
                _TimeChip(label: filter.range == AnalyticsTimeRange.custom ? AppStrings.customRange : AppStrings.custom, selected: filter.range == AnalyticsTimeRange.custom, onTap: () => _selectCustomRange(context, ref)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A choice-chip styled time range preset.
class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primaryLight,
      labelStyle: AppTextStyles.captionMedium.copyWith(
        color: selected ? AppColors.primary : AppColors.textSecondary,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r6)),
      ),
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.border,
        width: AppSizes.borderWidth,
      ),
      showCheckmark: false,
      onSelected: (_) => onTap(),
    );
  }
}
