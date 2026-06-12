/// Filter bar widget for the all-appointments management screen.
///
/// Provides patient search, date-range chips, doctor/branch/status dropdowns,
/// and a clear button. All filters are combinable.
library;

import 'package:flutter/material.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/shared/widgets/app_search_bar.dart';

/// Renders all filter controls for the all-appointments screen.
class AllAppointmentsFilterBar extends StatelessWidget {
  /// Creates an [AllAppointmentsFilterBar].
  const AllAppointmentsFilterBar({
    super.key,
    required this.dateFrom,
    required this.dateTo,
    required this.selectedDoctorId,
    required this.branchFilter,
    required this.statusFilter,
    required this.doctors,
    required this.onSearchChanged,
    required this.onPickDate,
    required this.onDoctorChanged,
    required this.onBranchChanged,
    required this.onStatusChanged,
    required this.onClear,
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? selectedDoctorId;
  final ClinicLocation? branchFilter;
  final AppointmentStatus? statusFilter;
  final List<Staff> doctors;
  final ValueChanged<String> onSearchChanged;
  final void Function(bool isFrom) onPickDate;
  final ValueChanged<String?> onDoctorChanged;
  final ValueChanged<ClinicLocation?> onBranchChanged;
  final ValueChanged<AppointmentStatus?> onStatusChanged;
  final VoidCallback onClear;

  bool get _hasAnyFilter =>
      dateFrom != null || dateTo != null || branchFilter != null || statusFilter != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p12, AppSizes.p16, AppSizes.p4),
      child: Column(
        children: [
          AppSearchBar(
            hintText: AppStrings.searchByPatientNameHint,
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: AppSizes.p8),
          Wrap(
            spacing: AppSizes.p8,
            runSpacing: AppSizes.p8,
            children: [
              _DateChip(
                label: dateFrom != null ? Formatters.formatDateShort(dateFrom!) : AppStrings.fromDate,
                isActive: dateFrom != null,
                onTap: () => onPickDate(true),
              ),
              _DateChip(
                label: dateTo != null ? Formatters.formatDateShort(dateTo!) : AppStrings.toDate,
                isActive: dateTo != null,
                onTap: () => onPickDate(false),
              ),
              if (_hasAnyFilter)
                ActionChip(
                  avatar: const Icon(Icons.clear_rounded, size: 16, color: AppColors.error),
                  label: Text(AppStrings.clearFilters,
                      style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                  onPressed: onClear,
                ),
            ],
          ),
          const SizedBox(height: AppSizes.p8),
          Row(
            children: [
              Expanded(child: _buildDoctorDropdown()),
              const SizedBox(width: AppSizes.p8),
              Expanded(child: _buildBranchDropdown()),
            ],
          ),
          const SizedBox(height: AppSizes.p8),
          Row(
            children: [
              Expanded(child: _buildStatusDropdown()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorDropdown() {
    final List<DropdownMenuItem<String?>> items = [
      DropdownMenuItem<String?>(value: null, child: Text(AppStrings.allDoctorsAppts)),
      ...doctors.map((d) => DropdownMenuItem<String?>(
            value: d.id,
            child: Text(d.fullName, maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
    ];
    return DropdownButtonFormField<String?>(
      initialValue: selectedDoctorId,
      decoration: _dropdownDecoration(AppStrings.filterByDoctor),
      hint: Text(AppStrings.allDoctorsAppts,
          style: AppTextStyles.captionMedium.copyWith(color: AppColors.textPrimary)),
      items: items,
      onChanged: onDoctorChanged,
    );
  }

  Widget _buildBranchDropdown() {
    return DropdownButtonFormField<ClinicLocation?>(
      initialValue: branchFilter,
      decoration: _dropdownDecoration(AppStrings.filterByBranch),
      items: const [
        DropdownMenuItem<ClinicLocation?>(value: null, child: Text(AppStrings.allBranches)),
        DropdownMenuItem<ClinicLocation?>(
            value: ClinicLocation.tagamoa, child: Text(AppStrings.clinicTagamoa)),
        DropdownMenuItem<ClinicLocation?>(
            value: ClinicLocation.masrElgedida, child: Text(AppStrings.clinicMasrElgedida)),
      ],
      onChanged: onBranchChanged,
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<AppointmentStatus?>(
      initialValue: statusFilter,
      decoration: _dropdownDecoration(AppStrings.filterByStatus),
      items: [
        DropdownMenuItem<AppointmentStatus?>(value: null, child: Text(AppStrings.allStatuses)),
        ...AppointmentStatus.values.map(
          (s) => DropdownMenuItem<AppointmentStatus?>(value: s, child: Text(s.displayLabel)),
        ),
      ],
      onChanged: onStatusChanged,
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

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label, required this.isActive, required this.onTap});
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.calendar_today_rounded, size: 16),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: isActive ? AppColors.primaryLight : AppColors.surface,
    );
  }
}
