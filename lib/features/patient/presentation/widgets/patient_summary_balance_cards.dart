import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/package_balance_edit_dialog.dart';

class PatientSummaryBalanceCards extends StatelessWidget {
  const PatientSummaryBalanceCards({super.key, required this.patient, required this.canEdit});

  final Patient patient;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSizes.p14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSizes.r12),
        border: Border.all(color: cs.outlineVariant.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  AppStrings.availableSessions,
                  style: AppTextStyles.captionBold.copyWith(color: cs.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canEdit)
                InkWell(
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => PackageBalanceEditDialog(patient: patient),
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.r4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.p4, vertical: AppSizes.p2),
                    child: Text(AppStrings.edit, style: AppTextStyles.captionBold.copyWith(color: cs.primary)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.p12),
          Row(
            children: [
              Expanded(child: _kpiTile(context, cs, AppStrings.ptSessions, patient.sessionBalance)),
              const SizedBox(width: AppSizes.p10),
              Expanded(child: _kpiTile(context, cs, AppStrings.spinalTraction, patient.tractionBalance)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiTile(BuildContext context, ColorScheme cs, String label, int balance) {
    final isNegative = balance < 0;
    final isPositive = balance > 0;
    final statusColor = isNegative ? cs.error : (isPositive ? cs.primary : cs.onSurfaceVariant);

    return Container(
      padding: const EdgeInsets.all(AppSizes.p10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.r8),
        border: Border.all(color: isNegative ? cs.error.withAlpha(80) : cs.outlineVariant.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant, fontSize: 11), maxLines: 1),
          const SizedBox(height: AppSizes.p4),
          Row(
            children: [
              Text('$balance', style: AppTextStyles.headingSmall.copyWith(color: statusColor, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
