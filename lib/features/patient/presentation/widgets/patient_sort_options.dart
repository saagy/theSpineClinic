/// Sort options for the main patient roster screen.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/shared/widgets/sort_options_sheet.dart';

enum PatientSortOption {
  nameAsc,
  nameDesc,
  dateAddedNewest,
  dateAddedOldest,
  nextVisitSoonest,
  nextVisitLatest;

  String get displayLabel => switch (this) {
    PatientSortOption.nameAsc => 'Name (A → Z)',
    PatientSortOption.nameDesc => 'Name (Z → A)',
    PatientSortOption.dateAddedNewest => 'Date Added (Newest)',
    PatientSortOption.dateAddedOldest => 'Date Added (Oldest)',
    PatientSortOption.nextVisitSoonest => 'Next Visit (Soonest)',
    PatientSortOption.nextVisitLatest => 'Next Visit (Latest)',
  };

  String get buttonLabel => switch (this) {
    PatientSortOption.nameAsc => 'Name A→Z',
    PatientSortOption.nameDesc => 'Name Z→A',
    PatientSortOption.dateAddedNewest => 'Date Added ↓',
    PatientSortOption.dateAddedOldest => 'Date Added ↑',
    PatientSortOption.nextVisitSoonest => 'Next Visit ↓',
    PatientSortOption.nextVisitLatest => 'Next Visit ↑',
  };

  (String orderBy, bool ascending) get sortParams => switch (this) {
    PatientSortOption.nameAsc => ('full_name', true),
    PatientSortOption.nameDesc => ('full_name', false),
    PatientSortOption.dateAddedNewest => ('created_at', false),
    PatientSortOption.dateAddedOldest => ('created_at', true),
    PatientSortOption.nextVisitSoonest => ('next_visit_date', true),
    PatientSortOption.nextVisitLatest => ('next_visit_date', false),
  };

  static PatientSortOption fromParams(String orderBy, bool ascending) {
    if (orderBy == 'created_at') {
      return ascending
          ? PatientSortOption.dateAddedOldest
          : PatientSortOption.dateAddedNewest;
    }
    if (orderBy == 'next_visit_date') {
      return ascending
          ? PatientSortOption.nextVisitSoonest
          : PatientSortOption.nextVisitLatest;
    }
    return ascending
        ? PatientSortOption.nameAsc
        : PatientSortOption.nameDesc;
  }

  static Future<PatientSortOption?> show(
    BuildContext context,
    PatientSortOption selected,
  ) {
    return SortOptionsSheet.show<PatientSortOption>(
      context: context,
      title: 'Sort Options',
      options: PatientSortOption.values
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
