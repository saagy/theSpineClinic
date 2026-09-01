library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_card.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

/// Tab displaying the list of rehabilitation programs for a patient.
class PatientTabPrograms extends ConsumerStatefulWidget {
  const PatientTabPrograms({super.key, required this.patient});

  final Patient patient;

  @override
  ConsumerState<PatientTabPrograms> createState() => _PatientTabProgramsState();
}

class _PatientTabProgramsState extends ConsumerState<PatientTabPrograms> {
  bool _showArchived = false;

  void _openProgramDetail(PatientProgram program) {
    context.push(
      AppRoutes.patientProgramDetail
          .replaceAll(':id', widget.patient.id)
          .replaceAll(':programId', program.id),
      extra: program,
    );
  }

  Widget _buildArchivedToggle(
    BuildContext context,
    int archivedCount,
    bool isExpanded,
  ) {
    final cs = Theme.of(context).colorScheme;
    final clinic = ClinicColors.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p8,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSizes.r16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: InkWell(
        onTap: () => setState(() => _showArchived = !_showArchived),
        borderRadius: BorderRadius.circular(AppSizes.r16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p16,
            vertical: AppSizes.p12,
          ),
          child: Row(
            children: [
              Icon(
                Icons.archive_outlined,
                size: AppSizes.iconSmall,
                color: clinic.neutral,
              ),
              const SizedBox(width: AppSizes.p8),
              Text(
                AppStrings.archivedProgramsCount(archivedCount),
                style: AppTextStyles.bodyBold.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: AppSizes.iconSmall,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<PatientProgram> activeAndCompleted,
    List<PatientProgram> archived,
  ) {
    final isExpanded = _showArchived || activeAndCompleted.isEmpty;
    final items = <Widget>[
      ...activeAndCompleted.map(
        (program) => ProgramCard(
          program: program,
          onTap: () => _openProgramDetail(program),
        ),
      ),
      if (archived.isNotEmpty) ...[
        _buildArchivedToggle(context, archived.length, isExpanded),
        if (isExpanded)
          ...archived.map(
            (program) => ProgramCard(
              program: program,
              onTap: () => _openProgramDetail(program),
            ),
          ),
      ],
    ];

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        top: AppSizes.p8,
        bottom: AppSizes.p24,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final bool isSenior = user?.isSeniorDoctor ?? false;
    final programsAsync = ref.watch(patientProgramsProvider(widget.patient.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isSenior)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.p16,
              AppSizes.p12,
              AppSizes.p16,
              AppSizes.p4,
            ),
            child: AppButton(
              labelText: AppStrings.newProgram,
              icon: Icons.add,
              shape: AppButtonShape.pill,
              onPressed: () => context.push(
                AppRoutes.newPatientProgram
                    .replaceAll(':id', widget.patient.id),
                extra: widget.patient,
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref
                .read(patientProgramsProvider(widget.patient.id).notifier)
                .refresh(),
            child: programsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSizes.p16),
                child: SkeletonTileList(count: 3),
              ),
              error: (err, _) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.p24),
                  child: ErrorView(
                    exception: err is AppException
                        ? err
                        : AppException.fromSupabaseException(err),
                    onRetry: () => ref
                        .read(
                          patientProgramsProvider(widget.patient.id).notifier,
                        )
                        .refresh(),
                  ),
                ),
              ),
              data: (programs) {
                if (programs.isEmpty) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSizes.p48),
                      child: EmptyState(
                        message: AppStrings.noProgramsRecorded,
                        icon: Icons.assignment_outlined,
                        actionLabel: isSenior ? AppStrings.newProgram : null,
                        onActionPressed: isSenior
                            ? () => context.push(
                                  AppRoutes.newPatientProgram
                                      .replaceAll(':id', widget.patient.id),
                                  extra: widget.patient,
                                )
                            : null,
                      ),
                    ),
                  );
                }

                final activeAndCompleted = programs
                    .where((p) => p.status != ProgramStatus.archived)
                    .toList();
                final archived = programs
                    .where((p) => p.status == ProgramStatus.archived)
                    .toList();

                return _buildList(context, activeAndCompleted, archived);
              },
            ),
          ),
        ),
      ],
    );
  }
}
