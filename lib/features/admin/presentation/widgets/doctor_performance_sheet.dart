import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/admin/data/analytics_dtos.dart';
import 'package:spine_clinic_app/shared/widgets/status_badge.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';

/// Modal bottom sheet content displaying detailed daily attendance and performance log.
class DoctorPerformanceSheet extends StatelessWidget {
  const DoctorPerformanceSheet({
    super.key,
    required this.performance,
    required this.scrollController,
  });

  /// The doctor performance data payload.
  final DoctorPerformance performance;

  /// Scroll controller passed by [AppBottomSheet] for list scroll physics.
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ClinicColors clinicColors = ClinicColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
          child: Row(
            children: [
              Expanded(
                child: _MetricItem(
                  label: AppStrings.activeDays,
                  value: '${performance.activeDays}',
                  icon: Icons.calendar_today_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                child: _MetricItem(
                  label: AppStrings.absences,
                  value: '${performance.absenceCount}',
                  icon: Icons.warning_amber_rounded,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                child: _MetricItem(
                  label: AppStrings.completed,
                  value: '${performance.completedAppointments}/${performance.totalAppointments}',
                  icon: Icons.check_circle_rounded,
                  color: clinicColors.success,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.p16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.p20),
          child: Divider(),
        ),
        const SizedBox(height: AppSizes.p8),
        Expanded(
          child: performance.dailyLogs.isEmpty
              ? const EmptyState(
                  message: AppStrings.noActivity,
                  icon: Icons.history_rounded,
                )
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p8),
                  itemCount: performance.dailyLogs.length,
                  itemBuilder: (context, index) {
                    final log = performance.dailyLogs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.p12),
                      child: Container(
                        padding: const EdgeInsets.all(AppSizes.p16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
                          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              log.date.toMediumDateString(),
                              style: AppTextStyles.bodyBold.copyWith(color: theme.colorScheme.onSurface),
                            ),
                            if (log.isAbsent)
                              StatusBadge(
                                label: AppStrings.absentCoveredBy.replaceAll('%s', log.coveringDoctorName ?? AppStrings.unknownFallback),
                                variant: StatusVariant.cancelled,
                              )
                            else if (log.totalAppointments > 0)
                              StatusBadge(
                                label: '${log.completedAppointments}/${log.totalAppointments} ${AppStrings.completed.toLowerCase()}',
                                variant: StatusVariant.completed,
                              )
                            else
                              Text(
                                AppStrings.noActivity,
                                style: AppTextStyles.caption.copyWith(color: clinicColors.textMuted),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ClinicColors clinicColors = ClinicColors.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: AppSizes.iconDefault),
          const SizedBox(height: AppSizes.p8),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: clinicColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSizes.p4),
          Text(
            value,
            style: AppTextStyles.bodyBold.copyWith(color: theme.colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}
