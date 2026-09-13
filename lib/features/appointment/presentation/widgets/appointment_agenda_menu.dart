import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/agenda_status_controller.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/agenda_status_action.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

enum _AgendaAction { patientDetails, checkIn, edit, revert, restore, cancel }

/// Compact anchored popup menu for appointment row operations.
class AppointmentAgendaMenu extends ConsumerWidget {
  const AppointmentAgendaMenu({
    super.key,
    required this.appointmentId,
    required this.patientId,
    required this.status,
  });

  final String appointmentId;
  final String patientId;
  final AppointmentStatus status;

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    AppointmentStatus newStatus,
  ) async {
    await updateAgendaStatus(
      context,
      ref,
      appointmentId: appointmentId,
      patientId: patientId,
      status: newStatus,
    );
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref, _AgendaAction action) async {
    switch (action) {
      case _AgendaAction.patientDetails:
        context.push(AppRoutes.patientDetail.replaceAll(':id', patientId));
      case _AgendaAction.checkIn:
        await _updateStatus(context, ref, AppointmentStatus.checkedIn);
      case _AgendaAction.edit:
        context.push(AppRoutes.editAppointment.replaceAll(':id', appointmentId));
      case _AgendaAction.revert || _AgendaAction.restore:
        await _updateStatus(context, ref, AppointmentStatus.scheduled);
      case _AgendaAction.cancel:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => const ConfirmationDialog(
            title: AppStrings.cancelAppointment,
            message: AppStrings.confirmCancel,
            isDestructive: true,
          ),
        );
        if (confirmed == true && context.mounted) {
          await _updateStatus(context, ref, AppointmentStatus.cancelled);
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider).value;
    final canAccess =
        user?.isActive == true &&
        (ref
                .watch(
                  canAccessAppointmentProvider(appointmentId: appointmentId, patientId: patientId),
                )
                .value ??
            false);
    final canEdit =
        canAccess &&
        (ref
                .watch(
                  canEditAppointmentProvider(appointmentId: appointmentId, patientId: patientId),
                )
                .value ??
            false);
    final pending = ref.watch(agendaStatusControllerProvider(appointmentId)).pending;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: () {},
      child: PopupMenuButton<_AgendaAction>(
        tooltip: AppStrings.moreActions,
        enabled: !pending,
        icon: const Icon(LucideIcons.ellipsis_vertical, size: AppSizes.iconSmall),
        color: cs.surface,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(minimumSize: const Size.square(AppSizes.tappableMin)),
        constraints: const BoxConstraints(minWidth: AppSizes.recordMenuWidth),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.r12),
          side: BorderSide(color: cs.outlineVariant.withAlpha(120), width: AppSizes.borderWidth),
        ),
        onSelected: (action) => _handleAction(context, ref, action),
        itemBuilder: (context) => [
          if (canAccess && status == AppointmentStatus.scheduled)
            PopupMenuItem(
              value: _AgendaAction.checkIn,
              height: AppSizes.tappableMin,
              child: _item(LucideIcons.log_in, AppStrings.checkIn, cs.primary),
            ),
          if (canAccess && status == AppointmentStatus.checkedIn)
            PopupMenuItem(
              value: _AgendaAction.revert,
              height: AppSizes.tappableMin,
              child: _item(LucideIcons.undo_2, AppStrings.undoCheckIn, cs.onSurface),
            ),
          if (canAccess && status == AppointmentStatus.cancelled)
            PopupMenuItem(
              value: _AgendaAction.restore,
              height: AppSizes.tappableMin,
              child: _item(LucideIcons.rotate_ccw, AppStrings.restoreAppointment, cs.onSurface),
            ),
          PopupMenuItem(
            value: _AgendaAction.patientDetails,
            height: AppSizes.tappableMin,
            child: _item(LucideIcons.user_round, AppStrings.patientDetails, cs.onSurface),
          ),
          if (canEdit && status != AppointmentStatus.cancelled)
            PopupMenuItem(
              value: _AgendaAction.edit,
              height: AppSizes.tappableMin,
              child: _item(LucideIcons.pencil, AppStrings.editAppointment, cs.onSurface),
            ),
          if (canAccess && status != AppointmentStatus.cancelled)
            PopupMenuItem(
              value: _AgendaAction.cancel,
              height: AppSizes.tappableMin,
              child: _item(LucideIcons.circle_x, AppStrings.cancelAppointment, cs.error),
            ),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.iconSmall, color: color),
        const SizedBox(width: AppSizes.p8),
        Flexible(
          child: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: color)),
        ),
      ],
    );
  }
}
