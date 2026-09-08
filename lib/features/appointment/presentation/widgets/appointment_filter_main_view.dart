/// Main page of the appointment filter sheet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_filter_chips_section.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_filter_date_section.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_filter_doctor_tile.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_sort_options.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

/// Main view displaying all appointment filter sections and sort radio rows.
class AppointmentFilterMainView extends StatelessWidget {
  const AppointmentFilterMainView({
    super.key,
    required this.selectedDateFrom,
    required this.selectedDateTo,
    required this.selectedDoctorId,
    required this.selectedClinic,
    required this.selectedStatus,
    required this.selectedType,
    required this.selectedSort,
    required this.canFilterDoctor,
    required this.canFilterClinic,
    required this.doctors,
    required this.onDateRangeChanged,
    required this.onOpenDoctorPicker,
    required this.onClinicChanged,
    required this.onStatusChanged,
    required this.onTypeChanged,
    required this.onSortChanged,
    required this.onReset,
    required this.onApply,
  });

  final DateTime? selectedDateFrom;
  final DateTime? selectedDateTo;
  final String? selectedDoctorId;
  final ClinicLocation? selectedClinic;
  final AppointmentStatus? selectedStatus;
  final AppointmentType? selectedType;
  final AppointmentSortOption selectedSort;
  final bool canFilterDoctor;
  final bool canFilterClinic;
  final List<Staff> doctors;
  final void Function(DateTime? from, DateTime? to) onDateRangeChanged;
  final VoidCallback onOpenDoctorPicker;
  final ValueChanged<ClinicLocation?> onClinicChanged;
  final ValueChanged<AppointmentStatus?> onStatusChanged;
  final ValueChanged<AppointmentType?> onTypeChanged;
  final ValueChanged<AppointmentSortOption> onSortChanged;
  final VoidCallback onReset;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context, cs),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(cs, AppStrings.dateRange),
                AppointmentFilterDateSection(
                  dateFrom: selectedDateFrom,
                  dateTo: selectedDateTo,
                  onDateRangeChanged: onDateRangeChanged,
                ),
                if (canFilterDoctor) ...[
                  const SizedBox(height: AppSizes.p20),
                  _buildSectionTitle(cs, AppStrings.assignedDoctors),
                  AppointmentFilterDoctorTile(
                    selectedDoctorId: selectedDoctorId,
                    doctors: doctors,
                    onTap: onOpenDoctorPicker,
                  ),
                ],
                const SizedBox(height: AppSizes.p20),
                AppointmentFilterChipsSection(
                  selectedClinic: selectedClinic,
                  selectedStatus: selectedStatus,
                  selectedType: selectedType,
                  canFilterClinic: canFilterClinic,
                  onClinicChanged: onClinicChanged,
                  onStatusChanged: onStatusChanged,
                  onTypeChanged: onTypeChanged,
                ),
                const SizedBox(height: AppSizes.p20),
                _buildSectionTitle(cs, AppStrings.sortOrder),
                AppointmentFilterSortList(
                  selectedSort: selectedSort,
                  onSortChanged: onSortChanged,
                ),
                const SizedBox(height: AppSizes.p20),
              ],
            ),
          ),
        ),
        _buildFooter(cs),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p20,
        AppSizes.p16,
        AppSizes.p12,
        AppSizes.p8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppStrings.filtersButton,
            style: AppTextStyles.headingMedium.copyWith(color: cs.onSurface),
          ),
          Row(
            children: [
              TextButton(
                onPressed: onReset,
                child: Text(
                  AppStrings.resetFilters,
                  style: AppTextStyles.bodyBold.copyWith(color: cs.primary),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
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

  Widget _buildFooter(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant,
            width: AppSizes.borderWidth,
          ),
        ),
      ),
      child: FilledButton(
        onPressed: onApply,
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          minimumSize: const Size.fromHeight(44.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.r8),
          ),
        ),
        child: Text(AppStrings.applyFilters, style: AppTextStyles.bodyBold),
      ),
    );
  }
}
