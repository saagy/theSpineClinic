/// Sort options for the receptionist All appointments screen.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/shared/widgets/filter_sort_option.dart';

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
  Widget build(BuildContext context) => Column(children: [
    for (final option in AppointmentSortOption.values)
      FilterSortOption(label: option.displayLabel, selected: selectedSort == option,
        onTap: () => onSortChanged(option)),
  ]);
}
