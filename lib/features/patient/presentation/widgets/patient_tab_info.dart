/// Dashboard-style Info tab for the patient detail screen.
///
/// Sections: Quick Stats Strip → Contact → Assigned Doctors → Package Balance
///
/// Rule 15/16 — all colours via Theme.of(context).colorScheme.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_appointments_notifier.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/package_balance_edit_dialog.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

class PatientTabInfo extends ConsumerWidget {
  const PatientTabInfo({super.key, required this.patient});
  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final isDoctor = user?.role == UserRole.doctor;
    final apptState = ref.watch(patientAppointmentsProvider(patient.id));
    final paymentsAsync = ref.watch(patientPaymentsProvider(patient.id));
    final doctorsAsync = ref.watch(patientAssignedDoctorsProvider(patient.id));
    final totalPaid = paymentsAsync.value
            ?.fold(0.0, (sum, p) => sum + p.amount) ??
        0.0;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(patientDetailProvider(patient.id));
        ref.invalidate(patientAssignedDoctorsProvider(patient.id));
        ref.read(patientAppointmentsProvider(patient.id).notifier).refresh();
        try {
          await ref.read(patientPaymentsProvider(patient.id).future);
        } catch (_) {}
      },
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _QuickStatsStrip(
              apptCount: apptState.totalCount,
              apptLoading: apptState.isLoading,
              lastVisit: patient.lastAppointmentDate,
              totalPaid: totalPaid,
              paymentsLoading: paymentsAsync.isLoading,
              isDoctor: isDoctor,
              onTapAppointments: () =>
                  DefaultTabController.of(context).animateTo(1),
              onTapPayments: isDoctor
                  ? null
                  : () => DefaultTabController.of(context).animateTo(3),
            ),
            const SizedBox(height: AppSizes.p16),
            _ContactSection(patient: patient),
            const SizedBox(height: AppSizes.p16),
            _AssignedDoctorsCard(doctorsAsync: doctorsAsync),
            const SizedBox(height: AppSizes.p16),
            _PackageBalanceCard(patient: patient, isDoctor: isDoctor),
          ],
        ),
      ),
    );
  }
}

class _QuickStatsStrip extends StatelessWidget {
  const _QuickStatsStrip({
    required this.apptCount,
    required this.apptLoading,
    required this.lastVisit,
    required this.totalPaid,
    required this.paymentsLoading,
    required this.isDoctor,
    required this.onTapAppointments,
    required this.onTapPayments,
  });
  final int apptCount;
  final bool apptLoading;
  final DateTime? lastVisit;
  final double totalPaid;
  final bool paymentsLoading;
  final bool isDoctor;
  final VoidCallback onTapAppointments;
  final VoidCallback? onTapPayments;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: apptLoading ? '—' : '$apptCount',
            label: AppStrings.totalAppointments,
            icon: Icons.calendar_today_rounded,
            onTap: onTapAppointments,
          ),
        ),
        const SizedBox(width: AppSizes.p12),
        Expanded(
          child: _StatCard(
            value: lastVisit != null
                ? Formatters.formatDateMedium(lastVisit!)
                : '—',
            label: AppStrings.lastVisit,
            icon: Icons.event_available_rounded,
          ),
        ),
        if (!isDoctor) ...[
          const SizedBox(width: AppSizes.p12),
          Expanded(
            child: _StatCard(
              value: paymentsLoading ? '—' : totalPaid.toCurrencyString(),
              label: AppStrings.totalPaid,
              icon: Icons.payments_rounded,
              onTap: onTapPayments,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    this.onTap,
  });
  final String value;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(AppSizes.r16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.r16),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.p16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.r16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: cs.primary, size: AppSizes.iconDefault),
              const SizedBox(height: AppSizes.p8),
              Text(
                value,
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.p4),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection({required this.patient});
  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: AppStrings.contact,
      child: Column(
        children: [
          _ContactRow(
            icon: Icons.phone_outlined,
            label: AppStrings.phone,
            value: patient.phoneNumber,
          ),
          const SizedBox(height: AppSizes.p12),
          _ContactRow(
            icon: Icons.local_hospital_outlined,
            label: AppStrings.clinic,
            value: patient.clinic.displayLabel,
          ),
          const SizedBox(height: AppSizes.p12),
          _ContactRow(
            icon: Icons.medical_services_outlined,
            label: AppStrings.program,
            value: patient.program ?? AppStrings.programNone,
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: AppSizes.iconDefault, color: cs.primary),
        const SizedBox(width: AppSizes.p12),
        Text(label, style: AppTextStyles.bodySecondary.copyWith(color: cs.onSurfaceVariant)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodyBold,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _AssignedDoctorsCard extends StatelessWidget {
  const _AssignedDoctorsCard({required this.doctorsAsync});
  final AsyncValue<List<Staff>> doctorsAsync;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: AppStrings.assignedDoctors,
      child: doctorsAsync.when(
        data: (doctors) => doctors.isEmpty
            ? const EmptyState(
                message: AppStrings.noDoctorsAssigned,
                icon: Icons.person_off_outlined,
              )
            : Column(
                children: doctors.map((doc) => _DoctorRow(doc: doc)).toList(),
              ),
        loading: () => const SkeletonListTile(),
        error: (_, __) => ErrorView(
          exception: UnknownException(
              message: AppStrings.errorLoadingAssignedDoctors),
        ),
      ),
    );
  }
}

class _DoctorRow extends StatelessWidget {
  const _DoctorRow({required this.doc});
  final Staff doc;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p6),
      child: Row(
        children: [
          AppAvatar(name: doc.fullName, radius: AppSizes.avatarSmall / 2),
          const SizedBox(width: AppSizes.p12),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    doc.fullName,
                    style: AppTextStyles.bodyBold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!doc.isActive) ...[
                  const SizedBox(width: AppSizes.p8),
                  Text(
                    AppStrings.deactivated,
                    style: AppTextStyles.caption.copyWith(
                      color: cs.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageBalanceCard extends StatelessWidget {
  const _PackageBalanceCard({required this.patient, required this.isDoctor});
  final Patient patient;
  final bool isDoctor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      title: AppStrings.packageBalance,
      action: isDoctor
          ? null
          : TextButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => PackageBalanceEditDialog(patient: patient),
              ),
              icon: Icon(Icons.edit_outlined, size: AppSizes.iconSmall, color: cs.primary),
              label: Text(AppStrings.edit, style: TextStyle(color: cs.primary)),
            ),
      child: Row(
        children: [
          Expanded(
            child: _BalanceNumber(
              label: AppStrings.ptSessionsBucket,
              value: patient.sessionBalance,
              positiveColor: cs.primary,
            ),
          ),
          const SizedBox(width: AppSizes.p16),
          Expanded(
            child: _BalanceNumber(
              label: AppStrings.tractionSessionsBucket,
              value: patient.tractionBalance,
              positiveColor: cs.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceNumber extends StatelessWidget {
  const _BalanceNumber({
    required this.label,
    required this.value,
    required this.positiveColor,
  });
  final String label;
  final int value;
  final Color positiveColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool isWarning = value <= 0;
    final color = isWarning ? cs.error : positiveColor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: AppTextStyles.numberLarge.copyWith(color: color),
        ),
        const SizedBox(height: AppSizes.p4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
