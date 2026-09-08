/// Status, type, and branch filter chips for appointment filter sheet.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

/// Renders clinic, status, and type chip groups.
class AppointmentFilterChipsSection extends StatelessWidget {
  const AppointmentFilterChipsSection({
    super.key,
    required this.selectedClinic,
    required this.selectedStatus,
    required this.selectedType,
    required this.canFilterClinic,
    required this.onClinicChanged,
    required this.onStatusChanged,
    required this.onTypeChanged,
  });

  final ClinicLocation? selectedClinic;
  final AppointmentStatus? selectedStatus;
  final AppointmentType? selectedType;
  final bool canFilterClinic;
  final ValueChanged<ClinicLocation?> onClinicChanged;
  final ValueChanged<AppointmentStatus?> onStatusChanged;
  final ValueChanged<AppointmentType?> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canFilterClinic) ...[
          _buildSectionTitle(cs, AppStrings.clinic),
          _buildClinicOptions(cs),
          const SizedBox(height: AppSizes.p20),
        ],
        _buildSectionTitle(cs, AppStrings.status),
        _buildStatusOptions(cs),
        const SizedBox(height: AppSizes.p20),
        _buildSectionTitle(cs, AppStrings.type),
        _buildTypeOptions(cs),
      ],
    );
  }

  Widget _buildSectionTitle(ColorScheme cs, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.p8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.captionBold.copyWith(
          color: cs.onSurfaceVariant,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildClinicOptions(ColorScheme cs) {
    final clinics = <ClinicLocation?>[
      null,
      ClinicLocation.tagamoa,
      ClinicLocation.masrElgedida,
    ];
    return Wrap(
      spacing: AppSizes.p8,
      runSpacing: AppSizes.p8,
      children: clinics.map((c) {
        final isSelected = selectedClinic == c;
        final label = c == null ? AppStrings.filterAllBranches : c.displayLabel;
        return _buildChip(
          cs: cs,
          label: label,
          isSelected: isSelected,
          onTap: () => onClinicChanged(c),
        );
      }).toList(),
    );
  }

  Widget _buildStatusOptions(ColorScheme cs) {
    final statuses = <AppointmentStatus?>[
      null,
      AppointmentStatus.scheduled,
      AppointmentStatus.checkedIn,
      AppointmentStatus.cancelled,
    ];
    return Wrap(
      spacing: AppSizes.p8,
      runSpacing: AppSizes.p8,
      children: statuses.map((s) {
        final isSelected = selectedStatus == s;
        final label = s == null ? AppStrings.all : s.displayLabel;
        return _buildChip(
          cs: cs,
          label: label,
          isSelected: isSelected,
          onTap: () => onStatusChanged(s),
        );
      }).toList(),
    );
  }

  Widget _buildTypeOptions(ColorScheme cs) {
    final types = <AppointmentType?>[
      null,
      AppointmentType.normalPtSession,
      AppointmentType.spinalTractionSession,
      AppointmentType.initialAssessment,
      AppointmentType.reassessment,
    ];
    return Wrap(
      spacing: AppSizes.p8,
      runSpacing: AppSizes.p8,
      children: types.map((t) {
        final isSelected = selectedType == t;
        final label = t == null ? AppStrings.all : t.displayLabel;
        return _buildChip(
          cs: cs,
          label: label,
          isSelected: isSelected,
          onTap: () => onTypeChanged(t),
        );
      }).toList(),
    );
  }

  Widget _buildChip({
    required ColorScheme cs,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.r8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p12,
          vertical: AppSizes.p8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primaryContainer
              : cs.surfaceContainerHighest.withAlpha(120),
          borderRadius: BorderRadius.circular(AppSizes.r8),
          border: Border.all(
            color: isSelected
                ? cs.primary
                : cs.outlineVariant.withAlpha(100),
            width: AppSizes.borderWidth,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.captionBold.copyWith(
            color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
          ),
        ),
      ),
    );
  }
}
