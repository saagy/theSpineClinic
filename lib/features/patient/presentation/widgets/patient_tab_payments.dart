import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/payment_row.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/payment_summary_header.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

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
        final double totalSum = payments.fold(0.0, (sum, pmt) => sum + pmt.amount);

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(patientPaymentsProvider(patient.id));
            try {
              await ref.read(patientPaymentsProvider(patient.id).future);
            } catch (_) {
              // Ignore failure for refresh indicator UI
            }
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
                          children: payments.asMap().entries.map((entry) {
                            final int idx = entry.key;
                            final pmt = entry.value;
                            return PaymentRow(
                              payment: pmt,
                              isAdmin: isAdmin,
                              patientId: patient.id,
                            ).animate().fadeIn(
                                  duration: 250.ms,
                                  delay: (idx * 30).ms,
                                );
                          }).toList(),
                        ),
                ),
              ],
            ).animate().fadeIn(duration: 350.ms),
          ),
        );
      },
    );
  }
}