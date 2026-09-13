part of 'new_patient_form.dart';

extension _NewPatientView on _NewPatientFormState {
  Widget _buildAttachmentsList(bool isSaving, ColorScheme cs) {
    if (_selectedFiles.isEmpty) {
      return Text(
        AppStrings.noDocumentsSelected,
        style: AppTextStyles.bodySecondary.copyWith(color: ClinicColors.of(context).textMuted),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _selectedFiles.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.p4),
      itemBuilder: (context, index) {
        final PlatformFile file = _selectedFiles[index];
        final AttachmentStatus status = ref.watch(indexedAttachmentStatusProvider(index));
        final String ext = p.extension(file.name).toLowerCase();
        final bool isImage = const ['.png', '.jpg', '.jpeg'].contains(ext);
        return _AttachmentRow(
          file: file,
          isImage: isImage,
          status: status,
          onRemove: isSaving ? null : () => _removeFile(index),
          cs: cs,
        );
      },
    );
  }

  String get _uploadingLabel {
    int uploading = 0;
    for (int i = 0; i < _selectedFiles.length; i++) {
      final s = ref.read(indexedAttachmentStatusProvider(i));
      if (s == AttachmentStatus.uploading) {
        uploading++;
      }
    }
    return AppStrings.attachmentsRemaining(uploading);
  }

  Widget _buildForm(BuildContext context) {
    final isSaving = ref.watch(newPatientControllerProvider).isLoading;
    final cs = Theme.of(context).colorScheme;
    return FormBuilder(
      key: _formKey,
      enabled: !isSaving,
      child: FormPageBody(
        isSaving: isSaving,
        onSave: _handleSave,
        onCancel: _handleCancel,
        saveLabel: AppStrings.registerPatient,
        child: FormColumns(
          first: FormSection(
            title: AppStrings.patientDetails,
            child: PatientFormFields(enabled: !isSaving),
          ),
          second: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormSection(
                title: AppStrings.assignedDoctors,
                child: FormBuilderField<List<Staff>>(
                  name: 'assigned_doctors',
                  initialValue: const [],
                  builder: (state) => DoctorSelectField(
                    enabled: !isSaving,
                    initialValue: List<Staff>.from(state.value ?? []),
                    onSavedDoctors: state.didChange,
                    onChanged: state.didChange,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.p20),
              FormSection(
                title: AppStrings.attachments,
                action: TextButton.icon(
                  onPressed: isSaving ? null : _pickFiles,
                  icon: const Icon(Icons.attach_file_rounded, size: AppSizes.iconSmall),
                  label: const Text(AppStrings.add),
                ),
                child: _buildAttachmentsList(isSaving, cs),
              ),
              if (isSaving && _selectedFiles.isNotEmpty) ...[
                const SizedBox(height: AppSizes.p12),
                Text(_uploadingLabel, style: AppTextStyles.caption),
                const SizedBox(height: AppSizes.p4),
                LinearProgressIndicator(color: cs.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
