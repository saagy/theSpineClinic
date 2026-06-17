import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_notes_list_notifier.dart';
import 'package:spine_clinic_app/shared/widgets/section_header.dart';
import 'package:spine_clinic_app/shared/widgets/unified_filter_sheet.dart';

class PatientNotesFilterContent extends ConsumerStatefulWidget {
  const PatientNotesFilterContent({
    super.key,
    required this.patientId,
    this.scrollController,
  });

  final String patientId;
  final ScrollController? scrollController;

  @override
  ConsumerState<PatientNotesFilterContent> createState() => _PatientNotesFilterContentState();
}

class _PatientNotesFilterContentState extends ConsumerState<PatientNotesFilterContent> {
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    final state = ref.read(patientNotesListProvider(widget.patientId));
    _dateFrom = state.dateFrom;
    _dateTo = state.dateTo;
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
      showDoctorFilter: false,
      initialDoctorId: null,
      initialClinic: null,
      onReset: () {
        setState(() {
          _dateFrom = null;
          _dateTo = null;
        });
      },
      onApplied: (_, __) {
        final notifier = ref.read(patientNotesListProvider(widget.patientId).notifier);
        notifier.setDateRange(_dateFrom, _dateTo);
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
      ],
    );
  }
}
