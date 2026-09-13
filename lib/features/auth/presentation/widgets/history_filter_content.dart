import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/history_sort_option.dart';
import 'package:spine_clinic_app/features/auth/presentation/doctor_history_provider.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_filter_sheet.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_sort_options.dart';

Future<void> showHistoryFilters(BuildContext context, WidgetRef ref) async {
  final initial = ref.read(doctorHistoryProvider);
  HistorySortOption sort = initial.sortOption;
  final result = await AppointmentFilterSheet.show(
    context: context,
    dateFrom: initial.dateFrom,
    dateTo: initial.dateTo?.add(const Duration(days: 1)),
    doctorId: null,
    clinic: initial.branchFilter,
    status: null,
    type: initial.typeFilter,
    sort: AppointmentSortOption.dateDesc,
    canFilterDoctor: false,
    canFilterClinic: true,
    showStatusFilter: false,
    onResetAdditional: () => sort = HistorySortOption.dateNewest,
    sortOptionsBuilder: (_) => StatefulBuilder(
      builder: (context, update) => Column(
        children: [
          for (final option in HistorySortOption.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              minTileHeight: AppSizes.tappableMin,
              leading: Icon(
                sort == option ? Icons.radio_button_checked : Icons.radio_button_off,
                size: AppSizes.iconDefault,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(option.displayLabel, style: AppTextStyles.bodyMedium),
              onTap: () => update(() => sort = option),
            ),
        ],
      ),
    ),
  );
  if (result == null || !context.mounted) return;
  final notifier = ref.read(doctorHistoryProvider.notifier);
  notifier.setDateRange(result.dateFrom, result.dateTo?.subtract(const Duration(days: 1)));
  notifier.setTypeFilter(result.type);
  notifier.setBranchFilter(result.clinic);
  notifier.setSortOption(sort);
}
