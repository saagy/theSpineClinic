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
      if (isSenior) ProgramRecordMenu(program: program, inDetail: true),
    ];
  }
}
