import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/package_balance_edit_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
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
        final String totalPaid = totalSum.toCurrencyString();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Total Paid summary banner.
              SectionCard(
                title: 'Payment Summary',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Paid',
                          style: AppTextStyles.bodySecondary,
                        ),
                        Text(
                          totalPaid,
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
                              labelText: 'Record Payment',
                              onPressed: () {
                                context.push(
                                  AppRoutes.recordPayment.replaceAll(':id', patient.id),
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
                                  builder: (BuildContext context) =>
                                      PackageBalanceEditDialog(patient: patient),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.p16),
              // List of payment records.
              SectionCard(
                title: 'Payment History',
                child: payments.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSizes.p24),
                          child: Text('No payments recorded'),
                        ),
                      )
                    : Column(
                        children: payments.map((pmt) {
                          return DataListTile(
                            title: pmt.reason,
                            subtitle: pmt.recordedAt.toDateTimeString(),
                            trailing: Text(
                              pmt.amount.toCurrencyString(),
                              style: AppTextStyles.bodyBold.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            transparent: true,
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
