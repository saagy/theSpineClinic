enum PatientNotesSortOption {
  dateNewest,
  dateOldest;

  String get displayLabel => switch (this) {
    PatientNotesSortOption.dateNewest => 'Date (Newest)',
    PatientNotesSortOption.dateOldest => 'Date (Oldest)',
  };

  String get buttonLabel => switch (this) {
    PatientNotesSortOption.dateNewest => 'Date ↓',
    PatientNotesSortOption.dateOldest => 'Date ↑',
  };
}
