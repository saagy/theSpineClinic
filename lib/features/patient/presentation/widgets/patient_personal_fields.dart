import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/form_columns.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../../shared/widgets/record_action_menu.dart';
import '../../../../shared/widgets/record_menu_select.dart';
import '../../domain/patient.dart';

class PatientPersonalFields extends StatelessWidget {
  const PatientPersonalFields({
    super.key,
    required this.value,
    required this.onChanged,
    required this.enabled,
  });
  final PatientPersonalDetails value;
  final ValueChanged<PatientPersonalDetails> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => FormColumns(
    first: FormSection(
      title: AppStrings.personalDetails,
      description: AppStrings.patientOptionalDetails,
      child: _fields([
        _text(
          AppStrings.patientSecondaryPhone,
          value.secondaryPhone,
          (text) => onChanged(value.copyWith(secondaryPhone: text)),
          keyboard: TextInputType.phone,
        ),
        _text(
          AppStrings.patientAddress,
          value.address,
          (text) => onChanged(value.copyWith(address: text)),
        ),
        _date(
          context,
          AppStrings.patientBirthDate,
          value.dateOfBirth,
          (date) => onChanged(value.copyWith(dateOfBirth: date)),
          lastDate: DateTime.now(),
        ),
        _text(
          AppStrings.patientNationality,
          value.nationality,
          (text) => onChanged(value.copyWith(nationality: text)),
        ),
        RecordMenuSelect<PatientGender?>(
          label: AppStrings.patientGender,
          value: value.gender,
          isField: true,
          options: const [
            RecordMenuAction(
              null,
              AppStrings.patientNotSpecified,
              Icons.remove,
            ),
            RecordMenuAction(
              PatientGender.female,
              AppStrings.patientFemale,
              Icons.person_outline,
            ),
            RecordMenuAction(
              PatientGender.male,
              AppStrings.patientMale,
              Icons.person_outline,
            ),
          ],
          onChanged: enabled
              ? (gender) => onChanged(value.copyWith(gender: gender))
              : null,
        ),
        _text(
          AppStrings.patientReferralSource,
          value.referralSource,
          (text) => onChanged(value.copyWith(referralSource: text)),
        ),
      ]),
    ),
    second: FormSection(
      title: AppStrings.patientInsurance,
      description: AppStrings.patientOptionalDetails,
      child: _fields([
        _text(
          AppStrings.patientInsuranceCompany,
          value.insuranceCompany,
          (text) => onChanged(value.copyWith(insuranceCompany: text)),
        ),
        _text(
          AppStrings.patientInsuranceNumber,
          value.insuranceMemberNumber,
          (text) => onChanged(value.copyWith(insuranceMemberNumber: text)),
        ),
        _date(
          context,
          AppStrings.patientInsuranceExpiry,
          value.insuranceExpiry,
          (date) => onChanged(value.copyWith(insuranceExpiry: date)),
          lastDate: DateTime(2150),
        ),
      ]),
    ),
  );

  Widget _fields(List<Widget> fields) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (index, field) in fields.indexed) ...[
        if (index != 0) const SizedBox(height: AppSizes.p16),
        field,
      ],
    ],
  );

  Widget _text(
    String label,
    String? initialValue,
    ValueChanged<String?> onChange, {
    TextInputType keyboard = TextInputType.text,
  }) => TextFormField(
    initialValue: initialValue,
    enabled: enabled,
    keyboardType: keyboard,
    textInputAction: TextInputAction.next,
    style: AppTextStyles.body,
    decoration: InputDecoration(labelText: label),
    onChanged: (value) => onChange(value.trim().isEmpty ? null : value.trim()),
  );

  Widget _date(
    BuildContext context,
    String label,
    DateTime? value,
    ValueChanged<DateTime?> onChange, {
    required DateTime lastDate,
  }) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          icon: const Icon(Icons.calendar_today_outlined),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, AppSizes.tappableMin),
          ),
          onPressed: enabled
              ? () async {
                  final firstDate = DateTime(1900);
                  final selected = value ?? DateTime.now();
                  final initial = selected.isBefore(firstDate)
                      ? firstDate
                      : selected.isAfter(lastDate)
                      ? lastDate
                      : selected;
                  final date = await showDatePicker(
                    context: context,
                    firstDate: firstDate,
                    lastDate: lastDate,
                    initialDate: initial,
                  );
                  if (context.mounted && date != null) onChange(date);
                }
              : null,
          label: Text(
            value == null
                ? label
                : '$label · ${Formatters.formatDateMedium(value)}',
            style: AppTextStyles.bodyMedium,
          ),
        ),
      ),
      if (value != null)
        IconButton(
          tooltip: AppStrings.clearFilters,
          onPressed: enabled ? () => onChange(null) : null,
          icon: const Icon(Icons.close),
        ),
    ],
  );
}
