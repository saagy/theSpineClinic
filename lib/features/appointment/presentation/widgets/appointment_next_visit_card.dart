/// Read-only context card + Manage link for the patient's next visit
/// date on an appointment detail screen.
///
/// Tap on "Manage" pushes the patient detail screen, where the canonical
/// write surface (tappable Next-visit stat) lives.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';

/// Section card showing patient next expected visit context.
class AppointmentNextVisitContext extends StatelessWidget {
  const AppointmentNextVisitContext({
    super.key,
    required this.patient,
  });

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final clinic = ClinicColors.of(context);
    final DateTime? date = patient.nextVisitDate;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p8,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
        boxShadow: [clinic.cardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        child: InkWell(
          onTap: () => _openPatient(context),
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Row(
              children: [
                Icon(
                  Icons.event_repeat_rounded,
                  size: AppSizes.iconDefault,
                  color: cs.primary,
                ),
                const SizedBox(width: AppSizes.p12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppStrings.patientFollowUp,
                        style: AppTextStyles.captionMedium.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSizes.p2),
                      Text(
                        date == null
                            ? AppStrings.noNextVisitSet
                            : DateFormat('EEE, MMM d, yyyy').format(date),
                        style: date == null
                            ? AppTextStyles.bodySecondary.copyWith(
                                color: cs.onSurfaceVariant,
                              )
                            : AppTextStyles.bodyBold.copyWith(
                                color: cs.onSurface,
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.p12),
                Text(
                  AppStrings.manage,
                  style: AppTextStyles.bodyBold.copyWith(color: cs.primary),
                ),
                const SizedBox(width: AppSizes.p4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: AppSizes.iconDefault,
                  color: cs.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPatient(BuildContext context) {
    context.push(AppRoutes.patientDetail.replaceAll(':id', patient.id));
  }
}
