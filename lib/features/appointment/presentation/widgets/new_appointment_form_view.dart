part of 'new_appointment_form.dart';

extension _NewAppointmentFormView on _NewAppointmentFormState {
  Widget _buildForm(BuildContext context) {
    final Patient? patient = _resolvePatient();
    final bool isPatientValid = _patientId != null;
    final availableAsync = isPatientValid
        ? ref.watch(
            availableBalanceForTypeProvider((
              patientId: _patientId!,
              type: _selectedType,
            )),
          )
        : null;
    final int proposedCount = _usePackage ? _computedSlots.length : 0;
    final bool isSubmissionBlocked =
        isPatientValid &&
        proposedCount > 0 &&
        (availableAsync == null ||
            availableAsync.isLoading ||
            availableAsync.hasError ||
            proposedCount > (availableAsync.value ?? 0));

    return LoadingOverlay(
      isLoading: _isSubmitting,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.appointmentFormMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BookingFormFields(
                    preselectedPatient: patient,
                    onPatientTap: () => _openPatientSearch(context),
                    selectedType: _selectedType,
                    onTypeChanged: (type) => _mutate(() {
                      _selectedType = type;
                      if (!type.affectsPackageBalance) _usePackage = false;
                    }),
                    isRecurring: _isRecurring,
                    onRecurringChanged: (value) =>
                        _mutate(() => _isRecurring = value),
                    selectedDate: _selectedDate,
                    onDateChanged: (date) =>
                        _mutate(() => _selectedDate = date),
                    selectedTime: _selectedTime,
                    onTimeChanged: (time) =>
                        _mutate(() => _selectedTime = time),
                    dateErrorText: _dateErrorText,
                    timeErrorText: _timeErrorText,
                  ),
                  if (_isRecurring) ...[
                    const SizedBox(height: AppSizes.p16),
                    _buildRecurrenceSection(context),
                  ],
                  const SizedBox(height: AppSizes.p16),
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
                      usePackage: _usePackage,
                    ),
                  ],
                  const SizedBox(height: AppSizes.p32),
                  AppButton(
                    labelText: AppStrings.save,
                    onPressed: isSubmissionBlocked || _isSubmitting
                        ? null
                        : _submitForm,
                    isLoading: _isSubmitting,
                    debounceMs: 1000,
                  ),
                  const SizedBox(height: AppSizes.p48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
