/// Filter bar widget for the doctor history screen.
///
/// Provides date-range chips, appointment-type dropdown,
/// branch/clinic dropdown, and a clear button.
library;

import 'package:flutter/material.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

/// Renders date-range, type, and branch filters for the doctor history screen.
class HistoryFilterBar extends StatelessWidget {
  /// Creates a [HistoryFilterBar].
  const HistoryFilterBar({
    super.key,
    required this.dateFrom,
    required this.dateTo,
    required this.typeFilter,
    required this.branchFilter,
    required this.onPickDate,
    required this.onTypeChanged,
    required this.onBranchChanged,
    required this.onClear,
  });

  /// Currently selected start date, or null.
  final DateTime? dateFrom;

  /// Currently selected end date, or null.
  final DateTime? dateTo;

  /// Currently selected appointment type, or null for all.
  final AppointmentType? typeFilter;

  /// Currently selected clinic branch, or null for all.
  final ClinicLocation? branchFilter;

  /// Called when the user taps a date chip.
  final void Function(bool isFrom) onPickDate;

  /// Called when the type dropdown changes.
  final void Function(AppointmentType?) onTypeChanged;

  /// Called when the branch dropdown changes.
  final void Function(ClinicLocation?) onBranchChanged;

  /// Called when the user taps the clear button.
  final VoidCallback onClear;

  bool get _hasAnyFilter =>
      dateFrom != null || dateTo != null || typeFilter != null || branchFilter != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildTypeDropdown(context)),
              const SizedBox(width: AppSizes.p8),
              Expanded(child: _buildBranchDropdown(context)),
            ],
          ),
          const SizedBox(height: AppSizes.p8),
          Wrap(
            spacing: AppSizes.p8,
            runSpacing: AppSizes.p8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.calendar_today_rounded, size: 16),
                label: Text(
                  dateFrom != null ? Formatters.formatDateShort(dateFrom!) : AppStrings.fromDate,
                ),
                onPressed: () => onPickDate(true),
                backgroundColor: dateFrom != null ? AppColors.primaryLight : AppColors.surface,
              ),
              ActionChip(
                avatar: const Icon(Icons.calendar_today_rounded, size: 16),
                label: Text(
                  dateTo != null ? Formatters.formatDateShort(dateTo!) : AppStrings.toDate,
                ),
                onPressed: () => onPickDate(false),
                backgroundColor: dateTo != null ? AppColors.primaryLight : AppColors.surface,
              ),
              if (_hasAnyFilter)
                ActionChip(
                  avatar: const Icon(Icons.clear_rounded, size: 16, color: AppColors.error),
                  label: Text(
                    AppStrings.clearFilters,
                    style: AppTextStyles.caption.copyWith(color: AppColors.error),
                  ),
                  onPressed: onClear,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeDropdown(BuildContext context) {
    final typeItems = <DropdownMenuItem<AppointmentType?>>[
      DropdownMenuItem<AppointmentType?>(
        value: null,
        child: Text(AppStrings.allTypes),
      ),
      ...AppointmentType.values.map(
        (type) => DropdownMenuItem<AppointmentType?>(
          value: type,
          child: Text(type.displayLabel),
        ),
      ),
    ];
    return DropdownButtonFormField<AppointmentType?>(
      initialValue: typeFilter,
      decoration: _dropdownDecoration(AppStrings.filterByType),
      items: typeItems,
      onChanged: onTypeChanged,
    );
  }

  Widget _buildBranchDropdown(BuildContext context) {
    return DropdownButtonFormField<ClinicLocation?>(
      initialValue: branchFilter,
      decoration: _dropdownDecoration(AppStrings.filterByBranch),
      items: const [
        DropdownMenuItem<ClinicLocation?>(
          value: null,
          child: Text(AppStrings.allBranches),
        ),
        DropdownMenuItem<ClinicLocation?>(
          value: ClinicLocation.tagamoa,
          child: Text(AppStrings.clinicTagamoa),
        ),
        DropdownMenuItem<ClinicLocation?>(
          value: ClinicLocation.masrElgedida,
          child: Text(AppStrings.clinicMasrElgedida),
        ),
      ],
      onChanged: onBranchChanged,
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.captionMedium.copyWith(color: AppColors.textSecondary),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      isDense: true,
      contentPadding: AppSizes.paddingCell,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r6)),
        borderSide: BorderSide(color: AppColors.border),
      ),
    );
  }
}
