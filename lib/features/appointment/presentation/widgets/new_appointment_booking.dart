part of 'new_appointment_form.dart';

extension _NewAppointmentBooking on _NewAppointmentFormState {
  Future<void> _executeBooking(
    Staff creator,
    List<Staff> doctors,
    List<Staff> secondaryDoctors,
  ) async {
    _mutate(() => _isSubmitting = true);
    final result = await BookingSubmitHelper.executeBooking(
      repo: ref.read(appointmentRepositoryProvider),
      patientId: _patientId!,
      type: _selectedType,
      slots: _computedSlots,
      time: _selectedTime!,
      creatorId: creator.id,
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
    if (_bundleSecondarySession) {
      final secondaryResult = await BookingSubmitHelper.executeBooking(
        repo: ref.read(appointmentRepositoryProvider),
        patientId: _patientId!,
        type: _secondaryType,
        slots: _computedSlots,
        time: _secondaryTime!,
        creatorId: creator.id,
        doctors: secondaryDoctors,
        usePackage: false,
        expectedNextVisitDate: null,
      );
      if (!mounted) return;
      _mutate(() => _isSubmitting = false);
      secondaryResult.when(
        success: (_) {
          _invalidateBookingData();
          ref.invalidate(
            availableBalanceForTypeProvider((
              patientId: _patientId!,
              type: _secondaryType,
            )),
          );
          AppSnackbar.show(
            context,
            message: 'Bundled sessions booked successfully!',
            variant: AppSnackbarVariant.success,
          );
          context.pop();
        },
        failure: (e) {
          _invalidateBookingData();
          AppSnackbar.show(
            context,
            message:
                'Primary booked, but secondary failed: ${AppStrings.fromKey(e.userMessageKey)}',
            variant: AppSnackbarVariant.error,
          );
          context.pop();
        },
      );
    } else {
      _mutate(() => _isSubmitting = false);
      result.when(
        success: (_) {
          _invalidateBookingData();
          AppSnackbar.show(
            context,
            message: _isRecurring
                ? AppStrings.bookingRecurringSuccess
                : AppStrings.bookingSuccess,
            variant: AppSnackbarVariant.success,
          );
          context.pop();
        },
        failure: (_) {},
      );
    }
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
