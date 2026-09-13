import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';

/// Intersects the text query with explicitly selected appointment types.
Set<AppointmentType>? matchingAppointmentTypes(String query, Set<AppointmentType>? selected) {
  if (query.isEmpty) return selected;
  return AppointmentType.values
      .where(
        (type) =>
            type.displayLabel.toLowerCase().contains(query.toLowerCase()) &&
            (selected == null || selected.isEmpty || selected.contains(type)),
      )
      .toSet();
}
