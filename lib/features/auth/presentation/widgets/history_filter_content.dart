import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/shared/widgets/filter_chip.dart';
import 'package:spine_clinic_app/shared/widgets/section_header.dart';
import 'package:spine_clinic_app/shared/widgets/unified_filter_sheet.dart';

/// Renders the history-specific filters and hooks into the unified filter sheet.
///
/// Follows the same pattern as [AppointmentFilterContent]: a
/// [ConsumerStatefulWidget] that wraps [UnifiedFilterSheet], holding local
/// state for Date Range and Session Type while delegating Branch to
/// [UnifiedFilterSheet]'s built-in branch section.
class HistoryFilterContent extends ConsumerStatefulWidget {
  /// Creates a [HistoryFilterContent].
  const HistoryFilterContent({
    required this.initialDateFrom,
    required this.initialDateTo,
    required this.initialType,
    required this.initialBranch,
    required this.onApplied,
    this.scrollController,
    super.key,
  });

  /// The initially selected date-from filter.
  final DateTime? initialDateFrom;

  /// The initially selected date-to filter (exclusive upper bound).
  final DateTime? initialDateTo;

  /// The initially selected appointment type filter.
  final AppointmentType? initialType;

  /// The initially selected branch filter.
  final ClinicLocation? initialBranch;

  /// Called when filters are applied.
  final void Function({
    required DateTime? dateFrom,
    required DateTime? dateTo,
    required AppointmentType? type,
    required ClinicLocation? clinic,
  }) onApplied;

  /// Scroll controller passed down from the bottom sheet for draggable behavior.
  final ScrollController? scrollController;

  @override
  ConsumerState<HistoryFilterContent> createState() =>
      _HistoryFilterContentState();
}

class _HistoryFilterContentState extends ConsumerState<HistoryFilterContent> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  AppointmentType? _selectedType;

  @override
  void initState() {
    super.initState();
    _dateFrom = widget.initialDateFrom;
    _dateTo = widget.initialDateTo;
    _selectedType = widget.initialType;
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

  @override
  Widget build(BuildContext context) {
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

      // ── Session Type ──
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
          ...AppointmentType.values.map(
            (t) => AppFilterChip(
              label: t.displayLabel,
              isActive: _selectedType == t,
              onTap: () => setState(() => _selectedType = t),
            ),
          ),
        ],
      ),
    ];

    return UnifiedFilterSheet(
      initialDoctorId: null,
      initialClinic: widget.initialBranch,
      showDoctorFilter: false,
      showBranchFilter: true,
      additionalFilters: additional,
      scrollController: widget.scrollController,
      onReset: () {
        setState(() {
          _dateFrom = null;
          _dateTo = null;
          _selectedType = null;
        });
      },
      onApplied: (String? doctorId, ClinicLocation? clinic) {
        widget.onApplied(
          dateFrom: _dateFrom,
          dateTo: _dateTo,
          type: _selectedType,
          clinic: clinic,
        );
      },
    );
  }
}
