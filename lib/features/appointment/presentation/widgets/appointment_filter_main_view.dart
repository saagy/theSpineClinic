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

part 'appointment_filter_chrome.dart';

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
    this.appointmentFiltersBuilder,
    this.showAppointmentFilters = true,
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
  final WidgetBuilder? appointmentFiltersBuilder;
  final bool showAppointmentFilters;

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
                if (showAppointmentFilters) ...[
                  const SizedBox(height: AppSizes.p20),
                  if (appointmentFiltersBuilder != null)
                    appointmentFiltersBuilder!(context)
                  else
                    AppointmentFilterChipsSection(
                      selectedClinic: selectedClinic,
                      selectedStatus: selectedStatus,
                      selectedType: selectedType,
                      canFilterClinic: canFilterClinic,
                      onClinicChanged: onClinicChanged,
                      onStatusChanged: onStatusChanged,
                      onTypeChanged: onTypeChanged,
                    ),
                ],
                const SizedBox(height: AppSizes.p20),
                _buildSectionTitle(cs, AppStrings.sortOrder),
                AppointmentFilterSortList(selectedSort: selectedSort, onSortChanged: onSortChanged),
                const SizedBox(height: AppSizes.p20),
              ],
            ),
          ),
        ),
        _buildFooter(cs),
      ],
    );
  }
}
