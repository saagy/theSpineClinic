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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_schedule_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_actions_trailing.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_badge_colors.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_status_style.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_list_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

part 'receptionist_appointment_card_menu.dart';
part 'receptionist_appointment_card_parts.dart';

/// A single appointment card used across receptionist and doctor screens.
class ReceptionistAppointmentCard extends ConsumerStatefulWidget {
  const ReceptionistAppointmentCard({
    super.key,
    required this.item,
    this.showMenu = true,
    this.onStatusChanged,
    this.showDate = false,
  });

  final AppointmentWithPatient item;
  final bool showMenu;
  final VoidCallback? onStatusChanged;

  /// When true the leading section stacks "MMM d" over "hh:mm a".
  /// Defaults to false (time-only).
  final bool showDate;

  @override
  ConsumerState<ReceptionistAppointmentCard> createState() =>
      _ReceptionistAppointmentCardState();
}

class _ReceptionistAppointmentCardState
    extends ConsumerState<ReceptionistAppointmentCard>
    with _ReceptionistAppointmentCardMenu {
  @override
  Widget build(BuildContext context) {
    final AppointmentStatus status = widget.item.appointment.status;
    final AppointmentStatusStyle style = AppointmentStatusStyle.forStatus(
      context,
      status,
    );
    final AppointmentBadgeColors statusBadge = status.badgeColors(context);
    final bool isCancelled = status == AppointmentStatus.cancelled;
    final bool applyFade = isCancelled;

    final DateTime t = widget.item.appointment.scheduledAt.toLocal();
    final bool isPastScheduled =
        status == AppointmentStatus.scheduled &&
        DateUtils.dateOnly(t).isBefore(DateUtils.dateOnly(DateTime.now()));
    final ClinicColors clinic = ClinicColors.of(context);

    final user = ref.watch(currentUserProvider).value;
    final bool isDoctor = user?.role == UserRole.doctor;
    final canAccessAsync = isDoctor
        ? ref.watch(
            canAccessAppointmentProvider(
              appointmentId: widget.item.appointment.id,
              patientId: widget.item.patient.id,
            ),
          )
        : const AsyncValue.data(true);
    final bool canAccess = canAccessAsync.value ?? !isDoctor;
    final bool enableMenu = widget.showMenu && canAccess;

    final Widget card = Container(
      decoration: BoxDecoration(
        color: isPastScheduled ? clinic.warningContainer : style.bg,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        border: Border.all(
          color: isPastScheduled ? clinic.warning : style.border,
          width: AppSizes.borderWidth,
        ),
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface.withAlpha(0),
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        child: GestureDetector(
          onLongPressStart: enableMenu
              ? (details) => showLongPressMenu(details.globalPosition)
              : null,
          onSecondaryTapDown: enableMenu
              ? (details) => showLongPressMenu(details.globalPosition)
              : null,
          child: InkWell(
            borderRadius:
                const BorderRadius.all(Radius.circular(AppSizes.r16)),
            onTap: () async {
              if (!canAccess) {
                AppSnackbar.show(
                  context,
                  message: AppStrings.errorDatabasePermissionDenied,
                  variant: AppSnackbarVariant.error,
                );
                return;
              }
              await context.push(
                AppRoutes.appointmentDetail.replaceAll(
                  ':id',
                  widget.item.appointment.id,
                ),
              );
              if (context.mounted) widget.onStatusChanged?.call();
            },
            // Rule 13 — minimum 16 px internal padding.
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.p16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Leading: Time + Avatar
                  _TimeAvatar(
                    item: widget.item,
                    showDate: widget.showDate,
                    style: style,
                  ),
                  const SizedBox(width: AppSizes.p8),
                  Expanded(
                    child: _NameStatus(
                      item: widget.item,
                      style: style,
                      statusBadge: statusBadge,
                      isPastScheduled: isPastScheduled,
                      clinic: clinic,
                    ),
                  ),
                  if (enableMenu) ...[
                    const SizedBox(width: AppSizes.p8),
                    AppointmentActionsTrailing(
                      appointment: widget.item.appointment,
                      onStatusChanged: widget.onStatusChanged,
                      showBadge: false,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Vertical spacing between cards: 6 px top + 6 px bottom = 12 px gap.
    final Widget padded = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p6,
      ),
      child: applyFade ? Opacity(opacity: 0.6, child: card) : card,
    );
    return padded;
  }
}
