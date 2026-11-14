import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';

/// The identity facts a patient banner shows beside the name, in the order
/// staff confirm them: sex, age, date of birth. Only known parts appear;
/// null when none are known.
String? patientIdentityLine(PatientPersonalDetails details, {DateTime? today}) {
  final DateTime now = today ?? DateTime.now();
  final DateTime? born = details.dateOfBirth;
  final List<String> parts = [
    switch (details.gender) {
      PatientGender.female => AppStrings.patientFemale,
      PatientGender.male => AppStrings.patientMale,
      null => null,
    },
    if (born != null) AppStrings.patientAgeYears(_years(born, now)),
    if (born != null) Formatters.formatDateMedium(born),
  ].whereType<String>().toList();
  return parts.isEmpty ? null : parts.join(' · ');
}

int _years(DateTime born, DateTime now) {
  int years = now.year - born.year;
  if (now.month < born.month || (now.month == born.month && now.day < born.day)) years--;
  return years < 0 ? 0 : years;
}
