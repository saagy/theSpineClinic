enum HistorySortOption {
  dateNewest,
  dateOldest,
  patientNameAsc,
  patientNameDesc;

  String get displayLabel => switch (this) {
    HistorySortOption.dateNewest => 'Date (Newest)',
    HistorySortOption.dateOldest => 'Date (Oldest)',
    HistorySortOption.patientNameAsc => 'Patient Name (A → Z)',
    HistorySortOption.patientNameDesc => 'Patient Name (Z → A)',
  };

  String get buttonLabel => switch (this) {
    HistorySortOption.dateNewest => 'Date ↓',
    HistorySortOption.dateOldest => 'Date ↑',
    HistorySortOption.patientNameAsc => 'Name A→Z',
    HistorySortOption.patientNameDesc => 'Name Z→A',
  };
}
