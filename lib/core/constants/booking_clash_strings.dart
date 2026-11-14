/// Text for the booking warning shown when the patient already has a visit
/// on a chosen day.
final class BookingClashStrings {
  const BookingClashStrings();

  final String sameTime = 'This patient is already booked at this time.';
  final String sameDay = 'This patient already has a visit that day.';
  String severalDates(int count) =>
      'This patient already has visits on $count of these dates.';

  /// `Sat, Nov 21 at 10:00 AM · PT Session`, with the branch when known.
  String visitLine(String date, String time, String type, String? branch) =>
      [('$date at $time'), type, ?branch].join(' · ');
  String sameTimeTag(String line) => 'Same time: $line';
  String more(int count) => 'and $count more';
  final String note = 'You can still book it. Check it isn\'t a duplicate.';
}
