import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';

/// Passive status: consuming a tap here must never navigate or modify data.
class AppointmentStatusIndicator extends StatelessWidget {
  const AppointmentStatusIndicator({
    super.key,
    required this.status,
    this.pending = false,
    this.showLabel = false,
  });
  final AppointmentStatus status;
  final bool pending;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = status == AppointmentStatus.checkedIn
        ? ClinicColors.of(context).success
        : cs.onSurfaceVariant;
    final icon = switch (status) {
      AppointmentStatus.scheduled => Icons.schedule_outlined,
      AppointmentStatus.checkedIn => Icons.check_circle_rounded,
      AppointmentStatus.cancelled => Icons.cancel_outlined,
    };
    return Semantics(
      label: status.displayLabel,
      liveRegion: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: () {},
        child: Tooltip(
          message: status.displayLabel,
          excludeFromSemantics: true,
          child: SizedBox(
            height: AppSizes.tappableMin,
            width: showLabel ? null : AppSizes.agendaIndicatorWidth,
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox.square(
                    dimension: AppSizes.iconDefault,
                    child: AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.85, end: 1).animate(animation),
                          child: child,
                        ),
                      ),
                      child: pending
                          ? Center(
                              key: const ValueKey('pending'),
                              child: SizedBox.square(
                                dimension: AppSizes.iconSmall,
                                child: CircularProgressIndicator(
                                  strokeWidth: AppSizes.strokeWidthThin,
                                  color: cs.primary,
                                ),
                              ),
                            )
                          : Icon(
                              icon,
                              key: ValueKey(status),
                              color: color,
                              size: AppSizes.iconDefault,
                            ),
                    ),
                  ),
                  if (showLabel) ...[
                    const SizedBox(width: AppSizes.p6),
                    Flexible(
                      child: Text(
                        status.displayLabel,
                        style: AppTextStyles.caption.copyWith(color: color),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
