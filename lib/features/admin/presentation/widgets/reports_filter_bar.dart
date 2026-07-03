import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/admin/presentation/reports_controller.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

/// Top filter bar widget for the ReportsScreen.
/// Allows selecting the target ClinicLocation and date frame preset.
class ReportsFilterBar extends ConsumerWidget {
  /// Creates a [ReportsFilterBar] instance.
  const ReportsFilterBar({super.key});

  Future<void> _selectCustomDateRange(BuildContext context, WidgetRef ref) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        final ThemeData theme = Theme.of(context);
        final ColorScheme cs = theme.colorScheme;
        return Theme(
          data: theme.copyWith(
            colorScheme: cs.copyWith(
              primary: cs.primary,
              onPrimary: cs.onPrimary,
              surface: cs.surface,
              onSurface: cs.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(reportsFilterStateProvider.notifier).setDateFrame(
            DateFrame.custom,
            start: picked.start,
            end: picked.end.add(const Duration(hours: 23, minutes: 59, seconds: 59)),
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReportsFilter filter = ref.watch(reportsFilterStateProvider);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<ClinicLocation?>(
                  initialValue: filter.clinic,
                  decoration: InputDecoration(
                    labelText: AppStrings.clinic,
                    labelStyle: AppTextStyles.captionMedium.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    isDense: true,
                    contentPadding: AppSizes.paddingCell,
                    border: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text(AppStrings.allClinics),
                    ),
                    DropdownMenuItem(
                      value: ClinicLocation.tagamoa,
                      child: Text(AppStrings.clinicTagamoa),
                    ),
                    DropdownMenuItem(
                      value: ClinicLocation.masrElgedida,
                      child: Text(AppStrings.clinicMasrElgedida),
                    ),
                  ],
                  onChanged: (val) {
                    ref.read(reportsFilterStateProvider.notifier).setClinic(val);
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
                _FilterChipItem(
                  label: AppStrings.today,
                  selected: filter.dateFrame == DateFrame.today,
                  onSelected: () => ref
                      .read(reportsFilterStateProvider.notifier)
                      .setDateFrame(DateFrame.today),
                ),
                const SizedBox(width: AppSizes.p8),
                _FilterChipItem(
                  label: AppStrings.thisWeek,
                  selected: filter.dateFrame == DateFrame.thisWeek,
                  onSelected: () => ref
                      .read(reportsFilterStateProvider.notifier)
                      .setDateFrame(DateFrame.thisWeek),
                ),
                const SizedBox(width: AppSizes.p8),
                _FilterChipItem(
                  label: AppStrings.thisMonth,
                  selected: filter.dateFrame == DateFrame.thisMonth,
                  onSelected: () => ref
                      .read(reportsFilterStateProvider.notifier)
                      .setDateFrame(DateFrame.thisMonth),
                ),
                const SizedBox(width: AppSizes.p8),
                _FilterChipItem(
                  label: filter.dateFrame == DateFrame.custom
                      ? AppStrings.customRange
                      : AppStrings.custom,
                  selected: filter.dateFrame == DateFrame.custom,
                  onSelected: () => _selectCustomDateRange(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: AppTextStyles.captionMedium.copyWith(
        color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r6)),
      ),
      side: BorderSide(
        color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline,
        width: AppSizes.borderWidth,
      ),
      showCheckmark: false,
      onSelected: (_) => onSelected(),
    );
  }
}
