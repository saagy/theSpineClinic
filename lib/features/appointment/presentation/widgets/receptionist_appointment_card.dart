/// Hybrid appointment card with status-based background styling.
///
/// Layout: [80px date/time] | avatar | patient info (expanded) | ··· menu.
/// When [showDate] is true the left column stacks "MMM d" over "hh:mm a".
/// Status is communicated via container background, border, and timing
/// colour — no text badges. Cancelled appointments get strikethrough
/// and a muted gray avatar.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_actions_trailing.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_status_style.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/status_indicator.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';

/// A single appointment card used across receptionist and doctor screens.
class ReceptionistAppointmentCard extends StatelessWidget {
  /// Creates a [ReceptionistAppointmentCard].
  const ReceptionistAppointmentCard({
    super.key,
    required this.item,
    this.faded = false,
    this.showMenu = true,
    this.onStatusChanged,
    this.showDate = false,
  });

  final AppointmentWithPatient item;
  final bool faded;
  final bool showMenu;
  final VoidCallback? onStatusChanged;

  /// When true, the left column stacks a short date ("Jun 6") over the time
  /// ("09:00 AM"). Used in patient history views where every card may fall
  /// on a different date. Defaults to false (time-only).
  final bool showDate;

  static const double _timeWidth = 80;

  @override
  Widget build(BuildContext context) {
    final AppointmentStatus status = item.appointment.status;
    final AppointmentStatusStyle style = AppointmentStatusStyle.forStatus(status);
    final bool isCancelled = status == AppointmentStatus.cancelled;
    // Cancelled always fades regardless of the caller's flag.
    final bool applyFade = faded || isCancelled;

    final Widget card = Container(
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        border: Border.all(color: style.border, width: 0.5),
      ),
      child: Material(
        color: AppColors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
          onTap: () => context.push(
            AppRoutes.appointmentDetail.replaceAll(':id', item.appointment.id),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p16, vertical: AppSizes.p12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Date / Time column (80 px) ──
                SizedBox(
                  width: _timeWidth,
                  child: showDate
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('MMM d').format(item.appointment.scheduledAt.toLocal()),
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: AppTextStyles.caption.copyWith(color: style.timeColor),
                            ),
                            Text(
                              DateFormat('hh:mm a').format(item.appointment.scheduledAt.toLocal()),
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: AppTextStyles.bodyBold.copyWith(color: style.timeColor),
                            ),
                          ],
                        )
                      : Text(
                          Formatters.formatTime(item.appointment.scheduledAt.toLocal()),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style: AppTextStyles.bodyBold.copyWith(color: style.timeColor),
                        ),
                ),
                const SizedBox(width: AppSizes.p12),
                // ── Avatar ──
                AppAvatar(
                  name: item.patient.fullName,
                  radius: AppSizes.avatarTile / 2,
                  color: style.avatarBg,
                ),
                const SizedBox(width: AppSizes.p12),
                // ── Patient info ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.patient.fullName,
                        style: AppTextStyles.bodyBold.copyWith(
                          color: style.nameColor,
                          decoration: style.nameDecoration,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSizes.p2),
                      Text(
                        item.appointment.type.displayLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Status micro-indicator ──
                if (showMenu) ...[
                  const SizedBox(width: AppSizes.p12),
                  StatusIndicator(status: item.appointment.status),
                  const SizedBox(width: AppSizes.p12),
                  AppointmentActionsTrailing(
                    appointment: item.appointment,
                    onStatusChanged: onStatusChanged,
                    showBadge: false,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    final Widget padded = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
      child: applyFade ? Opacity(opacity: 0.45, child: card) : card,
    );
    return padded;
  }
}
