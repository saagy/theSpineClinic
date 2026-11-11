import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/record_fact_grid.dart';
import '../../../../shared/widgets/record_section.dart';
import '../../domain/patient.dart';

class PatientPersonalSummary extends StatelessWidget {
  const PatientPersonalSummary({super.key, required this.details});
  final PatientPersonalDetails details;

  @override
  Widget build(BuildContext context) {
    final profile = details;
    final personal = <String, String?>{
      AppStrings.patientAddress: profile.address,
      AppStrings.patientBirthDate: profile.dateOfBirth == null
          ? null
          : Formatters.formatDateMedium(profile.dateOfBirth!),
      AppStrings.patientNationality: profile.nationality,
      AppStrings.patientGender: switch (profile.gender) {
        PatientGender.female => AppStrings.patientFemale,
        PatientGender.male => AppStrings.patientMale,
        null => null,
      },
      AppStrings.patientSecondaryPhone: profile.secondaryPhone,
      AppStrings.patientReferralSource: profile.referralSource,
    };
    return _section(AppStrings.personalDetails, personal);
  }

  Widget _section(String title, Map<String, String?> fields) {
    final populated = fields.entries.where(
      (field) => field.value?.isNotEmpty == true,
    );
    if (populated.isEmpty) return const SizedBox.shrink();
    return RecordSection(
      title: title,
      child: RecordFactGrid(
        children: [
          for (final field in populated)
            RecordFact(label: field.key, value: field.value!),
        ],
      ),
    );
  }
}
