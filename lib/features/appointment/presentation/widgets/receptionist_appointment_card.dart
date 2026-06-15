/// Hybrid appointment card with status-based background styling.
///
/// Fluid three-section layout — no hardcoded widths or heights:
///   LEADING  = time + avatar in a min-width Row
///   MIDDLE   = name + type in Expanded
///   TRAILING = status + menu in a min-width Row
///
/// Status is communicated via container background, border, and timing
/// colour. Cancelled appointments get strikethrough and a muted avatar.
///
/// Rule 1  — under 200 lines.
/// Rule 13 — min 16 px internal padding.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

  /// When true the leading section stacks "MMM d" over "hh:mm a".
  /// Defaults to false (time-only).
  final bool showDate;

  static const double _avatarRadius = 18;

  @override
  Widget build(BuildContext context) {
    final AppointmentStatus status = item.appointment.status;
    final AppointmentStatusStyle style = AppointmentStatusStyle.forStatus(status);
    final bool isCancelled = status == AppointmentStatus.cancelled;
    final bool applyFade = faded || isCancelled;

    // ── Time widget: single line or date-over-time column ──
    final Widget timeWidget = showDate
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMM d')
                    .format(item.appointment.scheduledAt.toLocal()),
                maxLines: 1,
                softWrap: false,
                style: AppTextStyles.caption
                    .copyWith(color: style.timeColor, fontSize: 12),
              ),
              Text(
                DateFormat('hh:mm a')
                    .format(item.appointment.scheduledAt.toLocal()),
                maxLines: 1,
                softWrap: false,
                style: AppTextStyles.captionBold
                    .copyWith(color: style.timeColor, fontSize: 13),
              ),
            ],
          )
        : Text(
            Formatters.formatTime(
                item.appointment.scheduledAt.toLocal()),
            maxLines: 1,
            softWrap: false,
            style: AppTextStyles.captionBold
                .copyWith(color: style.timeColor, fontSize: 13),
          );

    final Widget card = Container(
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius:
            const BorderRadius.all(Radius.circular(AppSizes.r16)),
        border: Border.all(color: style.border, width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius:
            const BorderRadius.all(Radius.circular(AppSizes.r16)),
        child: InkWell(
          borderRadius:
              const BorderRadius.all(Radius.circular(AppSizes.r16)),
          onTap: () => context.push(
            AppRoutes.appointmentDetail
                .replaceAll(':id', item.appointment.id),
          ),
          // Rule 13 — minimum 16 px internal padding.
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── LEADING: Time + Avatar (min-size Row, never overlaps) ──
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    timeWidget,
                    const SizedBox(width: AppSizes.p8),
                    AppAvatar(
                      name: item.patient.fullName,
                      radius: _avatarRadius,
                      color: style.avatarBg,
                    ),
                  ],
                ),
                const SizedBox(width: AppSizes.p8),
                // ── MIDDLE: Patient Info (Expanded, fills remaining space) ──
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
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSizes.p2),
                      Text(
                        item.appointment.type.displayLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // ── TRAILING: Status + Menu (min-size Row, never overflows) ──
                if (showMenu) ...[
                  const SizedBox(width: AppSizes.p8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusIndicator(
                          status: item.appointment.status),
                      const SizedBox(width: AppSizes.p4),
                      AppointmentActionsTrailing(
                        appointment: item.appointment,
                        onStatusChanged: onStatusChanged,
                        showBadge: false,
                      ),
                    ],
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
      child: applyFade
          ? Opacity(opacity: 0.45, child: card)
          : card,
    );
    return padded;
  }
}
