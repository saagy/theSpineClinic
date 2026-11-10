part of 'program_detail_screen.dart';

extension _ProgramDetailLayout on _ProgramDetailScreenState {
  Widget _buildLayout(PatientProgram program) {
    final user = ref.watch(currentUserProvider).value;
    final canEdit = user?.isActive == true && user?.isSeniorDoctor == true;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.clinicalContentMaxWidth),
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(programDetailProvider(widget.programId));
            await ref.read(programDetailProvider(widget.programId).future);
          },
          child: ListView(
            key: PageStorageKey('program-detail-${program.id}'),
            padding: const EdgeInsets.all(AppSizes.p16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (ref.watch(programDetailProvider(widget.programId)).hasError)
                RecordMessage(
                  message: AppStrings.patientSectionError,
                  action: AppStrings.retry,
                  onAction: () => ref.invalidate(programDetailProvider(widget.programId)),
                ),
              ProgramDetailHeader(program: program),
              ProgramDetailTreatment(program: program),
              RecordSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProgramDetailConditions(
                      program: program,
                      onEdit: canEdit ? () => _editProgram(program, ProgramEditSection.conditions) : null,
                    ),
                    ProgramDetailFindings(
                      program: program,
                      onEdit: canEdit ? () => _editProgram(program, ProgramEditSection.findings) : null,
                    ),
                    ProgramDetailDocuments(
                      program: program,
                      onEdit: canEdit ? () => _editProgram(program, ProgramEditSection.documents) : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
