import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';
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

    // Mock payment records data.
    final List<Map<String, dynamic>> mockPayments = [
      {
        'date': '2026-06-01',
        'reason': 'Package (10 Sessions)',
        'amount': 'EGP 2,000.00',
      },
      {
        'date': '2026-05-25',
        'reason': 'Single Session',
        'amount': 'EGP 250.00',
      },
      {
        'date': '2026-05-18',
        'reason': 'Gehaz Shad Fakarat',
        'amount': 'EGP 300.00',
      },
    ];

    const String totalPaid = 'EGP 2,550.00';

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
                            // To be wired to RecordPaymentScreen in a future phase.
                          },
                        ),
                      ),
                      const SizedBox(width: AppSizes.p8),
                      Expanded(
                        child: AppButton(
                          labelText: 'Edit Balance',
                          variant: AppButtonVariant.secondary,
                          onPressed: () {
                            // To be wired to EditBalance dialog in a future phase.
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
            child: mockPayments.isEmpty
                ? const Center(child: Text('No payments recorded'))
                : Column(
                    children: mockPayments.map((pmt) {
                      return DataListTile(
                        title: pmt['reason'] as String,
                        subtitle: pmt['date'] as String,
                        trailing: Text(
                          pmt['amount'] as String,
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
  }
}
