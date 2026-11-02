part of 'program_form_screen.dart';

extension _ProgramFormView on _ProgramFormScreenState {
  Widget _buildForm(BuildContext context) {
    final isEdit = widget.program != null;
    final programId = widget.program?.id;
    final removedIds = ref.watch(programDocumentDraftProvider(_formKey)).removedIds;
    final mutation = ref.watch(programControllerProvider);
    final error = mutation.scope == ProgramMutationState.saveScope(widget.patientId, programId)
        ? mutation.error
        : null;
    final mustReview = error?.userMessageKey == 'program_attachments_rejected';
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
          hasDocumentUploads: _pendingFiles.isNotEmpty,
          savingLabel: _pendingFiles.isEmpty
              ? AppStrings.savingChanges
              : AppStrings.savingProgramAndDocuments,
          savingDetail: _pendingFiles.isEmpty ? null : AppStrings.keepPageOpen,
          errorMessage: error == null ? null : AppStrings.fromKey(error.userMessageKey),
          onSave: mustReview
              ? () => context.go(AppRoutes.patientDetail.replaceAll(':id', widget.patientId))
              : _submit,
          onCancel: _close,
          saveLabel: mustReview
              ? AppStrings.patientRecord
              : error != null
              ? AppStrings.retrySave
              : isEdit
              ? AppStrings.saveChanges
              : AppStrings.saveAndPrescribePlan,
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
                existingDocuments: existingDocs
                    .where((doc) => !removedIds.contains(doc.id))
                    .toList(),
                onPendingFilesChanged: (files) => _mutate(() => _pendingFiles = files),
                onDeleteExistingDocument: _stageDocumentRemoval,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
