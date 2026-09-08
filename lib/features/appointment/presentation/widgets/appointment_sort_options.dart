/// Sort options for the receptionist All appointments screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Sort options for all-appointments archive.
enum AppointmentSortOption {
  dateDesc,
  dateAsc;

  String get displayLabel => switch (this) {
    AppointmentSortOption.dateDesc => AppStrings.sortDateNewest,
    AppointmentSortOption.dateAsc => AppStrings.sortDateOldest,
  };

  bool get ascending => this == AppointmentSortOption.dateAsc;

  static AppointmentSortOption fromAscending(bool ascending) =>
      ascending ? AppointmentSortOption.dateAsc : AppointmentSortOption.dateDesc;
}

/// Radio list of sort options matching the patient filter sheet style.
class AppointmentFilterSortList extends StatelessWidget {
  const AppointmentFilterSortList({
    super.key,
    required this.selectedSort,
    required this.onSortChanged,
  });

  final AppointmentSortOption selectedSort;
  final ValueChanged<AppointmentSortOption> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: AppointmentSortOption.values.map((s) {
        final isSelected = selectedSort == s;
        return InkWell(
          onTap: () => onSortChanged(s),
          borderRadius: BorderRadius.circular(AppSizes.r6),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSizes.p8,
              horizontal: AppSizes.p4,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? LucideIcons.circle_dot : LucideIcons.circle,
                  size: 16,
                  color: isSelected ? cs.primary : cs.outlineVariant,
                ),
                const SizedBox(width: AppSizes.p10),
                Expanded(
                  child: Text(
                    s.displayLabel,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: cs.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
