part of 'program_form_screen.dart';

extension _ProgramFormView on _ProgramFormScreenState {
  Widget _buildForm(BuildContext context) {
    final isEdit = widget.program != null;
    final programId = widget.program?.id;
    final List<PatientDocument> existingDocs = programId != null
        ? ref
                  .watch(
                    programDocumentsProvider(patientId: widget.patientId, programId: programId),
                  )
                  .value ??
              []
        : const [];

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(isEdit ? AppStrings.editProgram : AppStrings.newProgram),
      ),
      body: Form(
        key: _formKey,
        child: FormPageBody(
          isSaving: _isSubmitting,
          onSave: _submit,
          onCancel: _close,
          saveLabel: isEdit ? AppStrings.saveChanges : AppStrings.saveAndPrescribePlan,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProgramConditionSelector(
                selectedConditions: _selectedConditions,
                onConditionsChanged: (items) => _mutate(() => _selectedConditions = items),
              ),
              const SizedBox(height: AppSizes.p16),
              ProgramClinicalInputs(
                examinationController: _examinationController,
                imagingNotesController: _imagingNotesController,
                exaggeratingPositionsController: _exaggeratingPositionsController,
                relievingPositionsController: _relievingPositionsController,
                notesController: _notesController,
                pendingFiles: _pendingFiles,
                existingDocuments: existingDocs,
                onPendingFilesChanged: (files) => _mutate(() => _pendingFiles = files),
                onDeleteExistingDocument: (doc) => ref
                    .read(patientDocumentsNotifierProvider(widget.patientId).notifier)
                    .deleteDocument(doc),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
