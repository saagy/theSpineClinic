part of 'program_detail_screen.dart';

extension _ProgramDetailActions on _ProgramDetailScreenState {
  Future<void> _exportPdf(PatientProgram program) async {
    try {
      final patient = await ref.read(patientDetailProvider(program.patientId).future);
      final history = await ref.read(patientMedicalHistoryProvider(program.patientId).future);
      await ProgramPdfService.printProgramReport(program: program, patient: patient, medicalHistory: history);
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(context, message: AppStrings.pdfExportError, variant: AppSnackbarVariant.error);
      }
    }
  }

  Future<void> _deleteProgram(PatientProgram program) async {
    final user = ref.read(currentUserProvider).value;
    if (user?.isActive != true || user?.isSeniorDoctor != true) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => const ConfirmationDialog(
        title: AppStrings.deleteProgram,
        message: AppStrings.deleteProgramConfirm,
        isDestructive: true,
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await ref
        .read(programControllerProvider.notifier)
        .deleteProgram(programId: program.id, patientId: program.patientId);
    if (!mounted) return;
    result.when(
      success: (_) {
        AppSnackbar.show(context, message: AppStrings.programDeleted, variant: AppSnackbarVariant.success);
        context.pop();
      },
      failure: (e) => AppSnackbar.show(
        context,
        message: AppStrings.fromKey(e.userMessageKey),
        variant: AppSnackbarVariant.error,
      ),
    );
  }

  List<Widget> _buildAppBarActions(PatientProgram? program, {required bool isDeleting}) {
    if (program == null || isDeleting) return const [];
    final user = ref.watch(currentUserProvider).value;
    final isSenior = user?.isActive == true && user?.isSeniorDoctor == true;

    return [
      IconButton(
        icon: const Icon(Icons.picture_as_pdf_outlined),
        tooltip: AppStrings.exportPdf,
        onPressed: () => _exportPdf(program),
      ),
      if (isSenior) ...[
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: AppStrings.edit,
          onPressed: () {
            final user = ref.read(currentUserProvider).value;
            if (user?.isActive != true || user?.isSeniorDoctor != true) return;
            context.push(
              AppRoutes.editPatientProgram
                  .replaceAll(':id', program.patientId)
                  .replaceAll(':programId', program.id),
              extra: program,
            );
          },
        ),
        RecordActionMenu<String>(
          actions: const [
            RecordMenuAction('delete', AppStrings.deleteProgram, Icons.delete_outline, destructive: true),
          ],
          onSelected: (_) => _deleteProgram(program),
        ),
      ],
    ];
  }

}
