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
import 'package:spine_clinic_app/features/patient/presentation/widgets/package_balance_edit_dialog.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/quick_payment_sheet.dart';
import 'package:spine_clinic_app/features/payments/domain/payment_record.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';
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
                          return _PaymentRow(
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
    return SectionCard(
      title: AppStrings.paymentSummary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.totalPaid, style: AppTextStyles.bodySecondary),
              Text(
                totalPaid.toCurrencyString(),
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          if (!isDoctor) ...[
            const SizedBox(height: AppSizes.p16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    labelText: AppStrings.quickPayment,
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(AppSizes.r12),
                          ),
                        ),
                        builder: (_) => QuickPaymentSheet(patientId: patient.id),
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.p8),
                Expanded(
                  child: AppButton(
                    labelText: AppStrings.editPackageBalance,
                    variant: AppButtonVariant.secondary,
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (_) => PackageBalanceEditDialog(patient: patient),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentRow extends ConsumerWidget {
  const _PaymentRow({
    required this.payment,
    required this.isAdmin,
    required this.patientId,
  });

  final PaymentRecord payment;
  final bool isAdmin;
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DataListTile(
      title: payment.reason,
      subtitle: payment.recordedAt.toDateTimeString(),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            payment.amount.toCurrencyString(),
            style: AppTextStyles.bodyBold.copyWith(color: AppColors.textPrimary),
          ),
          if (isAdmin) ...[
            const SizedBox(width: AppSizes.p4),
            GestureDetector(
              onTap: () => _confirmDelete(context, ref),
              child: const Icon(Icons.delete_outline_rounded,
                  size: AppSizes.iconSmall, color: AppColors.error),
            ),
          ],
        ],
      ),
      transparent: true,
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(
        title: AppStrings.deletePayment,
        message: AppStrings.confirmDeletePayment,
        confirmLabel: AppStrings.delete,
        cancelLabel: AppStrings.cancel,
        isDestructive: true,
      ),
    );
    if (confirm == true && context.mounted) {
      final repo = ref.read(paymentRepositoryProvider);
      final result = await repo.deletePayment(payment.id);
      if (context.mounted) {
        result.when(
          success: (_) {
            AppSnackbar.show(context,
                message: AppStrings.paymentDeleted,
                variant: AppSnackbarVariant.success);
            ref.invalidate(patientPaymentsProvider(patientId));
          },
          failure: (error) {
            AppSnackbar.show(context,
                message: error.message, variant: AppSnackbarVariant.error);
          },
        );
      }
    }
  }
}
