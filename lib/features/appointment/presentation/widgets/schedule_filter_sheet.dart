import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_filter_doctor_view.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_monogram_badge.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';

class ScheduleFilterResult {
  const ScheduleFilterResult({required this.doctorId});
  final String? doctorId;
}

enum _ScheduleFilterPage { main, doctorPicker }

/// Modal filter sheet for the appointments schedule tab,
/// following the design language of [PatientFilterSheet].
class ScheduleFilterSheet extends ConsumerStatefulWidget {
  const ScheduleFilterSheet({
    super.key,
    required this.initialDoctorId,
  });

  final String? initialDoctorId;

  static Future<ScheduleFilterResult?> show({
    required BuildContext context,
    required String? doctorId,
  }) {
    return showModalBottomSheet<ScheduleFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ScheduleFilterSheet(initialDoctorId: doctorId),
    );
  }

  @override
  ConsumerState<ScheduleFilterSheet> createState() =>
      _ScheduleFilterSheetState();
}

class _ScheduleFilterSheetState extends ConsumerState<ScheduleFilterSheet> {
  _ScheduleFilterPage _page = _ScheduleFilterPage.main;
  late String? _doctorId = widget.initialDoctorId;

  void _reset() {
    setState(() => _doctorId = null);
  }

  void _apply() {
    Navigator.of(context).pop(ScheduleFilterResult(doctorId: _doctorId));
  }

  String _doctorSummary(List<Staff> doctors) {
    if (_doctorId == null) return AppStrings.filterAllDoctors;
    final doc = doctors
        .cast<Staff?>()
        .firstWhere((d) => d?.id == _doctorId, orElse: () => null);
    return doc?.fullName ?? AppStrings.filterAllDoctors;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final doctors =
        ref.watch(allDoctorsForFilterProvider).value ?? const <Staff>[];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.r16),
        ),
        border: Border.all(
          color: cs.outlineVariant,
          width: AppSizes.borderWidth,
        ),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _page == _ScheduleFilterPage.doctorPicker
              ? PatientFilterDoctorView(
                  selectedDoctorId: _doctorId,
                  doctors: doctors,
                  onDoctorSelected: (id) => setState(() {
                    _doctorId = id;
                    _page = _ScheduleFilterPage.main;
                  }),
                  onBack: () =>
                      setState(() => _page = _ScheduleFilterPage.main),
                )
              : _buildMainView(context, cs, doctors),
        ),
      ),
    );
  }

  Widget _buildMainView(
    BuildContext context,
    ColorScheme cs,
    List<Staff> doctors,
  ) {
    final hasDoctor = _doctorId != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
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
                    onPressed: _reset,
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p20,
            vertical: AppSizes.p12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.assignedDoctors,
                style: AppTextStyles.captionBold.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSizes.p8),
              InkWell(
                onTap: () => setState(
                  () => _page = _ScheduleFilterPage.doctorPicker,
                ),
                borderRadius: BorderRadius.circular(AppSizes.r8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p12,
                    vertical: AppSizes.p10,
                  ),
                  decoration: BoxDecoration(
                    color: hasDoctor
                        ? cs.primaryContainer.withAlpha(50)
                        : cs.surfaceContainerHighest.withAlpha(80),
                    borderRadius: BorderRadius.circular(AppSizes.r8),
                    border: Border.all(
                      color: hasDoctor ? cs.primary : cs.outlineVariant,
                      width: AppSizes.borderWidth,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (hasDoctor) ...[
                        PatientMonogramBadge(
                          name: _doctorSummary(doctors),
                          size: 24,
                        ),
                        const SizedBox(width: AppSizes.p8),
                      ] else ...[
                        Icon(
                          LucideIcons.stethoscope,
                          size: 18,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSizes.p8),
                      ],
                      Expanded(
                        child: Text(
                          _doctorSummary(doctors),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: hasDoctor ? cs.primary : cs.onSurface,
                            fontWeight: hasDoctor
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      Icon(
                        LucideIcons.chevron_right,
                        size: 16,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.p20,
            AppSizes.p8,
            AppSizes.p20,
            AppSizes.p16,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.p12,
                    ),
                    side: BorderSide(
                      color: cs.outlineVariant,
                      width: AppSizes.borderWidth,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.r8),
                    ),
                  ),
                  child: Text(
                    AppStrings.resetFilters,
                    style: AppTextStyles.bodyBold.copyWith(color: cs.onSurface),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                child: FilledButton(
                  onPressed: _apply,
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.p12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.r8),
                    ),
                  ),
                  child: Text(
                    AppStrings.applyFilters,
                    style: AppTextStyles.bodyBold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
