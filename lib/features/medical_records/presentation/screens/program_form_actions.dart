part of 'program_form_screen.dart';

extension _ProgramFormActions on _ProgramFormScreenState {
  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedConditions.isEmpty) {
      AppSnackbar.show(context, message: AppStrings.selectConditionRequired, variant: AppSnackbarVariant.info);
      return;
    }

    _mutate(() => _isSubmitting = true);
    final notifier = ref.read(programControllerProvider.notifier);
    final conditionIds = _selectedConditions.map((c) => c.id).toList();
    final attachments = _pendingFiles
        .where((f) => f.bytes != null)
        .map((f) => ProgramAttachment(fileName: f.name, bytes: f.bytes!))
        .toList();

    if (widget.program == null) {
      final result = await notifier.createProgram(
        patientId: widget.patientId,
        conditionIds: conditionIds,
        examination: _examinationController.text.trim(),
        imagingNotes: _imagingNotesController.text.trim(),
        exaggeratingPositions: _exaggeratingPositionsController.text.trim(),
        relievingPositions: _relievingPositionsController.text.trim(),
        notes: _notesController.text.trim(),
        pendingAttachments: attachments,
      );

      if (!mounted) return;
      _mutate(() => _isSubmitting = false);

      result.when(
        success: (program) {
          AppSnackbar.show(context, message: AppStrings.programSaved, variant: AppSnackbarVariant.success);
          final targetUrl = AppRoutes.patientProgramDetail
              .replaceAll(':id', widget.patientId)
              .replaceAll(':programId', program.id);
          context.pushReplacement('$targetUrl?openPlan=true', extra: program);
        },
        failure: _reportSaveFailure,
      );
    } else {
      final result = await notifier.updateProgram(
        programId: widget.program!.id,
        patientId: widget.patientId,
        conditionIds: conditionIds,
        examination: _examinationController.text.trim(),
        imagingNotes: _imagingNotesController.text.trim(),
        exaggeratingPositions: _exaggeratingPositionsController.text.trim(),
        relievingPositions: _relievingPositionsController.text.trim(),
        notes: _notesController.text.trim(),
        pendingAttachments: attachments,
        removedDocumentIds: ref.read(programDocumentDraftProvider(_formKey)).removedIds.toList(),
      );

      if (!mounted) return;
      _mutate(() => _isSubmitting = false);

      result.when(
        success: (_) {
          AppSnackbar.show(context, message: AppStrings.programSaved, variant: AppSnackbarVariant.success);
          _close();
        },
        failure: _reportSaveFailure,
      );
    }
  }

  void _reportSaveFailure(AppException error) {
    // The persistent form error leaves Retry reachable; preflight failures still need feedback.
    if (identical(ref.read(programControllerProvider).error, error)) return;
    AppSnackbar.show(context, message: AppStrings.fromKey(error.userMessageKey), variant: AppSnackbarVariant.error);
  }

  void _stageDocumentRemoval(PatientDocument document) {
    if (ref.read(programDocumentDraftProvider(_formKey).notifier).remove(document.id)) return;
    AppSnackbar.show(
      context,
      message: AppStrings.fromKey('error_permission_denied'),
      variant: AppSnackbarVariant.error,
    );
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      final program = widget.program;
      context.go(
        program == null
            ? AppRoutes.patientDetail.replaceAll(':id', widget.patientId)
            : AppRoutes.patientProgramDetail.replaceAll(':id', widget.patientId).replaceAll(':programId', program.id),
      );
    }
  }
}
