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
    final int proposedCount =
        (_selectedType.affectsPackageBalance && _usePackage)
        ? _computedSlots.length
        : 0;

    final bool pendingRetry =
        isPatientValid &&
        (ref.watch(pendingBookingProvider(_patientId!)).value ?? false);
    final bool isSubmissionBlocked =
        !pendingRetry &&
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
        child: FormPageBody(
          isSaving: _isSubmitting,
          onSave: isSubmissionBlocked ? null : _submitForm,
          onCancel: () => context.pop(),
          child: FormColumns(
            first: BookingFormFields(
              preselectedPatient: patient,
              onPatientTap: () => _openPatientSearch(context),
              selectedType: _selectedType,
              onTypeChanged: (type) => _mutate(() {
                if (_selectedType.affectsPackageBalance) {
                  _sessionUsePackage = _usePackage;
                }
                _selectedType = type;
                _usePackage = type.affectsPackageBalance
                    ? _sessionUsePackage
                    : false;

                if (!type.affectsPackageBalance) {
                  _bundleSecondarySession = false;
                }
              }),
              isRecurring: _isRecurring,
              onRecurringChanged: (value) => _mutate(() {
                _isRecurring = value;
                if (value) {
                  _bundleSecondarySession = false;
                }
              }),
              selectedDate: _selectedDate,
              onDateChanged: (date) => _mutate(() => _selectedDate = date),
              selectedTime: _selectedTime,
              onTimeChanged: (time) => _mutate(() {
                _selectedTime = time;
                _secondaryTime = time;
              }),
              dateErrorText: _dateErrorText,
              timeErrorText: _timeErrorText,
              showRecurringToggle: !_bundleSecondarySession,
            ),
            second: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_selectedType == AppointmentType.normalPtSession ||
                    _selectedType == AppointmentType.spinalTractionSession) ...[
                  if (!_isRecurring) ...[
                    _buildBundlingToggle(context),
                    if (_bundleSecondarySession) ...[
                      const SizedBox(height: AppSizes.p16),
                      _buildSecondarySessionFields(context),
                    ],
                  ],
                ],
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBundlingToggle(BuildContext context) => FormSection(
    title: AppStrings.bundleAssessment,
    child: SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text(
        AppStrings.bundleAssessmentHint,
        style: AppTextStyles.body,
      ),
      value: _bundleSecondarySession,
      onChanged: (value) => _mutate(() {
        _bundleSecondarySession = value;
        if (value) {
          _isRecurring = false;
          _secondaryTime ??= _selectedTime;
        }
      }),
    ),
  );
}
