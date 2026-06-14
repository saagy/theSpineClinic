import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/shared/widgets/filter_chip.dart';
import 'package:spine_clinic_app/shared/widgets/section_header.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/unified_filter_sheet.dart';

/// Renders the appointment-specific filters and hooks into the unified filter sheet.
class AppointmentFilterContent extends ConsumerStatefulWidget {
  /// Creates an [AppointmentFilterContent].
  const AppointmentFilterContent({
    this.scrollController,
    super.key,
  });

  /// Scroll controller passed down from bottom sheet for draggable behavior.
  final ScrollController? scrollController;

  @override
  ConsumerState<AppointmentFilterContent> createState() =>
      _AppointmentFilterContentState();
}

class _AppointmentFilterContentState
    extends ConsumerState<AppointmentFilterContent> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  AppointmentStatus? _selectedStatus;
  AppointmentType? _selectedType;

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(allAppointmentsProvider.notifier);
    _dateFrom = notifier.dateFrom;
    _dateTo = notifier.dateTo;
    _selectedStatus = _parseStatus(notifier.status);
    _selectedType = _parseType(notifier.type);
  }

  AppointmentStatus? _parseStatus(String? dbValue) {
    if (dbValue == null) return null;
    return AppointmentStatus.values.cast<AppointmentStatus?>().firstWhere(
          (s) => s!.dbValue == dbValue,
          orElse: () => null,
        );
  }

  AppointmentType? _parseType(String? dbValue) {
    if (dbValue == null) return null;
    return AppointmentType.values.cast<AppointmentType?>().firstWhere(
          (t) => t!.dbValue == dbValue,
          orElse: () => null,
        );
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
        _dateTo = picked.end.add(const Duration(days: 1)); // exclusive
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _dateFrom = null;
      _dateTo = null;
      _selectedStatus = null;
      _selectedType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(allAppointmentsProvider.notifier);
    final user = ref.watch(currentUserProvider).value;
    final isReceptionist = user?.role == UserRole.receptionist;

    final String dateRangeText = _dateFrom != null && _dateTo != null
        ? '${Formatters.formatDateShort(_dateFrom!)} - ${Formatters.formatDateShort(_dateTo!.subtract(const Duration(days: 1)))}'
        : (_dateFrom != null
            ? 'From ${Formatters.formatDateShort(_dateFrom!)}'
            : (_dateTo != null
                ? 'Until ${Formatters.formatDateShort(_dateTo!.subtract(const Duration(days: 1)))}'
                : 'Select Date Range'));

    final List<Widget> additional = [
      // ── Date Range ──
      const SectionHeader(title: 'Date Range'),
      const SizedBox(height: AppSizes.p8),
      Container(
        decoration: BoxDecoration(
          color: (_dateFrom != null || _dateTo != null)
              ? AppColors.primaryLight
              : AppColors.surface,
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
          border: Border.all(
            color: (_dateFrom != null || _dateTo != null)
                ? AppColors.primary
                : AppColors.border,
            width: AppSizes.borderWidth,
          ),
        ),
        child: InkWell(
          onTap: _pickDateRange,
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p16,
              vertical: AppSizes.p12,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.date_range_rounded,
                  size: AppSizes.iconDefault,
                  color: (_dateFrom != null || _dateTo != null)
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSizes.p12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date Range',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.p2),
                      Text(
                        dateRangeText,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: (_dateFrom != null || _dateTo != null)
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: AppSizes.p16),

      // ── Appointment Status ChoiceChips ──
      const SectionHeader(title: 'Appointment Status'),
      const SizedBox(height: AppSizes.p8),
      Wrap(
        spacing: AppSizes.p8,
        runSpacing: AppSizes.p8,
        children: [
          AppFilterChip(
            label: 'All',
            isActive: _selectedStatus == null,
            onTap: () => setState(() => _selectedStatus = null),
          ),
          AppFilterChip(
            label: AppStrings.scheduled,
            isActive: _selectedStatus == AppointmentStatus.scheduled,
            onTap: () => setState(() => _selectedStatus = AppointmentStatus.scheduled),
          ),
          AppFilterChip(
            label: AppStrings.checkedIn,
            isActive: _selectedStatus == AppointmentStatus.checkedIn,
            onTap: () => setState(() => _selectedStatus = AppointmentStatus.checkedIn),
          ),
          AppFilterChip(
            label: AppStrings.cancelled,
            isActive: _selectedStatus == AppointmentStatus.cancelled,
            onTap: () => setState(() => _selectedStatus = AppointmentStatus.cancelled),
          ),
        ],
      ),
      const SizedBox(height: AppSizes.p16),

      // ── Session Type ChoiceChips ──
      const SectionHeader(title: 'Session Type'),
      const SizedBox(height: AppSizes.p8),
      Wrap(
        spacing: AppSizes.p8,
        runSpacing: AppSizes.p8,
        children: [
          AppFilterChip(
            label: 'All',
            isActive: _selectedType == null,
            onTap: () => setState(() => _selectedType = null),
          ),
          AppFilterChip(
            label: 'Session',
            isActive: _selectedType == AppointmentType.session,
            onTap: () => setState(() => _selectedType = AppointmentType.session),
          ),
          AppFilterChip(
            label: 'Spinal Traction',
            isActive: _selectedType == AppointmentType.gehazShadFakarat,
            onTap: () =>
                setState(() => _selectedType = AppointmentType.gehazShadFakarat),
          ),
          AppFilterChip(
            label: 'Follow-up',
            isActive: _selectedType == AppointmentType.checkUp,
            onTap: () => setState(() => _selectedType = AppointmentType.checkUp),
          ),
        ],
      ),
    ];

    return UnifiedFilterSheet(
      initialDoctorId: notifier.doctorId,
      initialClinic: _parseClinic(notifier.clinic),
      showBranchFilter: !isReceptionist,
      additionalFilters: additional,
      onReset: _clearFilters,
      scrollController: widget.scrollController,
      onApplied: (String? doctorId, ClinicLocation? clinic) {
        notifier.setFilters(
          from: _dateFrom,
          to: _dateTo,
          docId: doctorId,
          clinicLoc: clinic?.dbValue,
          statusFilter: _selectedStatus?.dbValue,
          typeFilter: _selectedType?.dbValue,
        );
        Navigator.of(context).pop();
      },
    );
  }

  ClinicLocation? _parseClinic(String? dbValue) {
    if (dbValue == null) return null;
    return ClinicLocation.values.cast<ClinicLocation?>().firstWhere(
          (c) => c!.dbValue == dbValue,
          orElse: () => null,
        );
  }
}
