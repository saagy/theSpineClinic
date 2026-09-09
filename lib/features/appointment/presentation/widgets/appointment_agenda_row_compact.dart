import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_with_patient.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_menu.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_status_action_badge.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_monogram_badge.dart';

/// Compact two-line appointment agenda row for mobile (<650px).
class AppointmentAgendaCompactRow extends StatelessWidget {
  const AppointmentAgendaCompactRow({
    super.key,
    required this.item,
    required this.timeStr,
    required this.isCancelled,
    required this.isCheckingIn,
    required this.onCheckIn,
    required this.showDoctor,
    this.onStatusChanged,
    this.patientContext = false,
    this.showDate = false,
  });

  final AppointmentWithPatient item;
  final String timeStr;
  final bool isCancelled;
  final bool isCheckingIn;
  final VoidCallback onCheckIn;
  final bool showDoctor;
  final VoidCallback? onStatusChanged;
  final bool patientContext;
  final bool showDate;

  Widget _buildTypePill(ColorScheme cs, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p6, vertical: 1.5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(140),
        borderRadius: BorderRadius.circular(AppSizes.r4),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: cs.onSurfaceVariant,
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appt = item.appointment;
    final identity = patientContext
        ? (item.allDoctorNames.isNotEmpty
              ? item.allDoctorNames.join(', ')
              : item.doctorName ?? AppStrings.noDoctorsAssigned)
        : item.patient.fullName;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(AppRoutes.appointmentDetail.replaceAll(':id', appt.id)),
        hoverColor: cs.primary.withAlpha(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52.0),
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!showDate)
                SizedBox(
                  width: 62.0,
                  child: Text(
                    timeStr,
                    style: AppTextStyles.bodyBold.copyWith(
                      color: isCancelled ? cs.onSurfaceVariant.withAlpha(120) : cs.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontSize: 12.0,
                    ),
                  ),
                ),
              if (!showDate) const SizedBox(width: AppSizes.p6),
              PatientMonogramBadge(name: identity, size: 26.0),
              const SizedBox(width: AppSizes.p8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      identity,
                      style: AppTextStyles.bodyBold.copyWith(
                        color: isCancelled ? cs.onSurfaceVariant.withAlpha(140) : cs.onSurface,
                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                        fontSize: 13.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2.0),
                    if (showDate)
                      Text(
                        '${Formatters.formatDateMedium(appt.scheduledAt.toLocal())} · $timeStr',
                        style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
                      ),
                    _buildTypePill(cs, appt.type.displayLabel),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.p4),
              AppointmentStatusActionBadge(
                status: appt.status,
                isCheckingIn: isCheckingIn,
                onCheckIn: onCheckIn,
                isInline: true,
              ),
              const SizedBox(width: AppSizes.p2),
              AppointmentAgendaMenu(
                appointmentId: appt.id,
                patientId: item.patient.id,
                status: appt.status,
                onStatusChanged: onStatusChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
