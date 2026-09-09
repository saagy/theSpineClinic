import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart'
    show appointmentRepositoryProvider, canAccessAppointmentProvider;
import 'package:spine_clinic_app/features/appointment/presentation/appointment_refresh.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_schedule_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_appointments_notifier.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

enum _AgendaAction { viewDetails, edit, revert, restore, cancel }

/// Compact anchored popup menu for appointment row operations.
class AppointmentAgendaMenu extends ConsumerWidget {
  const AppointmentAgendaMenu({
    super.key,
    required this.appointmentId,
    required this.patientId,
    required this.status,
    this.onStatusChanged,
  });

  final String appointmentId;
  final String patientId;
  final AppointmentStatus status;
  final VoidCallback? onStatusChanged;

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, AppointmentStatus newStatus) async {
    if (ref.read(currentUserProvider).value?.isActive != true) return;
    ref.read(receptionistAppointmentsProvider.notifier).changeStatus(appointmentId, newStatus);
    ref.read(doctorScheduleProvider.notifier).changeStatus(appointmentId, newStatus);
    ref.read(allAppointmentsProvider.notifier).updateStatus(appointmentId, newStatus);
    ref.read(patientAppointmentsProvider(patientId).notifier).changeStatus(appointmentId, newStatus);

    final result = await ref
        .read(appointmentRepositoryProvider)
        .updateAppointmentStatus(appointmentId, newStatus);
    if (!context.mounted) return;

    result.when(
      success: (_) {
        AppointmentRefresh.patientAndDashboards(ref, patientId: patientId);
        onStatusChanged?.call();
        AppSnackbar.show(
          context,
          message: AppStrings.statusUpdateSuccess,
          variant: AppSnackbarVariant.success,
        );
      },
      failure: (err) {
        ref.read(receptionistAppointmentsProvider.notifier).changeStatus(appointmentId, status);
        ref.read(doctorScheduleProvider.notifier).changeStatus(appointmentId, status);
        ref.read(allAppointmentsProvider.notifier).updateStatus(appointmentId, status);
        AppSnackbar.show(
          context,
          message: AppStrings.fromKey(err.userMessageKey),
          variant: AppSnackbarVariant.error,
        );
      },
    );
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref, _AgendaAction action) async {
    switch (action) {
      case _AgendaAction.viewDetails:
        context.push(AppRoutes.appointmentDetail.replaceAll(':id', appointmentId));
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
    final isDoctor = user?.role == UserRole.doctor;

    final canAccess = isDoctor
        ? (ref
                  .watch(canAccessAppointmentProvider(appointmentId: appointmentId, patientId: patientId))
                  .value ??
              false)
        : (user?.role == UserRole.receptionist || user?.role == UserRole.superAdmin);
    final canEdit =
        user?.role == UserRole.receptionist || user?.role == UserRole.superAdmin || (isDoctor && canAccess);

    return PopupMenuButton<_AgendaAction>(
      tooltip: AppStrings.moreActions,
      icon: const Icon(LucideIcons.ellipsis_vertical, size: 16.0),
      color: cs.surface,
      elevation: 3,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36.0, minHeight: 36.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.r12),
        side: BorderSide(color: cs.outlineVariant.withAlpha(120), width: AppSizes.borderWidth),
      ),
      onSelected: (action) => _handleAction(context, ref, action),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _AgendaAction.viewDetails,
          height: AppSizes.buttonHeightSmall,
          child: _item(LucideIcons.file_text, AppStrings.viewDetails, cs.onSurface),
        ),
        if (canEdit && status != AppointmentStatus.cancelled)
          PopupMenuItem(
            value: _AgendaAction.edit,
            height: AppSizes.buttonHeightSmall,
            child: _item(LucideIcons.pencil, AppStrings.editAppointment, cs.onSurface),
          ),
        if (canAccess && status == AppointmentStatus.checkedIn)
          PopupMenuItem(
            value: _AgendaAction.revert,
            height: AppSizes.buttonHeightSmall,
            child: _item(LucideIcons.undo_2, AppStrings.revertToScheduled, cs.onSurface),
          ),
        if (canAccess && status == AppointmentStatus.cancelled)
          PopupMenuItem(
            value: _AgendaAction.restore,
            height: AppSizes.buttonHeightSmall,
            child: _item(LucideIcons.rotate_ccw, AppStrings.restoreAppointment, cs.onSurface),
          ),
        if (canAccess && status != AppointmentStatus.cancelled)
          PopupMenuItem(
            value: _AgendaAction.cancel,
            height: AppSizes.buttonHeightSmall,
            child: _item(LucideIcons.circle_x, AppStrings.cancelAppointment, cs.error),
          ),
      ],
    );
  }

  Widget _item(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16.0, color: color),
        const SizedBox(width: AppSizes.p8),
        Text(label, style: AppTextStyles.bodyMedium.copyWith(color: color)),
      ],
    );
  }
}
