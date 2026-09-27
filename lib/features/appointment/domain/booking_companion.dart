import 'appointment_type.dart';

/// Optional assessment booked in the same transaction as the main treatment.
class BookingCompanion {
  const BookingCompanion({
    required this.type,
    required this.slots,
    required this.doctorIds,
  });
  final AppointmentType type;
  final List<DateTime> slots;
  final List<String> doctorIds;
}
