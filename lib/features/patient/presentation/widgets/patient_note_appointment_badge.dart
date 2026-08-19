import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

/// Clean pill-shaped badge displaying linked appointment info.
class PatientNoteAppointmentBadge extends ConsumerWidget {
  const PatientNoteAppointmentBadge({super.key, required this.appointmentId});
  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentAsync = ref.watch(singleAppointmentProvider(appointmentId));
    final cs = Theme.of(context).colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: appointmentAsync.when(
        data: (appt) {
          final apptDate = Formatters.formatDateMedium(appt.scheduledAt);
          return Align(
            key: const ValueKey('appt_badge_data'),
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p10, vertical: AppSizes.p6),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withAlpha(80),
                borderRadius: BorderRadius.circular(AppSizes.r8),
                border: Border.all(color: cs.primary.withAlpha(35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_note_rounded, size: 14, color: cs.primary),
                  const SizedBox(width: AppSizes.p6),
                  Flexible(
                    child: Text(
                      '${AppStrings.onAppointmentPrefix}${appt.type.displayLabel} ($apptDate)',
                      style: AppTextStyles.captionBold.copyWith(color: cs.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Align(
          key: ValueKey('appt_badge_loading'),
          alignment: Alignment.centerLeft,
          child: SkeletonBox(width: 180, height: 26, borderRadius: AppSizes.r8),
        ),
        error: (_, __) => Align(
          key: const ValueKey('appt_badge_error'),
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p10, vertical: AppSizes.p6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSizes.r8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.link_rounded, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: AppSizes.p6),
                Text(
                  AppStrings.linkedAppointmentLabel,
                  style: AppTextStyles.captionMedium.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
