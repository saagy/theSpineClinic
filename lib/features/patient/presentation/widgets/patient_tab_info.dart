/// Info tab — cardless continuous scroll matching appointment detail.
///
/// Sections: Quick Stats → Contact → Assigned Doctors → Package Balance
/// Separated by 24px gaps and 0.5px hairline dividers with eyebrow labels.
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
import 'package:spine_clinic_app/shared/widgets/doctor_row.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/eyebrow_label.dart';
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
    final totalPaid =
        paymentsAsync.value?.fold(0.0, (sum, p) => sum + p.amount) ?? 0.0;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatsStrip(
              apptCount: apptState.totalCount,
              apptLoading: apptState.isLoading,
              lastVisit: patient.lastAppointmentDate,
              totalPaid: totalPaid,
              paymentsLoading: paymentsAsync.isLoading,
              isDoctor: isDoctor,
            ),
            const _FullWidthHairline(),
            const SizedBox(height: AppSizes.p24),
            _ContactSection(patient: patient),
            const SizedBox(height: AppSizes.p24),
            const _HairlineDivider(),
            const SizedBox(height: AppSizes.p24),
            _AssignedDoctorsSection(doctorsAsync: doctorsAsync),
            const SizedBox(height: AppSizes.p24),
            const _HairlineDivider(),
            const SizedBox(height: AppSizes.p24),
            _PackageBalanceSection(
                patient: patient, isDoctor: isDoctor),
            const SizedBox(height: AppSizes.p24),
          ],
        ),
      ),
    );
  }
}

class _FullWidthHairline extends StatelessWidget {
  const _FullWidthHairline();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Divider(color: cs.outlineVariant, height: 0.5, thickness: 0.5);
  }
}

class _HairlineDivider extends StatelessWidget {
  const _HairlineDivider();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
      child: Divider(color: cs.outlineVariant, height: 1, thickness: 0.5),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
    required this.apptCount,
    required this.apptLoading,
    required this.lastVisit,
    required this.totalPaid,
    required this.paymentsLoading,
    required this.isDoctor,
  });
  final int apptCount;
  final bool apptLoading;
  final DateTime? lastVisit;
  final double totalPaid;
  final bool paymentsLoading;
  final bool isDoctor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stats = <_Stat>[
      _Stat(
        value: apptLoading ? '—' : '$apptCount',
        label: AppStrings.totalAppointments,
      ),
      _Stat(
        value: lastVisit != null
            ? Formatters.formatDateMedium(lastVisit!)
            : '—',
        label: AppStrings.lastVisit,
      ),
    ];
    if (!isDoctor) {
      stats.add(_Stat(
        value: paymentsLoading ? '—' : totalPaid.toCurrencyString(),
        label: AppStrings.totalPaid,
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p24, vertical: AppSizes.p16),
      child: Row(
        children: [
          for (int i = 0; i < stats.length; i++) ...[
            if (i > 0)
              Container(
                width: 0.5,
                height: AppSizes.iconHero,
                color: cs.outlineVariant,
                margin:
                    const EdgeInsets.symmetric(horizontal: AppSizes.p8),
              ),
            Expanded(
              child: _StatItem(stat: stats[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.stat});
  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            stat.value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: cs.onSurface,
            ),
            maxLines: 1,
          ),
        ),
        const SizedBox(height: AppSizes.p4),
        Text(
          stat.label,
          style: TextStyle(
            fontSize: 11,
            color: cs.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection({required this.patient});
  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EyebrowLabel(text: AppStrings.contact),
          const SizedBox(height: AppSizes.p12),
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
        Text(label,
            style:
                AppTextStyles.bodySecondary.copyWith(color: cs.onSurfaceVariant)),
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

class _AssignedDoctorsSection extends StatelessWidget {
  const _AssignedDoctorsSection({required this.doctorsAsync});
  final AsyncValue<List<Staff>> doctorsAsync;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EyebrowLabel(text: AppStrings.assignedDoctors),
          const SizedBox(height: AppSizes.p8),
          doctorsAsync.when(
            data: (doctors) => doctors.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
                    child: Text(
                      AppStrings.noDoctorsAssigned,
                      style: AppTextStyles.bodySecondary,
                    ),
                  )
                : Column(
                    children: doctors
                        .map((doc) => DoctorRow(
                              name: doc.fullName,
                              isActive: doc.isActive,
                            ))
                        .toList(),
                  ),
            loading: () => const SkeletonListTile(),
            error: (_, __) => ErrorView(
              exception: UnknownException(
                  message: AppStrings.errorLoadingAssignedDoctors),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageBalanceSection extends StatelessWidget {
  const _PackageBalanceSection({required this.patient, required this.isDoctor});
  final Patient patient;
  final bool isDoctor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EyebrowLabel(
            text: AppStrings.packageBalance,
            action: isDoctor
                ? null
                : GestureDetector(
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) =>
                          PackageBalanceEditDialog(patient: patient),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined,
                            size: AppSizes.iconSmall, color: cs.primary),
                        const SizedBox(width: AppSizes.p4),
                        Text(AppStrings.edit,
                            style: AppTextStyles.captionMedium
                                .copyWith(color: cs.primary)),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: AppSizes.p16),
          Row(
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
        Text('$value',
            style: AppTextStyles.numberLarge.copyWith(color: color)),
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
