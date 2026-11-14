part of 'new_appointment_form.dart';

extension _NewAppointmentBooking on _NewAppointmentFormState {
  Future<void> _executeBooking(List<Staff> doctors) async {
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
    unawaited(ref.read(bookingWorkboardProvider.notifier).refresh());
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
