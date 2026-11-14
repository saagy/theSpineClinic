part of 'edit_appointment_form.dart';

extension _EditAppointmentView on _EditAppointmentFormState {
  Widget _buildForm(BuildContext context) {
    final isScheduled = widget.appointment.status == AppointmentStatus.scheduled;
    final bool canMoveBranch =
        isScheduled || ref.watch(currentUserProvider).value?.role == UserRole.superAdmin;
    final ClinicLocation? branch = _branch;
    final TimeOfDay? time = _selectedTime;
    final DateTime? date = _selectedDate;
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
                BookingBranchField(
                  value: branch,
                  registeredAt: widget.patient.clinic,
                  onChanged: canMoveBranch ? (next) => _mutate(() => _branch = next) : null,
                  lockedMessage: canMoveBranch ? null : AppStrings.staffSchedule.branchLocked,
                ),
                const SizedBox(height: AppSizes.p16),
                Visibility(
                  visible: _selectedType.needsDoctor,
                  maintainState: true,
                  child: DoctorSelectField(
                    key: _doctorFieldKey,
                    initialValue: widget.initialDoctors,
                    branch: branch,
                    collapseOtherBranches: true,
                    onSavedDoctors: (_) {},
                    onChanged: (doctors) => _mutate(() => _doctors = doctors),
                    validator: (doctors) =>
                        _selectedType.needsDoctor && (doctors == null || doctors.isEmpty)
                        ? AppStrings.atLeastOneDoctorRequired
                        : null,
                  ),
                ),
                if (isScheduled && _selectedType.needsDoctor && branch != null && date != null && time != null) ...[
                  const SizedBox(height: AppSizes.p12),
                  BookingScheduleWarnings(
                    doctors: _doctors,
                    branch: branch,
                    starts: [DateTime(date.year, date.month, date.day, time.hour, time.minute)],
                  ),
                ],
                if (!_selectedType.needsDoctor)
                  Text(
                    AppStrings.tractionNoDoctor,
                    style: AppTextStyles.body.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
