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
        (_selectedType.affectsPackageBalance && _usePackage) ? _computedSlots.length : 0;

    final bool isSubmissionBlocked = isPatientValid &&
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
                      
                      if (type != AppointmentType.normalPtSession &&
                          type != AppointmentType.spinalTractionSession) {
                        _bundleSecondarySession = false;
                      } else {
                        _secondaryType = AppointmentType.initialAssessment;
                      }
                      _prepopulateDoctorsForBundling();
                    }),
                    isRecurring: _isRecurring,
                    onRecurringChanged: (value) =>
                        _mutate(() {
                          _isRecurring = value;
                          if (value) {
                            _bundleSecondarySession = false;
                          }
                        }),
                    selectedDate: _selectedDate,
                    onDateChanged: (date) =>
                        _mutate(() => _selectedDate = date),
                    selectedTime: _selectedTime,
                    onTimeChanged: (time) =>
                        _mutate(() {
                          _selectedTime = time;
                          _secondaryTime = time;
                        }),
                    dateErrorText: _dateErrorText,
                    timeErrorText: _timeErrorText,
                    showRecurringToggle: !_bundleSecondarySession,
                  ),
                  if (_selectedType == AppointmentType.normalPtSession ||
                      _selectedType == AppointmentType.spinalTractionSession) ...[
                    if (!_isRecurring) ...[
                      const SizedBox(height: AppSizes.p16),
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

  Widget _buildBundlingToggle(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p8),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: AppSizes.borderWidth,
          ),
        ),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Bundle with assessment',
            style: AppTextStyles.bodyBold.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            'Book an assessment session alongside this treatment',
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          value: _bundleSecondarySession,
          activeThumbColor: Theme.of(context).colorScheme.primary,
          onChanged: (val) => _mutate(() {
            _bundleSecondarySession = val;
            if (val) {
              _isRecurring = false;
            }
            _prepopulateDoctorsForBundling();
          }),
        ),
      ),
    );
  }

  Widget _buildSecondarySessionFields(BuildContext context) {
    final theme = Theme.of(context);
    final clinic = ClinicColors.of(context);

    final List<AppointmentType> allowedSecondaryTypes = [
      AppointmentType.initialAssessment,
      AppointmentType.reassessment,
    ];

    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        border: Border.all(
          color: theme.colorScheme.outline,
          width: AppSizes.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Secondary Session Settings',
            style: AppTextStyles.captionMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSizes.p12),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.outline,
              borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12 - 1)),
              child: Row(
                children: allowedSecondaryTypes.map((type) {
                  return Expanded(
                    child: _buildSecondaryCell(context, type),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.p16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Secondary Time',
                      style: AppTextStyles.captionMedium.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p6),
                    InkWell(
                      onTap: () => _pickSecondaryTime(context),
                      borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.p12,
                          vertical: AppSizes.p12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(AppSizes.r12),
                          ),
                          border: Border.all(
                            color: _secondaryTimeErrorText != null
                                ? theme.colorScheme.error
                                : theme.colorScheme.outline,
                            width: AppSizes.borderWidth,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: AppSizes.iconDefault,
                              color: clinic.textMuted,
                            ),
                            const SizedBox(width: AppSizes.p8),
                            Expanded(
                              child: Text(
                                _secondaryTime != null
                                    ? '${_secondaryTime!.hour.toString().padLeft(2, '0')}:${_secondaryTime!.minute.toString().padLeft(2, '0')}'
                                    : 'Select',
                                style: AppTextStyles.body.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_secondaryTimeErrorText != null) ...[
                      const SizedBox(height: AppSizes.p4),
                      Text(
                        _secondaryTimeErrorText!,
                        style: AppTextStyles.caption.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p16),
          Text(
            'Secondary Session Doctors',
            style: AppTextStyles.captionMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSizes.p6),
          DoctorSelectField(
            key: _secondaryDoctorFieldKey,
            initialValue: const [],
            enabled: _doctorFieldEnabled,
            onSavedDoctors: (_) {},
            onChanged: (_) {},
            validator: (doctors) => doctors == null || doctors.isEmpty
                ? AppStrings.atLeastOneDoctorRequired
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryCell(BuildContext context, AppointmentType type) {
    final theme = Theme.of(context);
    final bool active = _secondaryType == type;
    return Material(
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: () => _mutate(() {
          _secondaryType = type;
          _prepopulateDoctorsForBundling();
        }),
        child: Container(
          padding: const EdgeInsets.all(4.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              vertical: AppSizes.p12,
              horizontal: AppSizes.p4,
            ),
            decoration: BoxDecoration(
              color: active
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surface.withAlpha(0),
              border: Border.all(
                color: active
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surface.withAlpha(0),
                width: 1.0,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r8)),
            ),
            child: Text(
              type.displayLabel,
              textAlign: TextAlign.center,
              style: (active ? AppTextStyles.bodyBold : AppTextStyles.body).copyWith(
                color: active
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

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
