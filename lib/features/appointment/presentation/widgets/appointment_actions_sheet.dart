library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_badge.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Modal bottom sheet actions panel allowing receptionists and admins to transit
/// the status of an appointment.
class AppointmentActionsSheet extends ConsumerStatefulWidget {
  /// Creates an [AppointmentActionsSheet] modal block.
  const AppointmentActionsSheet({super.key, required this.appointment});

  /// The appointment entity to target.
  final Appointment appointment;

  @override
  ConsumerState<AppointmentActionsSheet> createState() => _AppointmentActionsSheetState();
}

class _AppointmentActionsSheetState extends ConsumerState<AppointmentActionsSheet> {
  bool _isLoading = false;

  Future<void> _updateStatus(AppointmentStatus targetStatus) async {
    setState(() => _isLoading = true);

    final result = await ref
        .read(appointmentRepositoryProvider)
        .updateAppointmentStatus(widget.appointment.id, targetStatus);

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.when(
      success: (_) {
        ref.invalidate(todayAppointmentsProvider);
        ref.invalidate(patientAppointmentsProvider(widget.appointment.patientId));
        ref.invalidate(patientDetailProvider(widget.appointment.patientId));
        Navigator.pop(context);
        AppSnackbar.show(
          context,
          message: AppStrings.statusUpdateSuccess,
          variant: AppSnackbarVariant.success,
        );
      },
      failure: (error) {
        AppSnackbar.show(
          context,
          message: AppStrings.fromKey(error.userMessageKey),
          variant: AppSnackbarVariant.error,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    final String timeStr = Formatters.formatTime(appointment.scheduledAt);

    return LoadingOverlay(
      isLoading: _isLoading,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionCard(
                child: Row(
                  children: [
                    Text(
                      timeStr,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSizes.p12),
                    AppBadge(
                      label: appointment.type.displayLabel,
                      textColor: appointment.type.textColor,
                      backgroundColor: appointment.type.backgroundColor,
                    ),
                    const Spacer(),
                    AppBadge(
                      label: appointment.status.displayLabel,
                      textColor: appointment.status.textColor,
                      backgroundColor: appointment.status.backgroundColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.p16),
              if (appointment.status == AppointmentStatus.scheduled) ...[
                AppButton(
                  labelText: AppStrings.checkInPatient,
                  onPressed: () => _updateStatus(AppointmentStatus.checkedIn),
                ),
                const SizedBox(height: AppSizes.p12),
                AppButton(
                  labelText: AppStrings.cancelAppointment,
                  variant: AppButtonVariant.danger,
                  onPressed: () => _updateStatus(AppointmentStatus.cancelled),
                ),
              ] else if (appointment.status == AppointmentStatus.checkedIn) ...[
                AppButton(
                  labelText: AppStrings.markAsCompleted,
                  onPressed: () => _updateStatus(AppointmentStatus.completed),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(AppSizes.p16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    AppStrings.historicalNote,
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
