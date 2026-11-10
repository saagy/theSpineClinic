part of 'program_detail_screen.dart';

extension _ProgramDetailActions on _ProgramDetailScreenState {
  void _editProgram(PatientProgram program, [ProgramEditSection? section]) {
    final user = ref.read(currentUserProvider).value;
    if (user?.isActive != true ||
        user?.isSeniorDoctor != true ||
        ref.read(programControllerProvider).isLoading ||
        ref.read(treatmentPlanControllerProvider).isLoading) {
      return;
    }
    final path = AppRoutes.editPatientProgram.replaceAll(':id', program.patientId).replaceAll(':programId', program.id);
    context.push(section == null ? path : '$path?section=${section.name}', extra: program);
  }

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

  List<Widget> _buildAppBarActions(PatientProgram? program, {required bool isDeleting}) {
    if (program == null || isDeleting) return const [];
    final user = ref.watch(currentUserProvider).value;
    final isSenior = user?.isActive == true && user?.isSeniorDoctor == true;

    return [
      if (isSenior)
        Tooltip(
          message: AppStrings.editProgramDetails,
          child: TextButton.icon(
            style: TextButton.styleFrom(minimumSize: const Size(AppSizes.tappableMin, AppSizes.tappableMin)),
            icon: const Icon(Icons.edit_outlined, size: AppSizes.iconSmall),
            label: Text(
              MediaQuery.sizeOf(context).width < AppSizes.desktopBreakpoint ? AppStrings.edit : AppStrings.editProgram,
              style: AppTextStyles.bodyMedium,
            ),
            onPressed: () => _editProgram(program),
          ),
        ),
      ProgramRecordMenu(program: program, inDetail: true, onExport: () => _exportPdf(program)),
    ];
  }
}
