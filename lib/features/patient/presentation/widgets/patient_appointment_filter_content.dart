import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_appointments_notifier.dart';
import 'package:spine_clinic_app/shared/widgets/filter_chip.dart';
import 'package:spine_clinic_app/shared/widgets/section_header.dart';
import 'package:spine_clinic_app/shared/widgets/unified_filter_sheet.dart';

class PatientAppointmentFilterContent extends ConsumerStatefulWidget {
  const PatientAppointmentFilterContent({
    super.key,
    required this.patientId,
    this.scrollController,
  });

  final String patientId;
  final ScrollController? scrollController;

  @override
  ConsumerState<PatientAppointmentFilterContent> createState() =>
      _PatientAppointmentFilterContentState();
}

class _PatientAppointmentFilterContentState
    extends ConsumerState<PatientAppointmentFilterContent> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  Set<AppointmentStatus> _statusFilter = {};
  Set<AppointmentType> _typeFilter = {};
  String? _selectedDoctorId;
  bool? _usePackageFilter;

  @override
  void initState() {
    super.initState();
    final state = ref.read(patientAppointmentsProvider(widget.patientId));
    _dateFrom = state.dateFrom;
    _dateTo = state.dateTo;
    _statusFilter = Set.from(state.statusFilter ?? {});
    _typeFilter = Set.from(state.typeFilter ?? {});
    _selectedDoctorId = state.doctorId;
    _usePackageFilter = state.usePackageFilter;
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateFrom != null && _dateTo != null
          ? DateTimeRange(
              start: _dateFrom!,
              end: _dateTo!.subtract(const Duration(days: 1)),
            )
          : null,
    );
    if (picked != null) {
      setState(() {
        _dateFrom = picked.start;
        _dateTo = picked.end.add(const Duration(days: 1));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String dateRangeText = _dateFrom != null && _dateTo != null
        ? '${Formatters.formatDateShort(_dateFrom!)} - ${Formatters.formatDateShort(_dateTo!.subtract(const Duration(days: 1)))}'
        : (_dateFrom != null
            ? 'From ${Formatters.formatDateShort(_dateFrom!)}'
            : (_dateTo != null
                ? 'Until ${Formatters.formatDateShort(_dateTo!.subtract(const Duration(days: 1)))}'
                : 'Select Date Range'));

    return UnifiedFilterSheet(
      scrollController: widget.scrollController,
      showBranchFilter: false,
      showDoctorFilter: true,
      initialDoctorId: _selectedDoctorId,
      initialClinic: null,
      onReset: () {
        setState(() {
          _dateFrom = null;
          _dateTo = null;
          _statusFilter = {};
          _typeFilter = {};
          _selectedDoctorId = null;
          _usePackageFilter = null;
        });
      },
      onApplied: (doctorId, _) {
        final notifier = ref.read(patientAppointmentsProvider(widget.patientId).notifier);
        notifier.setDoctorFilter(doctorId);
        notifier.setDateRange(_dateFrom, _dateTo);
        notifier.setStatusFilter(_statusFilter.isEmpty ? null : _statusFilter);
        notifier.setTypeFilter(_typeFilter.isEmpty ? null : _typeFilter);
        notifier.setUsePackageFilter(_usePackageFilter);
        Navigator.of(context).pop();
      },
      additionalFilters: [
        const SectionHeader(title: 'Date Range'),
        const SizedBox(height: AppSizes.p8),
        Container(
          decoration: BoxDecoration(
            color: (_dateFrom != null || _dateTo != null) ? AppColors.primaryLight : AppColors.surface,
            borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
            border: Border.all(
              color: (_dateFrom != null || _dateTo != null) ? AppColors.primary : AppColors.border,
              width: AppSizes.borderWidth,
            ),
          ),
          child: InkWell(
            onTap: _pickDateRange,
            borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p12),
              child: Row(
                children: [
                  Icon(
                    Icons.date_range_rounded,
                    size: AppSizes.iconDefault,
                    color: (_dateFrom != null || _dateTo != null) ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSizes.p12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date Range', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: AppSizes.p2),
                        Text(
                          dateRangeText,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: (_dateFrom != null || _dateTo != null) ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.p16),
        const SectionHeader(title: 'Appointment Status'),
        const SizedBox(height: AppSizes.p8),
        Wrap(
          spacing: AppSizes.p8,
          runSpacing: AppSizes.p8,
          children: AppointmentStatus.values
              .where((status) =>
                  status != AppointmentStatus.completed &&
                  status != AppointmentStatus.noShow)
              .map((status) {
            final isSelected = _statusFilter.contains(status);
            return AppFilterChip(
              label: status.displayLabel,
              isActive: isSelected,
              onTap: () => setState(() {
                if (isSelected) {
                  _statusFilter.remove(status);
                } else {
                  _statusFilter.add(status);
                }
              }),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSizes.p16),
        const SectionHeader(title: 'Appointment Type'),
        const SizedBox(height: AppSizes.p8),
        Wrap(
          spacing: AppSizes.p8,
          runSpacing: AppSizes.p8,
          children: AppointmentType.values.map((type) {
            final isSelected = _typeFilter.contains(type);
            return AppFilterChip(
              label: type.displayLabel,
              isActive: isSelected,
              onTap: () => setState(() {
                if (isSelected) {
                  _typeFilter.remove(type);
                } else {
                  _typeFilter.add(type);
                }
              }),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSizes.p16),
        const SectionHeader(title: 'Package Usage'),
        const SizedBox(height: AppSizes.p8),
        Wrap(
          spacing: AppSizes.p8,
          runSpacing: AppSizes.p8,
          children: [
            AppFilterChip(
              label: AppStrings.packageFilterAll,
              isActive: _usePackageFilter == null,
              onTap: () => setState(() => _usePackageFilter = null),
            ),
            AppFilterChip(
              label: AppStrings.packageFilterPackage,
              isActive: _usePackageFilter == true,
              onTap: () => setState(() => _usePackageFilter = true),
            ),
            AppFilterChip(
              label: AppStrings.packageFilterNoPackage,
              isActive: _usePackageFilter == false,
              onTap: () => setState(() => _usePackageFilter = false),
            ),
          ],
        ),
      ],
    );
  }
}
