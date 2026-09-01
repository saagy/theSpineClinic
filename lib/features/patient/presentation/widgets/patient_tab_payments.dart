/// Payments tab — wallet-style balance card + standalone payment cards.
///
/// Rule 15/16 — all colours via Theme.of(context).colorScheme.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_payments_skeleton.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/payment_row.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/payment_summary_header.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';

class PatientTabPayments extends ConsumerWidget {
  const PatientTabPayments({super.key, required this.patient});
  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider).value;
    final bool canManagePayments = user?.canHandlePayments ?? false;
    final isMutating = ref.watch(recordPaymentControllerProvider).isLoading;
    final asyncPayments = ref.watch(patientPaymentsProvider(patient.id));

    final Widget content = asyncPayments.when(
      loading: () => const KeyedSubtree(
        key: ValueKey('payments_loading'),
        child: PatientPaymentsSkeleton(),
      ),
      error: (error, _) => KeyedSubtree(
        key: const ValueKey('payments_error'),
        child: ErrorView(
          exception: error is AppException
              ? error
              : const UnknownException(
                  message: AppStrings.errorDatabaseQueryFailed,
                ),
          onRetry: () => ref.invalidate(patientPaymentsProvider(patient.id)),
        ),
      ),
      data: (payments) {
        final double totalSum = payments.fold(
          0.0,
          (sum, pmt) => sum + pmt.amount,
        );
        final double totalOutstanding = payments.fold(
          0.0,
          (sum, pmt) => sum + pmt.remainingDue,
        );

        return KeyedSubtree(
          key: const ValueKey('payments_data'),
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(patientPaymentsProvider(patient.id));
              try {
                await ref.read(patientPaymentsProvider(patient.id).future);
              } catch (_) {}
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PaymentSummaryHeader(
                    totalPaid: totalSum,
                  totalOutstanding: totalOutstanding,
                  canManagePayments: canManagePayments,
                  patient: patient,
                ),
                const SizedBox(height: AppSizes.p24),
                if (payments.isEmpty)
                  EmptyState(
                    message: AppStrings.noPaymentsRecorded,
                    icon: Icons.receipt_long_outlined,
                    actionLabel: canManagePayments
                        ? AppStrings.recordPayment
                        : null,
                    onActionPressed: canManagePayments
                        ? () => ref.invalidate(
                            patientPaymentsProvider(patient.id),
                          )
                        : null,
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.p12),
                    child: Text(
                      AppStrings.paymentHistory,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  ...payments.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final pmt = entry.value;
                    return PaymentRow(
                      payment: pmt,
                      isAdmin: canManagePayments,
                      patientId: patient.id,
                    ).animate().fadeIn(duration: 250.ms, delay: (idx * 30).ms);
                  }),
                ],
              ],
            ).animate().fadeIn(duration: 350.ms),
          ),
        ),
      );
      },
    );

    return LoadingOverlay(
      isLoading: isMutating,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: content,
      ),
    );
  }
}
