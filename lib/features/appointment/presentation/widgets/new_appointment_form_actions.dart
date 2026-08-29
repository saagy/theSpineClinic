part of 'new_appointment_form.dart';

extension _NewAppointmentFormActions on _NewAppointmentFormState {
  Future<void> _fetchAssignedDoctors() async {
    if (_patientId == null) return;
    _mutate(() => _isFetchingDoctors = true);
    try {
      final result = await ref
          .read(appointmentRepositoryProvider)
          .getAssignedDoctors(_patientId!)
          .timeout(_NewAppointmentFormState._fetchTimeout);
      if (!mounted) return;
      result.when(
        success: (docs) {
          final activeDocs = docs.where((s) => s.isActive).toList();
          _assignedDoctorsCache = activeDocs;
          _prepopulateDoctorsForBundling();
          _mutate(() {
            _isFetchingDoctors = false;
            _doctorFieldEnabled = true;
          });
        },
        failure: (e) {
          _mutate(() {
            _isFetchingDoctors = false;
            _doctorFieldEnabled = true;
          });
          AppSnackbar.show(
            context,
            message: AppStrings.fromKey(e.userMessageKey),
            variant: AppSnackbarVariant.error,
          );
        },
      );
    } on TimeoutException {
      if (!mounted) return;
      _mutate(() {
        _isFetchingDoctors = false;
        _doctorFieldEnabled = true;
      });
      AppSnackbar.show(
        context,
        message: AppStrings.doctorListTimeout,
        variant: AppSnackbarVariant.info,
      );
    } catch (_) {
      if (!mounted) return;
      _mutate(() {
        _isFetchingDoctors = false;
        _doctorFieldEnabled = true;
      });
    }
  }

  void _prepopulateDoctorsForBundling() {
    final docs = _assignedDoctorsCache;
    final primaryIsPT = _selectedType == AppointmentType.normalPtSession ||
        _selectedType == AppointmentType.spinalTractionSession;
    final secondaryIsPT = _bundleSecondarySession &&
        (_secondaryType == AppointmentType.normalPtSession ||
            _secondaryType == AppointmentType.spinalTractionSession);

    final sorted = List<Staff>.from(docs)
      ..sort((a, b) {
        if (a.id == widget.preselectedDoctorId) return -1;
        if (b.id == widget.preselectedDoctorId) return 1;
        return a.fullName.compareTo(b.fullName);
      });

    if (primaryIsPT) {
      _doctorFieldKey.currentState?.didChange(sorted);
      if (_bundleSecondarySession) {
        _secondaryDoctorFieldKey.currentState?.didChange([]);
      }
    } else {
      _doctorFieldKey.currentState?.didChange([]);
      if (secondaryIsPT) {
        _secondaryDoctorFieldKey.currentState?.didChange(sorted);
      } else {
        _secondaryDoctorFieldKey.currentState?.didChange([]);
      }
    }
  }

  void _onPatientSelected(Patient patient) {
    _doctorFieldKey.currentState?.didChange([]);
    _secondaryDoctorFieldKey.currentState?.didChange([]);
    _mutate(() {
      _patientId = patient.id;
      _doctorFieldEnabled = false;
      _isFetchingDoctors = true;
    });
    _fetchAssignedDoctors();
  }

  List<DateTime> get _computedSlots => _selectedDate == null
      ? const []
      : (!_isRecurring
            ? [_selectedDate!]
            : DateRecurrenceUtils.generateRecurrenceSlots(
                startDate: _selectedDate!,
                weekdays: _selectedWeekdays,
                totalSessions: int.tryParse(_sessionsController.text) ?? 0,
              ));

  Future<void> _submitForm() async {
    final bool isFormValid = _formKey.currentState?.validate() ?? false;
    _mutate(() {
      _dateErrorText = _selectedDate == null ? AppStrings.dateRequired : null;
      _timeErrorText = _selectedTime == null ? AppStrings.timeRequired : null;
      _secondaryTimeErrorText = _bundleSecondarySession && _secondaryTime == null
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
        creator.role == UserRole.doctor) {
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
            message: 'Primary booked, but secondary failed: ${AppStrings.fromKey(e.userMessageKey)}',
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

  Patient? _resolvePatient() {
    if (_patientId == null) return null;
    return ref.watch(patientDetailProvider(_patientId!)).value;
  }

  void _openPatientSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r24)),
      ),
      builder: (sheetContext) => PatientSearchSheet(
        onSelected: (patient) {
          _onPatientSelected(patient);
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }
}
