/// Text for staff reference details: national ID, dates and working hours.
final class StaffDetailsStrings {
  const StaffDetailsStrings();

  final String section = 'Employment details';
  final String sectionHelp = 'For the staff record only.';
  final String nationalId = 'National ID';
  final String nationalIdHint = '14 digits';
  final String nationalIdInvalid = 'Enter the 14-digit national ID.';
  final String nationalIdTaken = 'Another staff member already has this national ID.';
  final String birthDate = 'Date of birth';
  final String birthDateFuture = 'Date of birth cannot be in the future.';
  final String hireDate = 'Hire date';
  final String hireBeforeBirth = 'Hire date must be after the date of birth.';
  final String chooseDate = 'Choose date';
  final String chooseTime = 'Choose time';
  final String clear = 'Clear';
  final String invalid = 'Check the employment details and try again.';
  final String loadFailed = 'The employment details could not be loaded.';

  /// Short weekday names by ISO weekday, Monday = 1.
  String weekday(int day) => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1];
  String weekdayLong(int day) =>
      const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][day - 1];

  Map<String, String> get errorKeys => {
    'staff_national_id_taken': nationalIdTaken,
    'staff_details_invalid': invalid,
  };
}
