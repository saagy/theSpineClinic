import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_phone_options_sheet.dart';

/// The side panel's contact and registration facts.
class PatientSummaryFacts extends StatelessWidget {
  const PatientSummaryFacts({super.key, required this.patient});
  final Patient patient;

  /// Contact first (the second phone and the address; the main phone is the
  /// call action above), then how the patient came to the clinic.
  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final PatientPersonalDetails details = patient.personalDetails;
    final String? second = details.secondaryPhone?.trim().isEmpty ?? true ? null : details.secondaryPhone;
    final String? address = details.address?.trim().isEmpty ?? true ? null : details.address;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (second != null || address != null) ...[
          _heading(cs, AppStrings.patientContact),
          if (second != null)
            _metaRow(
              cs,
              AppStrings.patientSecondaryPhone,
              Formatters.formatPhone(second),
              onTap: () => PatientPhoneOptionsSheet.show(context, second),
            ),
          if (address != null) _metaRow(cs, AppStrings.patientAddress, address),
          const SizedBox(height: AppSizes.p16),
        ],
        _heading(cs, AppStrings.patientRegistration),
        _metaRow(cs, AppStrings.registered, Formatters.formatDateMedium(patient.createdAt)),
        if (patient.lastAppointmentDate != null)
          _metaRow(cs, AppStrings.lastVisit, Formatters.formatDateMedium(patient.lastAppointmentDate!)),
        if (details.referralSource?.trim().isNotEmpty ?? false)
          _metaRow(cs, AppStrings.patientReferralSource, details.referralSource!),
        if (details.nationality?.trim().isNotEmpty ?? false)
          _metaRow(cs, AppStrings.patientNationality, details.nationality!),
      ],
    );
  }

  Widget _heading(ColorScheme cs, String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.p4),
    child: Text(text, style: AppTextStyles.captionBold.copyWith(color: cs.onSurfaceVariant)),
  );

  /// Label above value, so long addresses and answers wrap instead of
  /// squeezing against the label.
  Widget _metaRow(ColorScheme cs, String label, String value, {VoidCallback? onTap}) {
    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: AppSizes.p2),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(color: onTap == null ? cs.onSurface : cs.primary),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.r6),
      child: ConstrainedBox(constraints: const BoxConstraints(minHeight: AppSizes.tappableMin), child: content),
    );
  }
}
