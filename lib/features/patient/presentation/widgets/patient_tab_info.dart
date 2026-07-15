/// Info tab for the patient profile.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_appointments_notifier.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_next_visit_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_info_assigned_doctors_section.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_info_contact_section.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_info_package_balance_section.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_info_stats_strip.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_next_visit_options_sheet.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

class PatientTabInfo extends ConsumerWidget {
  const PatientTabInfo({super.key, required this.patient});

  static const int _appointmentsTabIndex = 1;
  static const int _paymentsTabIndex = 3;

  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final bool isDoctor = user?.role == UserRole.doctor;
    final apptState = ref.watch(patientAppointmentsProvider(patient.id));
    final paymentsAsync = ref.watch(patientPaymentsProvider(patient.id));
    final doctorsAsync = ref.watch(patientAssignedDoctorsProvider(patient.id));
    final nextVisitState = ref.watch(patientNextVisitControllerProvider);
    final double amountDue =
        paymentsAsync.value?.fold<double>(
          0.0,
          (sum, payment) => sum + payment.remainingDue,
        ) ??
        0.0;
    final DateTime? nextVisitDate = patient.nextVisitDate;
    final bool canEditNextVisit = user?.isActive == true;
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final bool nextVisitInPast = nextVisitDate != null &&
        DateUtils.dateOnly(nextVisitDate).isBefore(today);

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
              nextVisitText: nextVisitDate != null
                  ? Formatters.formatDateMedium(nextVisitDate)
                  : AppStrings.noNextVisitSet,
              nextVisitSet: nextVisitDate != null,
              nextVisitIsMutating: nextVisitState.isMutating,
              nextVisitInPast: nextVisitInPast,
              amountDue: amountDue,
              paymentsLoading: paymentsAsync.isLoading,
              isDoctor: isDoctor,
              onAppointmentsTap: () =>
                  _animateToTab(context, _appointmentsTabIndex),
              onNextVisitTap: canEditNextVisit
                  ? () => _handleNextVisitTap(context, ref)
                  : () {
                      AppSnackbar.show(
                        context,
                        message: AppStrings.nextVisit,
                        variant: AppSnackbarVariant.info,
                      );
                    },
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

  Future<void> _handleNextVisitTap(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (patient.nextVisitDate == null) {
      await _openDatePicker(context, ref);
      return;
    }
    final NextVisitAction? action =
        await NextVisitOptionsSheet.show(context);
    if (action == null || !context.mounted) return;
    switch (action) {
      case NextVisitAction.change:
        await _openDatePicker(context, ref);
      case NextVisitAction.clear:
        await _confirmClear(context, ref);
    }
  }

  Future<void> _openDatePicker(BuildContext context, WidgetRef ref) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: patient.nextVisitDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)),
      helpText: AppStrings.setNextVisit,
    );
    if (picked == null) return;
    if (!context.mounted) return;
    final result = await ref
        .read(patientNextVisitControllerProvider.notifier)
        .setNextVisit(patient.id, picked);
    if (!context.mounted) return;
    _showMutationResult(context, result);
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: AppStrings.clearFollowUpTitle,
        message: AppStrings.clearFollowUpConfirmBody(patient.fullName),
        confirmLabel: AppStrings.clearNextVisit,
        isDestructive: true,
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await ref
        .read(patientNextVisitControllerProvider.notifier)
        .clearNextVisit(patient.id);
    if (!context.mounted) return;
    _showMutationResult(context, result);
  }

  void _showMutationResult(BuildContext context, Result<void> result) {
    result.when(
      success: (_) => AppSnackbar.show(
        context,
        message: AppStrings.nextVisitUpdated,
        variant: AppSnackbarVariant.success,
      ),
      failure: (error) => AppSnackbar.show(
        context,
        message: AppStrings.fromKey(error.userMessageKey),
        variant: AppSnackbarVariant.error,
      ),
    );
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
