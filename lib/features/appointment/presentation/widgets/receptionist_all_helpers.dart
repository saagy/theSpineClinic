/// Date-grouped list builder for the "All" appointments tab.
///
/// Extracted to keep [ReceptionistAllTab] under 200 lines.
///
/// Rule 1 — under 200 lines.
library;

import 'package:intl/intl.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';

/// Builds a date-grouped list from raw appointment items.
List<AllListItem> buildDateGroupedList(List<AppointmentWithPatient> items) {
  final result = <AllListItem>[];
  String? last;
  for (final item in items) {
    final d = item.appointment.scheduledAt.toLocal();
    final h = _header(d);
    if (h != last) {
      result.add(AllHeaderItem(h));
      last = h;
    }
    result.add(AllApptItem(item));
  }
  return result;
}

String _header(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final comp = DateTime(d.year, d.month, d.day);
  final diff = today.difference(comp).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff == -1) return 'Tomorrow';
  return DateFormat('EEEE, MMM d').format(d);
}

sealed class AllListItem {}

class AllHeaderItem extends AllListItem {
  AllHeaderItem(this.title);
  final String title;
}

class AllApptItem extends AllListItem {
  AllApptItem(this.item);
  final AppointmentWithPatient item;
}
