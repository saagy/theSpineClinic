enum PatientAppointmentSortOption {
  dateNewest,
  dateOldest;

  String get displayLabel => switch (this) {
    PatientAppointmentSortOption.dateNewest => 'Date (Newest)',
    PatientAppointmentSortOption.dateOldest => 'Date (Oldest)',
  };

  String get buttonLabel => switch (this) {
    PatientAppointmentSortOption.dateNewest => 'Date ↓',
    PatientAppointmentSortOption.dateOldest => 'Date ↑',
  };
}
