/// Sort options for the doctor's assigned patient roster.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/shared/widgets/sort_options_sheet.dart';

enum MyPatientSortOption {
  nameAsc,
  nameDesc,
  dateAddedNewest,
  dateAddedOldest;

  String get displayLabel => switch (this) {
    MyPatientSortOption.nameAsc => 'Name (A → Z)',
    MyPatientSortOption.nameDesc => 'Name (Z → A)',
    MyPatientSortOption.dateAddedNewest => 'Date Added (Newest)',
    MyPatientSortOption.dateAddedOldest => 'Date Added (Oldest)',
  };

  String get buttonLabel => switch (this) {
    MyPatientSortOption.nameAsc => 'Name A→Z',
    MyPatientSortOption.nameDesc => 'Name Z→A',
    MyPatientSortOption.dateAddedNewest => 'Date Added ↓',
    MyPatientSortOption.dateAddedOldest => 'Date Added ↑',
  };

  String get orderByColumn => switch (this) {
    MyPatientSortOption.nameAsc || MyPatientSortOption.nameDesc => 'full_name',
    MyPatientSortOption.dateAddedNewest ||
    MyPatientSortOption.dateAddedOldest => 'created_at',
  };

  bool get isAscending => switch (this) {
    MyPatientSortOption.nameAsc || MyPatientSortOption.dateAddedOldest => true,
    MyPatientSortOption.nameDesc || MyPatientSortOption.dateAddedNewest => false,
  };

  static Future<MyPatientSortOption?> show(
    BuildContext context,
    MyPatientSortOption selected,
  ) {
    return SortOptionsSheet.show<MyPatientSortOption>(
      context: context,
      title: 'Sort Options',
      options: MyPatientSortOption.values
          .map(
            (o) => SortOption(
              value: o,
              label: o.displayLabel,
              buttonLabel: o.buttonLabel,
            ),
          )
          .toList(),
      selected: selected,
    );
  }
}
