part of 'new_appointment_form.dart';

extension _SecondarySessionFields on _NewAppointmentFormState {
  Widget _buildSecondarySessionFields(BuildContext context) => FormSection(
    title: AppStrings.secondarySession,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<AppointmentType>(
          segments: [
            for (final type in [AppointmentType.initialAssessment, AppointmentType.reassessment])
              ButtonSegment(value: type, label: Text(type.displayLabel)),
          ],
          selected: {_secondaryType},
          showSelectedIcon: false,
          style: const ButtonStyle(
            textStyle: WidgetStatePropertyAll(AppTextStyles.captionBold),
            minimumSize: WidgetStatePropertyAll(Size(AppSizes.tappableMin, AppSizes.tappableMin)),
          ),
          onSelectionChanged: (types) => _mutate(() {
            _secondaryType = types.first;
          }),
        ),
        const SizedBox(height: AppSizes.p20),
        BookingPickerField(
          label: AppStrings.selectTime,
          value: _secondaryTime?.format(context) ?? AppStrings.select,
          icon: Icons.schedule,
          error: _secondaryTimeErrorText,
          onTap: () => _pickSecondaryTime(context),
        ),
        const SizedBox(height: AppSizes.p20),
        DoctorSelectField(
          key: _secondaryDoctorFieldKey,
          initialValue: const [],
          enabled: _doctorFieldEnabled,
          onSavedDoctors: (_) {},
          onChanged: (_) {},
          validator: (doctors) =>
              doctors == null || doctors.isEmpty ? AppStrings.atLeastOneDoctorRequired : null,
        ),
        const SizedBox(height: AppSizes.p8),
        const Text(AppStrings.assessmentDoctorReminder, style: AppTextStyles.caption),
      ],
    ),
  );
  Future<void> _pickSecondaryTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _secondaryTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) {
      _mutate(() {
        _secondaryTime = picked;
        _secondaryTimeErrorText = null;
      });
    }
  }
}
