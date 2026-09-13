import 'package:spine_clinic_app/shared/widgets/adaptive_name_text.dart';
import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_with_patient.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_menu.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_status_indicator.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_monogram_badge.dart';

/// Compact two-line appointment agenda row for mobile (<650px).
class AppointmentAgendaCompactRow extends StatelessWidget {
  const AppointmentAgendaCompactRow({
    super.key,
    required this.item,
    required this.timeStr,
    required this.isCancelled,
    required this.isCheckingIn,
    required this.showDoctor,
    this.patientContext = false,
    this.showDate = false,
  });

  final AppointmentWithPatient item;
  final String timeStr;
  final bool isCancelled;
  final bool isCheckingIn;
  final bool showDoctor;
  final bool patientContext;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appt = item.appointment;
    final identity = patientContext
        ? (item.allDoctorNames.isNotEmpty
              ? item.allDoctorNames.join(', ')
              : item.doctorName ?? AppStrings.noDoctorsAssigned)
        : item.patient.fullName;

    final enlarged = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final inlineTime = !showDate && !enlarged;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => context.push(AppRoutes.appointmentDetail.replaceAll(':id', appt.id)),
        hoverColor: cs.primary.withAlpha(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.agendaRowMinHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12, vertical: AppSizes.p8),
          child: Row(
            children: [
              if (inlineTime) ...[
                SizedBox(
                  width: AppSizes.agendaCompactTimeWidth,
                  child: Text(
                    timeStr,
                    style: AppTextStyles.captionBold.copyWith(color: cs.onSurface),
                  ),
                ),
                const SizedBox(width: AppSizes.p6),
              ],
              if (!enlarged) ...[
                PatientMonogramBadge(name: identity, size: AppSizes.agendaAvatarSize),
                const SizedBox(width: AppSizes.p8),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdaptiveNameText(
                      identity,
                      style: AppTextStyles.bodyBold.copyWith(
                        color: isCancelled ? cs.onSurfaceVariant : cs.onSurface,
                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (showDate || !inlineTime)
                      Text(
                        showDate
                            ? '${Formatters.formatDateMedium(appt.scheduledAt.toLocal())} \u00b7 $timeStr'
                            : timeStr,
                        style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
                      ),
                    Text(
                      appt.type.displayLabel,
                      style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.p4),
              AppointmentStatusIndicator(status: appt.status, pending: isCheckingIn),
              AppointmentAgendaMenu(
                appointmentId: appt.id,
                patientId: item.patient.id,
                status: appt.status,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
