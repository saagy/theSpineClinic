import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/collect_payment_sheet.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/package_balance_edit_dialog.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/payment_row.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Renders payment records and summary details for a patient.
class PatientTabPayments extends ConsumerWidget {
  /// Creates a [PatientTabPayments].
  const PatientTabPayments({super.key, required this.patient});

  /// The patient entity.
  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final isDoctor = user?.role == UserRole.doctor;
    final isAdmin = user?.role == UserRole.superAdmin;

    final asyncPayments = ref.watch(patientPaymentsProvider(patient.id));

    return asyncPayments.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.p24),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, _) => ErrorView(
        exception: error is AppException
            ? error
            : const UnknownException(message: AppStrings.errorDatabaseQueryFailed),
        onRetry: () => ref.invalidate(patientPaymentsProvider(patient.id)),
      ),
      data: (payments) {
        final double totalSum = payments.fold(0.0, (sum, pmt) => sum + pmt.amount);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PaymentSummaryHeader(
                totalPaid: totalSum,
                isDoctor: isDoctor,
                patient: patient,
                isAdmin: isAdmin,
              ),
              const SizedBox(height: AppSizes.p16),
              SectionCard(
                title: AppStrings.paymentHistory,
                child: payments.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSizes.p24),
                          child: Text(AppStrings.noPaymentsRecorded),
                        ),
                      )
                    : Column(
                        children: payments.map((pmt) {
                          return PaymentRow(
                            payment: pmt,
                            isAdmin: isAdmin,
                            patientId: patient.id,
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PaymentSummaryHeader extends StatelessWidget {
  const _PaymentSummaryHeader({
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
          child: Column(children: [
            Text(AppStrings.totalPaid,
                style: AppTextStyles.captionMedium.copyWith(color: AppColors.success)),
            const SizedBox(height: AppSizes.p4),
            Text(totalPaid.toCurrencyString(),
                style: AppTextStyles.headingLarge.copyWith(
                    color: AppColors.success, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        if (!isDoctor) ...[
          const SizedBox(height: AppSizes.p16),
          Row(
            children: [
              Expanded(
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
              const SizedBox(width: AppSizes.p12),
              Expanded(
                child: _ActionButton(
                  label: AppStrings.editPackageBalance,
                  filled: false,
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) =>
                        PackageBalanceEditDialog(patient: patient),
                  ),
                ),
              ),
            ],
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
            child: Text(label, style: AppTextStyles.bodyBold),
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