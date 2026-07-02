/// Info tab for the patient profile.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_appointments_notifier.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_info_assigned_doctors_section.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_info_contact_section.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_info_package_balance_section.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_info_stats_strip.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';

class PatientTabInfo extends ConsumerWidget {
  const PatientTabInfo({super.key, required this.patient});

  static const int _appointmentsTabIndex = 1;
  static const int _paymentsTabIndex = 3;
  static const String _emptyValue = '-';

  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final bool isDoctor = user?.role == UserRole.doctor;
    final apptState = ref.watch(patientAppointmentsProvider(patient.id));
    final paymentsAsync = ref.watch(patientPaymentsProvider(patient.id));
    final doctorsAsync = ref.watch(patientAssignedDoctorsProvider(patient.id));
    final double amountDue =
        paymentsAsync.value?.fold<double>(
          0.0,
          (sum, payment) => sum + payment.remainingDue,
        ) ??
        0.0;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(patientDetailProvider(patient.id));
        ref.invalidate(patientAssignedDoctorsProvider(patient.id));
        ref.invalidate(patientPaymentsProvider(patient.id));
        ref.read(patientAppointmentsProvider(patient.id).notifier).refresh();
        try {
          await ref.read(patientPaymentsProvider(patient.id).future);
        } catch (_) {}
      },
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PatientInfoStatsStrip(
              apptCount: apptState.totalCount,
              apptLoading: apptState.isLoading,
              lastVisitText: patient.lastAppointmentDate != null
                  ? Formatters.formatDateMedium(patient.lastAppointmentDate!)
                  : _emptyValue,
              amountDue: amountDue,
              paymentsLoading: paymentsAsync.isLoading,
              isDoctor: isDoctor,
              onAppointmentsTap: () =>
                  _animateToTab(context, _appointmentsTabIndex),
              onPaymentsTap: isDoctor
                  ? null
                  : () => _animateToTab(context, _paymentsTabIndex),
            ),
            const _FullWidthHairline(),
            const SizedBox(height: AppSizes.p24),
            PatientInfoContactSection(patient: patient),
            const SizedBox(height: AppSizes.p24),
            const _HairlineDivider(),
            const SizedBox(height: AppSizes.p24),
            PatientInfoAssignedDoctorsSection(doctorsAsync: doctorsAsync),
            const SizedBox(height: AppSizes.p24),
            const _HairlineDivider(),
            const SizedBox(height: AppSizes.p24),
            PatientInfoPackageBalanceSection(
              patient: patient,
              isDoctor: isDoctor,
            ),
            const SizedBox(height: AppSizes.p24),
          ],
        ),
      ),
    );
  }

  void _animateToTab(BuildContext context, int index) {
    DefaultTabController.maybeOf(context)?.animateTo(index);
  }
}

class _FullWidthHairline extends StatelessWidget {
  const _FullWidthHairline();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.outlineVariant,
      child: const SizedBox(height: AppSizes.borderWidth),
    );
  }
}

class _HairlineDivider extends StatelessWidget {
  const _HairlineDivider();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
      child: ColoredBox(
        color: cs.outlineVariant,
        child: const SizedBox(height: AppSizes.borderWidth),
      ),
    );
  }
}
