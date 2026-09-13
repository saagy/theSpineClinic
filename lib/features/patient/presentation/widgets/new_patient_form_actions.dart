part of 'new_patient_form.dart';

extension _NewPatientActions on _NewPatientFormState {
  bool _isFormDirty() {
    final FormBuilderState? state = _formKey.currentState;
    if (state == null) return false;
    final Map<String, dynamic> values = state.instantValue;
    final bool hasName = (values['full_name'] as String?)?.isNotEmpty == true;
    final bool hasPhone = (values['phone_number'] as String?)?.isNotEmpty == true;
    final bool hasDoctors = (values['assigned_doctors'] as List?)?.isNotEmpty == true;
    return hasName || hasPhone || hasDoctors || _selectedFiles.isNotEmpty;
  }

  Future<void> _handleCancel() async {
    if (_isFormDirty()) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => const ConfirmationDialog(
          title: AppStrings.discardChanges,
          message: AppStrings.discardChangesMessage,
          confirmLabel: AppStrings.discard,
          cancelLabel: AppStrings.keepEditing,
          isDestructive: true,
        ),
      );
      if (confirm == true && mounted) context.pop();
    } else {
      context.pop();
    }
  }

  Future<void> _handleSave() async {
    final FormBuilderState? state = _formKey.currentState;
    if (state == null || !state.saveAndValidate()) return;

    final String fullName = state.fields['full_name']!.value as String;
    final String phoneNumber = state.fields['phone_number']!.value as String;
    final ClinicLocation clinic = state.fields['clinic']!.value as ClinicLocation;
    final assignedDoctors = state.fields['assigned_doctors']!.value as List<Staff>;

    final List<String> assignedDoctorIds = assignedDoctors.map((d) => d.id).toList();

    final Result<Patient> result = await ref
        .read(newPatientControllerProvider.notifier)
        .createPatient(
          fullName: fullName.trim(),
          phoneNumber: phoneNumber.trim(),
          clinic: clinic,
          assignedDoctorIds: assignedDoctorIds,
          attachments: _selectedFiles,
        );

    if (!mounted) return;

    result.when(
      success: (Patient createdPatient) {
        // Inspect per-attachment status providers to know whether all
        // uploads succeeded or only some did.
        int failedCount = 0;
        for (int i = 0; i < _selectedFiles.length; i++) {
          final AttachmentStatus s = ref.read(indexedAttachmentStatusProvider(i));
          if (s == AttachmentStatus.failed) failedCount++;
        }
        if (failedCount > 0) {
          AppSnackbar.show(
            context,
            message: AppStrings.errorAttachmentPartialFail,
            variant: AppSnackbarVariant.error,
          );
        } else {
          AppSnackbar.show(
            context,
            message: AppStrings.patientRegistered,
            variant: AppSnackbarVariant.success,
          );
        }
        context.go(AppRoutes.patientDetail.replaceAll(':id', createdPatient.id));
      },
      failure: (AppException error) {
        AppSnackbar.show(
          context,
          message: AppStrings.fromKey(error.userMessageKey),
          variant: AppSnackbarVariant.error,
        );
      },
    );
  }
}
