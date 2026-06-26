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
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/payment_row.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/payment_summary_header.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

class PatientTabPayments extends ConsumerWidget {
  const PatientTabPayments({super.key, required this.patient});
  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider).value;
    final isDoctor = user?.role == UserRole.doctor;
    final isAdmin = user?.role == UserRole.superAdmin ||
        user?.role == UserRole.receptionist;
    final asyncPayments = ref.watch(patientPaymentsProvider(patient.id));

    return asyncPayments.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSizes.p16),
        child: SkeletonTileList(count: 4),
      ),
      error: (error, _) => ErrorView(
        exception: error is AppException
            ? error
            : const UnknownException(message: AppStrings.errorDatabaseQueryFailed),
        onRetry: () => ref.invalidate(patientPaymentsProvider(patient.id)),
      ),
      data: (payments) {
        final double totalSum =
            payments.fold(0.0, (sum, pmt) => sum + pmt.amount);

        return RefreshIndicator(
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
                  isDoctor: isDoctor,
                  patient: patient,
                ),
                const SizedBox(height: AppSizes.p24),
                if (payments.isEmpty)
                  EmptyState(
                    message: AppStrings.noPaymentsRecorded,
                    icon: Icons.receipt_long_outlined,
                    actionLabel: isDoctor ? null : AppStrings.recordPayment,
                    onActionPressed: isDoctor ? null : () => ref.invalidate(patientPaymentsProvider(patient.id)),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.p12),
                    child: Text(
                      AppStrings.paymentHistory,
                      style: AppTextStyles.headingSmall.copyWith(color: cs.onSurface),
                    ),
                  ),
                  ...payments.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final pmt = entry.value;
                    return PaymentRow(
                      payment: pmt,
                      isAdmin: isAdmin,
                      patientId: patient.id,
                    ).animate().fadeIn(duration: 250.ms, delay: (idx * 30).ms);
                  }),
                ],
              ],
            ).animate().fadeIn(duration: 350.ms),
          ),
        );
      },
    );
  }
}
