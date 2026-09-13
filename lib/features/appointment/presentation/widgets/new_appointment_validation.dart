part of 'new_appointment_form.dart';

extension _NewAppointmentValidation on _NewAppointmentFormState {
  Future<void> _submitForm() async {
    final bool isFormValid = _formKey.currentState?.validate() ?? false;
    _mutate(() {
      _dateErrorText = _selectedDate == null ? AppStrings.dateRequired : null;
      _timeErrorText = _selectedTime == null ? AppStrings.timeRequired : null;
      _secondaryTimeErrorText =
          _bundleSecondarySession && _secondaryTime == null
          ? AppStrings.timeRequired
          : null;
      _daysErrorText = _isRecurring && _selectedWeekdays.isEmpty
          ? AppStrings.daysRequired
          : null;
    });
    if (_isRecurring) {
      final int sessions = int.tryParse(_sessionsController.text) ?? 0;
      if (sessions < 1 || sessions > 24) {
        AppSnackbar.show(
          context,
          message: AppStrings.sessionsRangeError,
          variant: AppSnackbarVariant.error,
        );
        return;
      }
    }
    if (!isFormValid ||
        _dateErrorText != null ||
        _timeErrorText != null ||
        _secondaryTimeErrorText != null ||
        _daysErrorText != null) {
      return;
    }
    if (_patientId == null) {
      AppSnackbar.show(
        context,
        message: AppStrings.patientRequired,
        variant: AppSnackbarVariant.error,
      );
      return;
    }
    final doctors = _doctorFieldKey.currentState?.value ?? [];
    if (doctors.isEmpty) {
      AppSnackbar.show(
        context,
        message: AppStrings.noAssignedDoctors,
        variant: AppSnackbarVariant.error,
      );
      return;
    }
    final secondaryDoctors = _bundleSecondarySession
        ? (_secondaryDoctorFieldKey.currentState?.value ?? [])
        : const <Staff>[];
    if (_bundleSecondarySession && secondaryDoctors.isEmpty) {
      AppSnackbar.show(
        context,
        message: 'Secondary doctor is required',
        variant: AppSnackbarVariant.error,
      );
      return;
    }
    final Staff? creator = ref.read(currentUserProvider).value;
    if (creator == null ||
        !creator.isActive ||
        (creator.role == UserRole.doctor && !creator.isSeniorDoctor)) {
      AppSnackbar.show(
        context,
        message: AppStrings.accessDenied,
        variant: AppSnackbarVariant.error,
      );
      return;
    }

    if (_selectedType.affectsPackageBalance && _usePackage) {
      final available = await ref.read(
        availableBalanceForTypeProvider((
          patientId: _patientId!,
          type: _selectedType,
        )).future,
      );
      if (!mounted) return;
      if (_computedSlots.length > (available ?? 0)) {
        AppSnackbar.show(
          context,
          message: AppStrings.insufficientPackageBalance,
          variant: AppSnackbarVariant.error,
        );
        return;
      }
    }

    await _executeBooking(creator, doctors, secondaryDoctors);
  }
}
