/// Date-grouped list builder and action helpers for the "All" appointments tab.
///
/// Extracted to keep [ReceptionistAllTab] under 200 lines.
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_filter_content.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/sort_options_sheet.dart';

/// Shows the sort by date bottom sheet for the All tab.
Future<void> showAllSortSheet(BuildContext context, WidgetRef ref) async {
  final n = ref.read(allAppointmentsProvider.notifier);
  final currentAsc = n.isAscending;
  final selected = await SortOptionsSheet.show<String>(
    context: context,
    title: 'Sort by Date',
    options: const [
      SortOption(
        value: 'newest',
        label: 'Date (Newest)',
        buttonLabel: 'Date \u2193',
      ),
      SortOption(
        value: 'oldest',
        label: 'Date (Oldest)',
        buttonLabel: 'Date \u2191',
      ),
    ],
    selected: currentAsc ? 'oldest' : 'newest',
  );
  if (selected != null) n.setSortAscending(selected == 'oldest');
}

/// Opens the advanced filter bottom sheet for the All tab.
void openAllFilterSheet(BuildContext context) {
  AppBottomSheet.show(
    context: context,
    title: AppStrings.advancedFilters,
    initialChildSize: AppSizes.sheetMax,
    builder: (ctx, scrollCtrl) =>
        AppointmentFilterContent(scrollController: scrollCtrl),
  );
}

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