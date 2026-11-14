/// Text for staff branches, weekly schedules, the staff profile and the
/// branch-aware booking hints.
final class StaffScheduleStrings {
  const StaffScheduleStrings();

  // Editor.
  final String section = 'Branches and schedule';
  final String sectionHelp =
      'Booking lists show a branch\'s staff first. The schedule only drives booking warnings; '
      'it never blocks a booking.';
  final String branches = 'Branches';
  final String branchesHelp = 'Where this person works. Choose at least one for receptionists.';
  final String weeklySchedule = 'Weekly schedule';
  final String noBranchesYet = 'Choose a branch first to add working hours.';
  final String off = 'Off';
  final String addShift = 'Add hours';
  final String editShift = 'Edit hours';
  final String branch = 'Branch';
  final String startsAt = 'Starts';
  final String endsAt = 'Ends';
  final String save = 'Save';
  final String cancel = 'Cancel';
  final String remove = 'Remove';
  final String endAfterStart = 'The end time must be after the start time.';
  final String overlaps = 'These hours overlap other hours on the same day.';
  final String pickTimes = 'Choose a start and an end time.';
  final String receptionistNeedsBranch = 'Choose at least one branch for a receptionist.';
  final String removeBranchTitle = 'Remove branch?';
  final String keepBranch = 'Keep branch';
  final String removeBranchConfirm = 'Remove';
  String removeBranchMessage(String name, Map<String, int> counts) {
    final String places = counts.entries
        .map((e) => '${e.value} upcoming ${e.value == 1 ? 'visit' : 'visits'} at ${e.key}')
        .join(' and ');
    return '$name still has $places. They stay booked; reassign them from the schedule '
        'if this doctor will no longer be there.';
  }

  String shiftLabel(String branch, String start, String end) => '$branch · $start – $end';
  String hours(String start, String end) => '$start – $end';
  String removeShiftLabel(String label) => 'Remove $label';

  // Profile.
  final String profileTitle = 'Staff profile';
  final String contact = 'Contact';
  final String email = 'Email';
  final String phone = 'Phone';
  final String noBranches = 'No branches assigned';
  final String noSchedule = 'No working hours recorded';
  final String noEmploymentDetails = 'No employment details recorded';
  final String employmentHidden = 'Employment details are shown for colleagues at your branches.';
  final String show = 'Show';
  final String hide = 'Hide';
  final String showNationalId = 'Show national ID';
  final String hideNationalId = 'Hide national ID';
  final String inactive = 'Inactive';
  final String managesPayments = 'Manages payments';
  final String edit = 'Edit';
  final String notFound = 'This staff member could not be found.';
  String maskedId(String lastFour) => '•••• •••• ••$lastFour';
  String age(int years) => '$years yrs';
  String tenure(int years, int months) {
    if (years == 0 && months == 0) return 'Started this month';
    final List<String> parts = [
      if (years > 0) '$years ${years == 1 ? 'year' : 'years'}',
      if (months > 0) '$months ${months == 1 ? 'month' : 'months'}',
    ];
    return parts.join(' ');
  }

  String withDetail(String value, String detail) => '$value ($detail)';
  String updatedBy(String name, String when) => 'Updated by $name on $when';
  String updatedOn(String when) => 'Updated on $when';

  // Pickers and booking.
  String atBranch(String branch) => 'At $branch';
  final String otherDoctors = 'Other doctors';
  final String showOtherBranches = 'Show doctors from other branches';
  final String hideOtherBranches = 'Hide doctors from other branches';
  String notScheduledOn(String name, String day) => '$name is not scheduled to work on $day.';
  String worksElsewhereOn(String name, String day, String branches) =>
      '$name works at $branches on $day.';
  String outsideHours(String name, String hours) => '$name usually works $hours here.';
  final String warningNote = 'You can still book.';
  String registeredAt(String branch) => 'Registered at $branch';
  final String visitBranch = 'Branch';
  final String branchLocked = 'The branch can no longer be changed after check-in.';

  Map<String, String> get errorKeys => {
    'staff_shifts_overlap': overlaps,
    'staff_schedule_invalid': 'Check the branches and working hours and try again.',
    'branch_not_assigned': 'Choose one of your own branches.',
    'appointment_branch_locked': branchLocked,
  };
}
