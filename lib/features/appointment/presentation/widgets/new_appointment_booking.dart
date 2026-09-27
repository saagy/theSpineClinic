part of 'new_appointment_form.dart';

extension _NewAppointmentBooking on _NewAppointmentFormState {
  Future<void> _executeBooking(
    Staff creator,
    List<Staff> doctors,
    List<Staff> secondaryDoctors,
  ) async {
    _mutate(() => _isSubmitting = true);
    final result = await ref
        .read(bookingControllerProvider.notifier)
        .executeBooking(
          patientId: _patientId!,
          type: _selectedType,
          slots: _computedSlots,
          time: _selectedTime!,
          doctors: doctors,
          usePackage: _usePackage,
          expectedNextVisitDate: widget.expectedNextVisitDate,
          companionType: _bundleSecondarySession ? _secondaryType : null,
          companionTime: _bundleSecondarySession ? _secondaryTime : null,
          companionDoctors: secondaryDoctors,
        );
    if (!mounted) return;
    if (result.isFailure) {
      _mutate(() => _isSubmitting = false);
      result.when(
        success: (_) {},
        failure: (e) => AppSnackbar.show(
          context,
          message: AppStrings.fromKey(e.userMessageKey),
          variant: AppSnackbarVariant.error,
        ),
      );
      return;
    }
    _mutate(() => _isSubmitting = false);
    _invalidateBookingData();
    if (_bundleSecondarySession) {
      ref.invalidate(
        availableBalanceForTypeProvider((
          patientId: _patientId!,
          type: _secondaryType,
        )),
      );
    }
    AppSnackbar.show(
      context,
      message: _isRecurring
          ? AppStrings.bookingRecurringSuccess
          : AppStrings.bookingSuccess,
      variant: AppSnackbarVariant.success,
    );
    context.pop();
  }

  void _invalidateBookingData() {
    ref.invalidate(receptionistAppointmentsProvider);
    ref.invalidate(doctorScheduleProvider);
    ref.invalidate(allAppointmentsProvider);
    ref.invalidate(bookingWorkboardProvider);
    ref.invalidate(patient_tab.patientAppointmentsProvider(_patientId!));
    ref.invalidate(todayAppointmentsProvider);
    ref.invalidate(patientAppointmentsProvider(_patientId!));
    ref.invalidate(patientDetailProvider(_patientId!));
    ref.invalidate(futureScheduledAppointmentsCountProvider(_patientId!));
    ref.invalidate(
      availableBalanceForTypeProvider((
        patientId: _patientId!,
        type: _selectedType,
      )),
    );
  }
}
