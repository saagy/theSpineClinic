part of 'new_appointment_form.dart';

extension _NewAppointmentValidation on _NewAppointmentFormState {
  Future<void> _submitForm() async {
    final bool isFormValid = _formKey.currentState?.validate() ?? false;
    _mutate(() {
      _dateErrorText = _selectedDate == null ? AppStrings.dateRequired : null;
      _timeErrorText = _selectedTime == null ? AppStrings.timeRequired : null;
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
    final List<Staff> doctors = _selectedType.needsDoctor
        ? (_doctorFieldKey.currentState?.value ?? [])
        : const <Staff>[];
    if (_selectedType.needsDoctor && doctors.isEmpty) {
      AppSnackbar.show(
        context,
        message: AppStrings.noAssignedDoctors,
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

    await _executeBooking(doctors);
  }
}
