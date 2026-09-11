import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_monogram_badge.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_phone_options_sheet.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_summary_balance_cards.dart';

/// Modern 2026 SaaS Summary Rail anchored on the left of the patient workspace.
class PatientSummarySidebar extends ConsumerWidget {
  const PatientSummarySidebar({super.key, required this.patient, required this.isDoctor});

  final Patient patient;
  final bool isDoctor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider).value;
    final canEditBalance = user != null && user.role != UserRole.doctor;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(right: BorderSide(color: cs.outlineVariant.withAlpha(120))),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p24),
        children: [
          _buildIdentitySection(context, cs),
          const SizedBox(height: AppSizes.p20),
          _buildQuickActions(context, cs),
          const SizedBox(height: AppSizes.p24),
          PatientSummaryBalanceCards(patient: patient, canEdit: canEditBalance),
          const SizedBox(height: AppSizes.p24),
          _buildAttendingDoctors(context, ref, cs),
          const SizedBox(height: AppSizes.p24),
          _buildMetadata(context, cs),
        ],
      ),
    );
  }

  Widget _buildIdentitySection(BuildContext context, ColorScheme cs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PatientMonogramBadge(name: patient.fullName, size: AppSizes.patientHeaderAvatarSize),
        const SizedBox(width: AppSizes.p14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patient.fullName,
                style: AppTextStyles.headingMedium.copyWith(color: cs.onSurface),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSizes.p4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p2),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer.withAlpha(120),
                  borderRadius: BorderRadius.circular(AppSizes.r6),
                ),
                child: Text(
                  patient.clinic.displayLabel,
                  style: AppTextStyles.captionBold.copyWith(color: cs.onSecondaryContainer),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, ColorScheme cs) {
    final hasPhone = patient.phoneNumber.trim().isNotEmpty;
    return Wrap(
      spacing: AppSizes.p8,
      runSpacing: AppSizes.p8,
      children: [
        if (hasPhone)
          _ActionPill(
            icon: LucideIcons.phone,
            label: Formatters.formatPhone(patient.phoneNumber),
            onTap: () => PatientPhoneOptionsSheet.show(context, patient.phoneNumber),
          ),
        _ActionPill(
          icon: LucideIcons.pencil,
          label: AppStrings.edit,
          onTap: () => context.push(AppRoutes.editPatient.replaceFirst(':id', patient.id)),
        ),
      ],
    );
  }

  Widget _buildAttendingDoctors(BuildContext context, WidgetRef ref, ColorScheme cs) {
    final doctorsAsync = ref.watch(patientAssignedDoctorsProvider(patient.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.attendingStaff, style: AppTextStyles.captionBold.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: AppSizes.p8),
        doctorsAsync.when(
          data: (doctors) {
            if (doctors.isEmpty) {
              return Text(AppStrings.noDoctorsAssigned, style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant));
            }
            return Column(
              children: [
                for (final doc in doctors)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
                    child: Row(
                      children: [
                        PatientMonogramBadge(name: doc.fullName, size: AppSizes.p28),
                        const SizedBox(width: AppSizes.p10),
                        Expanded(
                          child: Text(doc.fullName, style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface)),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
          loading: () => const SizedBox(height: 24),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildMetadata(BuildContext context, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: cs.outlineVariant.withAlpha(80), height: 1),
        const SizedBox(height: AppSizes.p12),
        _metaRow(cs, AppStrings.phone, Formatters.formatPhone(patient.phoneNumber)),
        _metaRow(cs, AppStrings.registered, Formatters.formatDateMedium(patient.createdAt)),
        if (patient.lastAppointmentDate != null)
          _metaRow(cs, AppStrings.lastVisit, Formatters.formatDateMedium(patient.lastAppointmentDate!),
          ),
      ],
    );
  }

  Widget _metaRow(ColorScheme cs, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant)),
          Text(value, style: AppTextStyles.captionBold.copyWith(color: cs.onSurface)),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHigh.withAlpha(120),
      borderRadius: BorderRadius.circular(AppSizes.r8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.r8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p10, vertical: AppSizes.p6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: cs.primary),
              const SizedBox(width: AppSizes.p6),
              Text(label, style: AppTextStyles.captionBold.copyWith(color: cs.onSurface)),
            ],
          ),
        ),
      ),
    );
  }
}
