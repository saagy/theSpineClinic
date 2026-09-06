import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_monogram_badge.dart';

/// High-density sleek list layout for mobile viewports (< 768px).
///
/// Features compact 2-line hairline rows (Name, Phone, Branch, Next Visit),
/// pull-to-refresh, infinite scroll loading, and direct tap navigation.
class PatientMobileList extends StatelessWidget {
  const PatientMobileList({
    super.key,
    required this.patients,
    required this.hasMore,
    required this.onRefresh,
    required this.onPatientTap,
    required this.scrollController,
  });

  final List<Patient> patients;
  final bool hasMore;
  final Future<void> Function() onRefresh;
  final ValueChanged<Patient> onPatientTap;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: cs.primary,
      child: ListView.separated(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
        itemCount: patients.length + (hasMore ? 1 : 0),
        separatorBuilder: (_, __) => Divider(
          height: AppSizes.borderWidth,
          thickness: AppSizes.borderWidth,
          indent: AppSizes.p16,
          endIndent: AppSizes.p16,
          color: cs.outlineVariant.withAlpha(80),
        ),
        itemBuilder: (context, index) {
          if (index >= patients.length) {
            return Padding(
              padding: const EdgeInsets.all(AppSizes.p16),
              child: Center(
                child: SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: cs.primary,
                  ),
                ),
              ),
            );
          }
          return _buildMobileRow(context, patients[index]);
        },
      ),
    );
  }

  Widget _buildMobileRow(BuildContext context, Patient patient) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => onPatientTap(patient),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p16,
          vertical: AppSizes.p10,
        ),
        child: Row(
          children: [
            PatientMonogramBadge(name: patient.fullName, size: 32.0),
            const SizedBox(width: AppSizes.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          patient.fullName,
                          style: AppTextStyles.bodyBold.copyWith(color: cs.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSizes.p6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.p6,
                          vertical: AppSizes.p2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withAlpha(140),
                          borderRadius: BorderRadius.circular(AppSizes.r4),
                        ),
                        child: Text(
                          patient.clinic.displayLabel,
                          style: AppTextStyles.captionBold.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.p2),
                  Row(
                    children: [
                      Text(
                        patient.phoneNumber,
                        style: AppTextStyles.caption.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      if (patient.nextVisitDate != null) ...[
                        Text(
                          '  •  ',
                          style: AppTextStyles.caption.copyWith(
                            color: cs.onSurfaceVariant.withAlpha(120),
                          ),
                        ),
                        Icon(
                          LucideIcons.calendar,
                          size: 11.0,
                          color: cs.primary,
                        ),
                        const SizedBox(width: AppSizes.p4),
                        Flexible(
                          child: Text(
                            Formatters.formatDateMedium(patient.nextVisitDate!),
                            style: AppTextStyles.caption.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 11.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.p8),
            Icon(
              LucideIcons.chevron_right,
              size: 16.0,
              color: cs.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}
