part of 'edit_appointment_form.dart';

extension _EditAppointmentView on _EditAppointmentFormState {
  Widget _buildForm(BuildContext context) {
    final isScheduled = widget.appointment.status == AppointmentStatus.scheduled;
    return Form(
      key: _formKey,
      child: FormPageBody(
        isSaving: _isSubmitting,
        onSave: _submit,
        onCancel: () => context.pop(),
        child: FormColumns(
          first: BookingFormFields(
            preselectedPatient: widget.patient,
            onPatientTap: null,
            selectedType: _selectedType,
            onTypeChanged: (type) => _mutate(() {
              _selectedType = type;
              if (!type.affectsPackageBalance) {
                _usePackage = false;
              }
            }),
            isRecurring: false,
            onRecurringChanged: (_) {},
            selectedDate: _selectedDate,
            onDateChanged: (d) => _mutate(() => _selectedDate = d),
            selectedTime: _selectedTime,
            onTimeChanged: (t) => _mutate(() => _selectedTime = t),
            dateErrorText: _dateErrorText,
            timeErrorText: _timeErrorText,
            showRecurringToggle: false,
            enabled: isScheduled,
          ),
          second: FormSection(
            title: AppStrings.providerAndBilling,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isScheduled) ...[
                  Text(
                    AppStrings.checkedInEditHint,
                    style: AppTextStyles.body.copyWith(color: ClinicColors.of(context).warning),
                  ),
                  const SizedBox(height: AppSizes.p16),
                ],
                DoctorSelectField(
                  key: _doctorFieldKey,
                  initialValue: widget.initialDoctors,
                  onSavedDoctors: (_) {},
                  onChanged: (_) {},
                  validator: (doctors) => doctors == null || doctors.isEmpty
                      ? AppStrings.atLeastOneDoctorRequired
                      : null,
                ),
                const SizedBox(height: AppSizes.p16),
                if (_selectedType.affectsPackageBalance)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(AppStrings.usePackageBalance, style: AppTextStyles.body),
                    value: _usePackage,
                    onChanged: isScheduled ? (value) => _mutate(() => _usePackage = value) : null,
                  )
                else
                  const Text(AppStrings.paidSeparately, style: AppTextStyles.bodySecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
