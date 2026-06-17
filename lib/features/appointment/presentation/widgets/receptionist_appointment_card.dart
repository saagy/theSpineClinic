/// Appointment card with stacked time, auto-scaling name, and premium
/// dot+text status indicator.
///
///   LEADING  = stacked hh:mm / AM:PM + avatar
///   MIDDLE   = AutoSizeText name / session type + status dot
///   TRAILING = three-dot menu (vertically centred)
///
/// Rule 1  — under 200 lines.  Rule 13 — min 16 px internal padding.
library;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_actions_trailing.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_status_style.dart';
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

    final DateTime t = item.appointment.scheduledAt.toLocal();
    final Widget timeWidget = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showDate)
          Text(DateFormat('MMM d').format(t), maxLines: 1, softWrap: false,
              style: AppTextStyles.caption.copyWith(color: style.timeColor, fontSize: 11)),
        Text(DateFormat('hh:mm').format(t), maxLines: 1, softWrap: false,
            style: AppTextStyles.captionBold.copyWith(color: style.timeColor, fontSize: 13)),
        Text(DateFormat('a').format(t), maxLines: 1, softWrap: false,
            style: AppTextStyles.caption.copyWith(color: style.timeColor, fontSize: 10)),
      ],
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
                // Leading: Time + Avatar
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AutoSizeText(
                        item.patient.fullName,
                        style: AppTextStyles.bodyBold.copyWith(
                          color: style.nameColor,
                          decoration: style.nameDecoration,
                        ),
                        maxLines: 1,
                        minFontSize: 11,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSizes.p2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              item.appointment.type.displayLabel,
                              style: AppTextStyles.caption.copyWith(
                                color: Theme.of(context)
                                    .colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSizes.p6),
                          _StatusDot(
                            color: status.textColor,
                            label: status.displayLabel,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (showMenu) ...[
                  const SizedBox(width: AppSizes.p8),
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

    // Vertical spacing between cards: 6 px top + 6 px bottom = 12 px gap.
    final Widget padded = Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p16, vertical: AppSizes.p6),
      child: applyFade
          ? Opacity(opacity: 0.45, child: card)
          : card,
    );
    return padded;
  }
}

/// Colour-coded dot + coloured text — no background pill.
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: AppSizes.p6, height: AppSizes.p6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: AppSizes.p4),
      Text(label,
          style: AppTextStyles.caption.copyWith(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    ]);
  }
}
