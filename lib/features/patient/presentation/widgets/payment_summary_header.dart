/// Wallet-style balance card for the payments tab.
///
/// Rule 15/16 — all colours via Theme.of(context).colorScheme.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/collect_payment_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

class PaymentSummaryHeader extends StatelessWidget {
  const PaymentSummaryHeader({
    super.key,
    required this.totalPaid,
    required this.isDoctor,
    required this.patient,
  });
  final double totalPaid;
  final bool isDoctor;
  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.p20),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withAlpha(40),
            borderRadius: BorderRadius.circular(AppSizes.r16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            children: [
              Text(
                AppStrings.totalPaid,
                style: AppTextStyles.captionMedium.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: AppSizes.p4),
              Text(
                totalPaid.toCurrencyString(),
                style: AppTextStyles.numberLarge.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (!isDoctor) ...[
          const SizedBox(height: AppSizes.p16),
          AppButton(
            labelText: AppStrings.recordPayment,
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r16)),
              ),
              builder: (_) => CollectPaymentSheet(patient: patient),
            ),
            shape: AppButtonShape.pill,
          ),
        ],
      ],
    );
  }
}
