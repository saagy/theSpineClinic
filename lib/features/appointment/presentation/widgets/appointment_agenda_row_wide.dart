import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_with_patient.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_menu.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_doctor_badge.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_status_action_badge.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_monogram_badge.dart';

/// Single-line appointment agenda row for PC / wide displays (>=650px).
class AppointmentAgendaWideRow extends StatelessWidget {
  const AppointmentAgendaWideRow({
    super.key,
    required this.item,
    required this.timeStr,
    required this.isCancelled,
    required this.isCheckingIn,
    required this.onCheckIn,
    required this.showDoctor,
    this.onStatusChanged,
  });

  final AppointmentWithPatient item;
  final String timeStr;
  final bool isCancelled;
  final bool isCheckingIn;
  final VoidCallback onCheckIn;
  final bool showDoctor;
  final VoidCallback? onStatusChanged;

  Widget _buildTypePill(ColorScheme cs, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p6, vertical: 1.5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(140),
        borderRadius: BorderRadius.circular(AppSizes.r4),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant, fontSize: 10.5, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appt = item.appointment;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(AppRoutes.appointmentDetail.replaceAll(':id', appt.id)),
        hoverColor: cs.primary.withAlpha(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 46.0),
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: 6.0),
          child: Row(
            children: [
              SizedBox(
                width: 76.0,
                child: Text(
                  timeStr,
                  style: AppTextStyles.bodyBold.copyWith(
                    color: isCancelled ? cs.onSurfaceVariant.withAlpha(120) : cs.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontSize: 13.0,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    PatientMonogramBadge(name: item.patient.fullName, size: 26.0),
                    const SizedBox(width: AppSizes.p8),
                    Expanded(
                      child: Text(
                        item.patient.fullName,
                        style: AppTextStyles.bodyBold.copyWith(
                          color: isCancelled ? cs.onSurfaceVariant.withAlpha(140) : cs.onSurface,
                          decoration: isCancelled ? TextDecoration.lineThrough : null,
                          fontSize: 14.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildTypePill(cs, appt.type.displayLabel),
                ),
              ),
              if (showDoctor) ...[
                const SizedBox(width: AppSizes.p12),
                Expanded(
                  flex: 4,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AppointmentDoctorBadge(
                      doctorNames: item.allDoctorNames,
                      fallbackDoctorName: item.doctorName,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: AppSizes.p12),
              SizedBox(
                width: 120.0,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AppointmentStatusActionBadge(
                    status: appt.status,
                    isCheckingIn: isCheckingIn,
                    onCheckIn: onCheckIn,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.p8),
              SizedBox(
                width: 36.0,
                child: AppointmentAgendaMenu(
                  appointmentId: appt.id,
                  patientId: item.patient.id,
                  status: appt.status,
                  onStatusChanged: onStatusChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
