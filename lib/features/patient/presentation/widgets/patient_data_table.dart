import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_monogram_badge.dart';

/// High-density modern SaaS data table for desktop viewports (>= 768px).
class PatientDataTable extends StatelessWidget {
  const PatientDataTable({
    super.key,
    required this.patients,
    required this.onPatientTap,
  });

  final List<Patient> patients;
  final ValueChanged<Patient> onPatientTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        _buildHeader(cs),
        Expanded(
          child: ListView.separated(
            itemCount: patients.length,
            separatorBuilder: (_, __) => Divider(
              height: AppSizes.borderWidth,
              thickness: AppSizes.borderWidth,
              color: cs.outlineVariant.withAlpha(80),
            ),
            itemBuilder: (context, index) => _buildRow(context, patients[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Container(
      height: 44.0,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(100),
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withAlpha(140),
            width: AppSizes.borderWidth,
          ),
        ),
      ),
      child: Row(
        children: [
          _headerCell(AppStrings.patientColName, flex: 5, cs: cs),
          _headerCell(AppStrings.patientColBranch, flex: 3, cs: cs),
          _headerCell(AppStrings.patientColNextVisit, flex: 4, cs: cs),
          const SizedBox(width: 24.0),
        ],
      ),
    );
  }

  Widget _headerCell(String title, {required int flex, required ColorScheme cs}) {
    return Expanded(
      flex: flex,
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.captionBold.copyWith(
          color: cs.onSurfaceVariant,
          letterSpacing: 0.8,
          fontSize: 11.0,
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, Patient patient) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onPatientTap(patient),
        hoverColor: cs.primary.withAlpha(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52.0),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p20,
            vertical: AppSizes.p8,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    PatientMonogramBadge(name: patient.fullName, size: 32.0),
                    const SizedBox(width: AppSizes.p12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            patient.fullName,
                            style: AppTextStyles.bodyBold.copyWith(
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSizes.p2),
                          Text(
                            patient.phoneNumber,
                            style: AppTextStyles.caption.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p8,
                      vertical: AppSizes.p4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withAlpha(120),
                      borderRadius: BorderRadius.circular(AppSizes.r4),
                    ),
                    child: Text(
                      patient.clinic.displayLabel,
                      style: AppTextStyles.captionBold.copyWith(
                        color: cs.onSurface,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (patient.nextVisitDate != null) ...[
                      Icon(
                        LucideIcons.calendar,
                        size: 13.0,
                        color: cs.primary,
                      ),
                      const SizedBox(width: AppSizes.p6),
                    ],
                    Flexible(
                      child: Text(
                        patient.nextVisitDate != null
                            ? Formatters.formatDateMedium(patient.nextVisitDate!)
                            : AppStrings.noUpcomingVisit,
                        style: AppTextStyles.caption.copyWith(
                          color: patient.nextVisitDate != null
                              ? cs.onSurface
                              : cs.onSurfaceVariant.withAlpha(140),
                          fontWeight: patient.nextVisitDate != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevron_right,
                size: 16.0,
                color: cs.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
