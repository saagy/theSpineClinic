import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/payments/domain/patient_payment_summary.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';

class WorkspaceDue extends ConsumerWidget {
  const WorkspaceDue({super.key, required this.patientId, required this.onOpen});
  final String patientId;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(currentUserProvider).value?.role == UserRole.doctor) return const SizedBox.shrink();
    final attention = Theme.of(context).extension<ClinicColors>()!;
    final provider = patientPaymentsProvider(patientId);
    return RecordAsync(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      data: (records) {
        final summary = PatientPaymentSummary(records);
        if (summary.totalDue <= 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.p24),
          child: Material(
            color: attention.warningContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.r8),
              side: BorderSide(color: attention.warning),
            ),
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(AppSizes.r8),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.p16),
                child: Row(
                  children: [
                    Icon(LucideIcons.wallet, size: AppSizes.iconDefault, color: attention.warning),
                    const SizedBox(width: AppSizes.p12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.totalOutstanding, style: AppTextStyles.caption),
                          const SizedBox(height: AppSizes.p4),
                          Text(
                            Formatters.formatCurrency(summary.totalDue),
                            style: AppTextStyles.numberLarge.copyWith(color: attention.warning),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.p12),
                    Text(
                      AppStrings.viewAll,
                      style: AppTextStyles.captionBold.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: AppSizes.p8),
                    const Icon(LucideIcons.chevron_right, size: AppSizes.iconSmall),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
