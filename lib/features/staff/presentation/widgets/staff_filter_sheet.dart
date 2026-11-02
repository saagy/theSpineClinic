import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/shared/widgets/filter_sort_option.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_account_status.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_list_filter_models.dart';
import 'package:spine_clinic_app/shared/widgets/filter_sheet_frame.dart';
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
    return FilterSheetFrame.show<StaffFilterSelection>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => FilterSheetFrame(
          child: FilterSheetBody(
            onReset: () => update(() {
              filters = const StaffListFilters();
              sort = StaffSortOption.nameAsc;
            }),
            onApply: () => Navigator.of(context).pop((filters: filters, sort: sort)),
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
              const FilterSectionTitle(AppStrings.sortOrder),
              for (final option in StaffSortOption.values)
                FilterSortOption(
                  label: option.displayLabel,
                  selected: sort == option,
                  onTap: () => update(() => sort = option),
                ),
              const SizedBox(height: AppSizes.p20),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _group(String label, List<Widget> choices) => Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.p20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterSectionTitle(label),
        Wrap(spacing: AppSizes.p8, runSpacing: AppSizes.p8, children: choices),
      ],
    ),
  );
  static Widget _chip(String label, bool selected, VoidCallback onTap) =>
      FilterOptionChip(label: label, isSelected: selected, onTap: onTap);
}
