import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_account_status.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_list_filter_models.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_filter_sheet.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_sort_options.dart';
import 'package:spine_clinic_app/shared/widgets/filter_option_chip.dart';

typedef StaffFilterSelection = ({StaffListFilters filters, StaffSortOption sort});

abstract final class StaffFilterSheet {
  static Future<StaffFilterSelection?> show({
    required BuildContext context,
    required StaffListFilters initialFilters,
    required StaffSortOption initialSort,
  }) async {
    StaffListFilters filters = initialFilters;
    StaffSortOption sort = initialSort;
    final result = await AppointmentFilterSheet.show(
      context: context,
      dateFrom: null,
      dateTo: null,
      doctorId: null,
      clinic: null,
      status: null,
      type: null,
      sort: AppointmentSortOption.dateDesc,
      canFilterDoctor: false,
      canFilterClinic: false,
      showDateFilter: false,
      onResetAdditional: () {
        filters = filters.copyWith(role: () => null, status: () => null, branch: () => null);
        sort = StaffSortOption.nameAsc;
      },
      appointmentFiltersBuilder: (_) => StatefulBuilder(
        builder: (context, update) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _group(AppStrings.filterByRole, [
              _chip(
                AppStrings.allRoles,
                filters.role == null,
                () => update(() => filters = filters.copyWith(role: () => null)),
              ),
              for (final role in UserRole.values)
                _chip(
                  switch (role) {
                    UserRole.superAdmin => AppStrings.superAdmin,
                    UserRole.doctor => AppStrings.doctor,
                    UserRole.receptionist => AppStrings.receptionist,
                  },
                  filters.role == role,
                  () => update(() => filters = filters.copyWith(role: () => role)),
                ),
            ]),
            _group(AppStrings.filterByStatus, [
              _chip(
                AppStrings.allStatuses,
                filters.status == null,
                () => update(() => filters = filters.copyWith(status: () => null)),
              ),
              for (final status in StaffAccountStatus.values.where(
                (s) => s != StaffAccountStatus.pending,
              ))
                _chip(
                  status.label,
                  filters.status == status,
                  () => update(() => filters = filters.copyWith(status: () => status)),
                ),
            ]),
            _group(AppStrings.filterByBranch, [
              _chip(
                AppStrings.allBranches,
                filters.branch == null,
                () => update(() => filters = filters.copyWith(branch: () => null)),
              ),
              for (final branch in ClinicLocation.values)
                _chip(
                  branch.displayLabel,
                  filters.branch == branch,
                  () => update(() => filters = filters.copyWith(branch: () => branch)),
                ),
            ]),
          ],
        ),
      ),
      sortOptionsBuilder: (_) => StatefulBuilder(
        builder: (context, update) => Column(
          children: [
            for (final option in StaffSortOption.values)
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
    return result == null ? null : (filters: filters, sort: sort);
  }

  static Widget _group(String label, List<Widget> choices) => Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.p20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.captionBold),
        const SizedBox(height: AppSizes.p8),
        Wrap(spacing: AppSizes.p8, runSpacing: AppSizes.p8, children: choices),
      ],
    ),
  );
  static Widget _chip(String label, bool selected, VoidCallback onTap) =>
      FilterOptionChip(label: label, isSelected: selected, onTap: onTap);
}
