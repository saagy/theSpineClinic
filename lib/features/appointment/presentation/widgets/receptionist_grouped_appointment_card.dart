import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_actions_trailing.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';

/// Renders multiple appointments for a patient on the same day as a single,
/// unified card with a sub-session timeline and batch status options.
class ReceptionistGroupedAppointmentCard extends ConsumerStatefulWidget {
  const ReceptionistGroupedAppointmentCard({
    super.key,
    required this.patient,
    required this.items,
    this.onStatusChanged,
  });

  final Patient patient;
  final List<AppointmentWithPatient> items;
  final VoidCallback? onStatusChanged;

  @override
  ConsumerState<ReceptionistGroupedAppointmentCard> createState() =>
      _ReceptionistGroupedAppointmentCardState();
}

class _ReceptionistGroupedAppointmentCardState
    extends ConsumerState<ReceptionistGroupedAppointmentCard> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clinic = ClinicColors.of(context);
    final user = ref.watch(currentUserProvider).value;
    final bool isAuthorizedStaff = user != null &&
        (user.role == UserRole.receptionist ||
            user.role == UserRole.superAdmin ||
            user.role == UserRole.doctor);

    final statuses = widget.items.map((i) => i.appointment.status).toSet();

    final bool hasScheduled = statuses.contains(AppointmentStatus.scheduled);
    final bool hasCheckedIn = statuses.contains(AppointmentStatus.checkedIn);

    final sortedItems = List<AppointmentWithPatient>.from(widget.items)
      ..sort((a, b) => a.appointment.scheduledAt.compareTo(b.appointment.scheduledAt));

    final tEarliest = sortedItems.first.appointment.scheduledAt.toLocal();
    final timeStr = DateFormat('hh:mm a').format(tEarliest);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p6,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        border: Border.all(
          color: theme.colorScheme.outline,
          width: AppSizes.borderWidth,
        ),
        boxShadow: [clinic.cardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppAvatar(
                    name: widget.patient.fullName,
                    radius: AppSizes.avatarSmall / 2,
                  ),
                  const SizedBox(width: AppSizes.p12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          widget.patient.fullName,
                          style: AppTextStyles.bodyBold.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSizes.p2),
                        Text(
                          '$timeStr • Dual Session',
                          style: AppTextStyles.caption.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAuthorizedStaff)
                    _buildGroupContextMenu(
                      context,
                      widget.items,
                      hasScheduled,
                      hasCheckedIn,
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.p12),
              Divider(color: theme.colorScheme.outline, height: 1, thickness: 0.5),
              const SizedBox(height: AppSizes.p8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSizes.p8),
                itemBuilder: (context, idx) {
                  final item = sortedItems[idx];
                  final subAppt = item.appointment;
                  final localTime = subAppt.scheduledAt.toLocal();
                  final formattedTime = DateFormat('h:mm a').format(localTime);

                  return GestureDetector(
                    onLongPressStart: (details) {
                      if (isAuthorizedStaff) {
                        _showIndividualStatusMenu(
                          subAppt,
                          details.globalPosition,
                        );
                      }
                    },
                    onSecondaryTapDown: (details) {
                      if (isAuthorizedStaff) {
                        _showIndividualStatusMenu(
                          subAppt,
                          details.globalPosition,
                        );
                      }
                    },
                    child: InkWell(
                      borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r8)),
                      onTap: () async {
                        await context.push(
                          AppRoutes.appointmentDetail.replaceAll(
                            ':id',
                            subAppt.id,
                          ),
                        );
                        if (context.mounted) widget.onStatusChanged?.call();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.p6,
                          horizontal: AppSizes.p4,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle_outlined,
                              size: 10,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: AppSizes.p8),
                            Text(
                              formattedTime,
                              style: AppTextStyles.captionBold.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: AppSizes.p12),
                            Expanded(
                              child: Text(
                                subAppt.type.displayLabel,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            AppointmentActionsTrailing(
                              appointment: subAppt,
                              onStatusChanged: widget.onStatusChanged,
                              showBadge: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupContextMenu(
    BuildContext context,
    List<AppointmentWithPatient> items,
    bool hasScheduled,
    bool hasCheckedIn,
  ) {
    final theme = Theme.of(context);
    final clinic = ClinicColors.of(context);

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz_rounded, color: theme.colorScheme.onSurfaceVariant),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      splashRadius: AppSizes.iconDefault,
      color: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r12)),
      ),
      elevation: 1,
      position: PopupMenuPosition.under,
      enabled: !_isProcessing,
      onSelected: (value) {
        if (value == 'check_in_all') {
          final scheduledIds = items
              .where((i) => i.appointment.status == AppointmentStatus.scheduled)
              .map((i) => i.appointment.id)
              .toList();
          _setGroupStatus(scheduledIds, AppointmentStatus.checkedIn);
        } else if (value == 'cancel_all') {
          final cancellableIds = items
              .where((i) => i.appointment.status != AppointmentStatus.cancelled)
              .map((i) => i.appointment.id)
              .toList();
          _confirmCancelAll(cancellableIds);
        } else if (value == 'revert_all') {
          final checkedInIds = items
              .where((i) => i.appointment.status == AppointmentStatus.checkedIn)
              .map((i) => i.appointment.id)
              .toList();
          _setGroupStatus(checkedInIds, AppointmentStatus.scheduled);
        }
      },
      itemBuilder: (context) {
        return [
          if (hasScheduled)
            _menuItem(
              'check_in_all',
              Icons.check_circle_outline_rounded,
              clinic.success,
              'Check In All Sessions',
            ),
          if (hasCheckedIn)
            _menuItem(
              'revert_all',
              Icons.undo_rounded,
              theme.colorScheme.onSurfaceVariant,
              'Revert All Sessions',
            ),
          _menuItem(
            'cancel_all',
            Icons.close_rounded,
            theme.colorScheme.error,
            'Cancel All Sessions',
          ),
        ];
      },
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    Color iconColor,
    String label,
  ) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return PopupMenuItem<String>(
      value: value,
      height: AppSizes.buttonHeightSmall,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: AppSizes.p8),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancelAll(List<String> ids) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(
        title: 'Cancel All Sessions',
        message: 'Are you sure you want to cancel all sessions for this visit?',
        isDestructive: true,
      ),
    );
    if (confirmed == true && mounted) {
      await _setGroupStatus(ids, AppointmentStatus.cancelled);
    }
  }

  Future<void> _setGroupStatus(List<String> ids, AppointmentStatus status) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await ref
          .read(receptionistAppointmentsProvider.notifier)
          .changeGroupStatus(ids, status);
      if (!mounted) return;
      AppSnackbar.show(
        context,
        message: AppStrings.statusUpdateSuccess,
        variant: AppSnackbarVariant.success,
      );
      widget.onStatusChanged?.call();
    } catch (error) {
      if (mounted) {
        AppSnackbar.show(
          context,
          message: 'Error updating session status',
          variant: AppSnackbarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showIndividualStatusMenu(
    Appointment appointment,
    Offset globalPosition,
  ) async {
    final theme = Theme.of(context);
    final clinic = ClinicColors.of(context);
    final status = appointment.status;

    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(globalPosition, globalPosition),
      overlay.localToGlobal(Offset.zero) & overlay.size,
    );

    final String? selectedValue = await showMenu<String>(
      context: context,
      position: position,
      color: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r12)),
      ),
      elevation: 1,
      items: [
        if (status == AppointmentStatus.scheduled) ...[
          _menuItem(
            'check_in',
            Icons.check_circle_outline_rounded,
            clinic.success,
            'Check In',
          ),
          _menuItem(
            'cancel',
            Icons.close_rounded,
            theme.colorScheme.error,
            'Cancel',
          ),
        ],
        if (status == AppointmentStatus.checkedIn) ...[
          _menuItem(
            'revert',
            Icons.undo_rounded,
            theme.colorScheme.onSurfaceVariant,
            'Revert to Scheduled',
          ),
          _menuItem(
            'cancel',
            Icons.close_rounded,
            theme.colorScheme.error,
            'Cancel',
          ),
        ],
        if (status == AppointmentStatus.cancelled) ...[
          _menuItem(
            'restore',
            Icons.refresh_rounded,
            clinic.success,
            'Restore Appointment',
          ),
        ],
      ],
    );

    if (selectedValue == null || !mounted) return;

    if (selectedValue == 'check_in') {
      _setGroupStatus([appointment.id], AppointmentStatus.checkedIn);
    } else if (selectedValue == 'revert') {
      _setGroupStatus([appointment.id], AppointmentStatus.scheduled);
    } else if (selectedValue == 'restore') {
      _setGroupStatus([appointment.id], AppointmentStatus.scheduled);
    } else if (selectedValue == 'cancel') {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => const ConfirmationDialog(
          title: AppStrings.cancelAppointment,
          message: AppStrings.confirmCancel,
          isDestructive: true,
        ),
      );
      if (confirmed == true && mounted) {
        _setGroupStatus([appointment.id], AppointmentStatus.cancelled);
      }
    }
  }
}
