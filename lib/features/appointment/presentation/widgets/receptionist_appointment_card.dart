/// Hybrid appointment card with status-based background styling.
///
/// Layout: [65px time] | avatar | patient info (expanded) | ··· menu.
/// Status is communicated via container background, border, and timing
/// colour — no text badges. Cancelled appointments get strikethrough
/// and a muted gray avatar.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_actions_trailing.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/status_indicator.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';

/// Status-driven colour tokens for the hybrid card.
class _StatusStyle {
  const _StatusStyle({
    required this.bg,
    required this.border,
    required this.timeColor,
    required this.avatarBg,
    required this.nameDecoration,
    required this.nameColor,
  });

  final Color bg;
  final Color border;
  final Color timeColor;
  final Color avatarBg;
  final TextDecoration? nameDecoration;
  final Color nameColor;

  static _StatusStyle forStatus(AppointmentStatus s) => switch (s) {
    AppointmentStatus.checkedIn => const _StatusStyle(
        bg: Color(0xFFF0FAF6),
        border: Color(0xFF9FE1CB),
        timeColor: Color(0xFF085041),
        avatarBg: AppColors.primary,
        nameDecoration: null,
        nameColor: AppColors.textPrimary,
      ),
    AppointmentStatus.cancelled => const _StatusStyle(
        bg: AppColors.surface,
        border: AppColors.border,
        timeColor: AppColors.textMuted,
        avatarBg: AppColors.textMuted,
        nameDecoration: TextDecoration.lineThrough,
        nameColor: AppColors.textMuted,
      ),
    _ => const _StatusStyle(
        bg: AppColors.surface,
        border: AppColors.border,
        timeColor: AppColors.textPrimary,
        avatarBg: AppColors.primary,
        nameDecoration: null,
        nameColor: AppColors.textPrimary,
      ),
  };
}

/// A single appointment card used across receptionist and doctor screens.
class ReceptionistAppointmentCard extends StatelessWidget {
  /// Creates a [ReceptionistAppointmentCard].
  const ReceptionistAppointmentCard({
    super.key,
    required this.item,
    this.faded = false,
    this.showMenu = true,
    this.onStatusChanged,
  });

  final AppointmentWithPatient item;
  final bool faded;
  final bool showMenu;
  final VoidCallback? onStatusChanged;

  static const double _timeWidth = 65;

  @override
  Widget build(BuildContext context) {
    final AppointmentStatus status = item.appointment.status;
    final _StatusStyle style = _StatusStyle.forStatus(status);
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
              children: [
                // ── Time column ──
                SizedBox(
                  width: _timeWidth,
                  child: Text(
                    Formatters.formatTime(
                        item.appointment.scheduledAt.toLocal()),
                    style: AppTextStyles.bodyBold.copyWith(
                      color: style.timeColor,
                    ),
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
