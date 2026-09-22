part of 'new_appointment_form.dart';

extension _NewAppointmentFormActions on _NewAppointmentFormState {
  Future<void> _fetchAssignedDoctors() async {
    final String? patientId = _patientId;
    if (patientId == null) return;
    _mutate(() => _isFetchingDoctors = true);
    try {
      final result = await ref
          .read(appointmentRepositoryProvider)
          .getAssignedDoctors(patientId)
          .timeout(_NewAppointmentFormState._fetchTimeout);
      if (!mounted || _patientId != patientId) return;
      result.when(
        success: (docs) {
          final List<Staff> activeDocs = docs.where((s) => s.isActive).toList();
          _prepopulateAssignedDoctors(activeDocs);
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
      if (!mounted || _patientId != patientId) return;
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
      if (!mounted || _patientId != patientId) return;
      _mutate(() {
        _isFetchingDoctors = false;
        _doctorFieldEnabled = true;
      });
    }
  }

  void _prepopulateAssignedDoctors(List<Staff> docs) {
    final sorted = List<Staff>.from(docs)
      ..sort((a, b) {
        if (a.id == widget.preselectedDoctorId) return -1;
        if (b.id == widget.preselectedDoctorId) return 1;
        return a.fullName.compareTo(b.fullName);
      });

    _doctorFieldKey.currentState?.didChange(sorted);
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
