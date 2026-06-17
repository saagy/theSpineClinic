import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/collect_payment_sheet.dart';

class PaymentSummaryHeader extends StatelessWidget {
  const PaymentSummaryHeader({
    super.key,
    required this.totalPaid,
    required this.isDoctor,
    required this.patient,
    required this.isAdmin,
  });

  final double totalPaid;
  final bool isDoctor;
  final Patient patient;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Prominent balance container ──
        Container(
          padding: const EdgeInsets.all(AppSizes.p20),
          decoration: BoxDecoration(
            color: AppColors.successBg,
            borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
          ),
          child: Column(
            children: [
              Text(
                AppStrings.totalPaid,
                style: AppTextStyles.captionMedium.copyWith(color: AppColors.success),
              ),
              const SizedBox(height: AppSizes.p4),
              Text(
                totalPaid.toCurrencyString(),
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (!isDoctor) ...[
          const SizedBox(height: AppSizes.p16),
          SizedBox(
            width: double.infinity,
            child: _ActionButton(
              label: 'Record Payment',
              filled: true,
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => CollectPaymentSheet(patient: patient),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.filled, required this.onTap});
  final String label;
  final bool filled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return filled
        ? ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p24, vertical: AppSizes.p14),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      const BorderRadius.all(Radius.circular(AppSizes.r12))),
              elevation: 0,
            ),
            child: Text(label, style: AppTextStyles.button),
          )
        : OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p24, vertical: AppSizes.p14),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      const BorderRadius.all(Radius.circular(AppSizes.r12))),
            ),
            child: Text(label, style: AppTextStyles.bodyMedium),
          );
  }
}
