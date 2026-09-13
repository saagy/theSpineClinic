part of 'edit_patient_form.dart';

extension _EditPatientView on _EditPatientFormState {
  Widget _buildForm(BuildContext context) {
    final isSaving = ref.watch(editPatientControllerProvider).isLoading;
    final user = ref.watch(currentUserProvider).value;
    final isRegularDoctor = user?.role == UserRole.doctor && !(user?.isSeniorDoctor ?? false);

    ref.listen<AsyncValue<void>>(editPatientControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          if (previous?.isLoading != true) return;
          AppSnackbar.show(
            context,
            message: AppStringsAuth.patientUpdatedSuccess,
            variant: AppSnackbarVariant.success,
          );
          _leaveForm();
        },
        error: (error, _) {
          final ex = error is AppException ? error : UnknownException(message: error.toString());
          AppSnackbar.show(
            context,
            message: AppStrings.fromKey(ex.userMessageKey),
            variant: AppSnackbarVariant.error,
          );
        },
      );
    });

    return PopScope(
      canPop: _allowPop || (!_hasChanges() && !isSaving),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || isSaving) return;
        await _handleCancel();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text(AppStrings.editPatient),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: isSaving ? null : _handleCancel,
          ),
        ),
        body: LoadingOverlay(
          isLoading: isSaving,
          child: Form(
            key: _formKey,
            child: FormPageBody(
              isSaving: isSaving,
              onSave: _submit,
              onCancel: _handleCancel,
              child: FormColumns(
                first: FormSection(
                  title: AppStrings.patientDetails,
                  child: PatientDemographicFields(
                    nameCtrl: _nameCtrl,
                    phoneCtrl: _phoneCtrl,
                    selectedClinic: _selectedClinic,
                    onClinicChanged: (val) => _mutate(() => _selectedClinic = val),
                    enabled: !isSaving,
                  ),
                ),
                second: FormSection(
                  title: AppStrings.assignedDoctors,
                  child: isRegularDoctor
                      ? Wrap(
                          spacing: AppSizes.p8,
                          runSpacing: AppSizes.p8,
                          children: _selectedDoctors
                              .map((doc) => AppChip(label: doc.fullName))
                              .toList(),
                        )
                      : DoctorSelectField(
                          initialValue: _selectedDoctors,
                          onSavedDoctors: (doctors) => _mutate(() {
                            _selectedDoctors.clear();
                            _selectedDoctors.addAll(doctors);
                          }),
                          onChanged: (doctors) => _mutate(() {
                            _selectedDoctors.clear();
                            _selectedDoctors.addAll(doctors);
                          }),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
