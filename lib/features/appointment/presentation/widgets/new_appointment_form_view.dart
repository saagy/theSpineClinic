part of 'new_appointment_form.dart';

extension _NewAppointmentFormView on _NewAppointmentFormState {
  Widget _buildForm(BuildContext context) {
    final Patient? patient = _resolvePatient();
    final bool isPatientValid = _patientId != null;
    final int proposedCount = _selectedType.affectsPackageBalance ? _computedSlots.length : 0;

    return Form(
      key: _formKey,
      child: FormPageBody(
        isSaving: _isSubmitting,
        onSave: _submitForm,
        onCancel: () => context.pop(),
        child: FormColumns(
          first: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBookingFields(context, patient),
              if (isPatientValid && _selectedTime != null)
                PatientVisitClashWarning(
                  patientId: _patientId!,
                  starts: [
                    for (final DateTime day in _computedSlots)
                      DateTime(day.year, day.month, day.day, _selectedTime!.hour, _selectedTime!.minute),
                  ],
                ),
            ],
          ),
          second: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isRecurring) ...[
                _buildRecurrenceSection(context),
                const SizedBox(height: AppSizes.p16),
              ],
              _buildProviderSection(context),
              if (isPatientValid) ...[
                const SizedBox(height: AppSizes.p24),
                AppointmentBalanceDiagnostics(
                  patientId: _patientId!,
                  appointmentType: _selectedType,
                  requestedCount: proposedCount,
                ),
              ],
              if (_computedSlots.isNotEmpty) ...[
                const SizedBox(height: AppSizes.p24),
                BookingSlotsPreview(
                  slots: _computedSlots,
                  timeOfDay: _selectedTime,
                  usePackage: _selectedType.affectsPackageBalance,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingFields(BuildContext context, Patient? patient) => BookingFormFields(
    preselectedPatient: patient,
    onPatientTap: () => _openPatientSearch(context),
    selectedType: _selectedType,
    onTypeChanged: (type) => _mutate(() => _selectedType = type),
    isRecurring: _isRecurring,
    onRecurringChanged: (value) => _mutate(() => _isRecurring = value),
    selectedDate: _selectedDate,
    onDateChanged: (date) => _mutate(() => _selectedDate = date),
    selectedTime: _selectedTime,
    onTimeChanged: (time) => _mutate(() => _selectedTime = time),
    dateErrorText: _dateErrorText,
    timeErrorText: _timeErrorText,
  );
}
