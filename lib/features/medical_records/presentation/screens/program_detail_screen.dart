library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_history_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/program_controller.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/services/program_pdf_service.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/treatment_plan_controller.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_detail_conditions.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_detail_findings.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_detail_header.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_detail_treatment.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/treatment_plan_builder_sheet.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';
import 'package:spine_clinic_app/shared/widgets/record_action_menu.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

part 'program_detail_actions.dart';

/// Screen displaying comprehensive details of a single rehabilitation program.
class ProgramDetailScreen extends ConsumerStatefulWidget {
  const ProgramDetailScreen({
    super.key,
    required this.patientId,
    required this.programId,
    this.initialProgram,
    this.autoOpenPlanBuilder = false,
  });

  final String patientId;
  final String programId;
  final PatientProgram? initialProgram;
  final bool autoOpenPlanBuilder;

  @override
  ConsumerState<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}
class _ProgramDetailScreenState extends ConsumerState<ProgramDetailScreen> {
  bool _planBuilderOpened = false;

  void _checkAutoOpen(PatientProgram program) {
    final user = ref.read(currentUserProvider).value;
    if (user?.isActive != true || user?.isSeniorDoctor != true) return;
    if (widget.autoOpenPlanBuilder && !_planBuilderOpened) {
      _planBuilderOpened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ref.read(currentUserProvider).value?.isActive == true &&
            ref.read(currentUserProvider).value?.isSeniorDoctor == true) {
          TreatmentPlanBuilderSheet.show(
            context,
            programId: program.id,
            patientId: program.patientId,
            affectedRegions: program.affectedRegions,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDeleting = ref.watch(programControllerProvider).isLoading;
    final isPlanBusy = ref.watch(treatmentPlanControllerProvider).isLoading;
    final isBusy = isDeleting || isPlanBusy;
    final asyncDetail = ref.watch(programDetailProvider(widget.programId));
    final program = asyncDetail.hasValue ? asyncDetail.value : widget.initialProgram;
    if (program != null) _checkAutoOpen(program);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text(AppStrings.programDetails),
        actions: _buildAppBarActions(program, isDeleting: isBusy),
      ),
      bottomNavigationBar: isBusy
          ? const Padding(
              padding: EdgeInsets.all(AppSizes.p12),
              child: Text(AppStrings.savingClinicalRecord, textAlign: TextAlign.center),
            )
          : null,
      body: AbsorbPointer(
        absorbing: isBusy,
        child: SafeArea(
          child: asyncDetail.when(
            loading: () => program != null
                ? _buildLayout(program)
                : const Padding(padding: EdgeInsets.all(AppSizes.p16), child: SkeletonTileList(count: 4)),
            error: (err, _) => program != null
                ? _buildLayout(program)
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.p24),
                      child: ErrorView(
                        exception: err is AppException ? err : AppException.fromSupabaseException(err),
                        onRetry: () => ref.invalidate(programDetailProvider(widget.programId)),
                      ),
                    ),
                  ),
            data: (prog) {
              final effective = prog;
              if (effective == null) {
                return const EmptyState(message: AppStrings.programNotFound, icon: Icons.search_off_rounded);
              }
              return _buildLayout(effective);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLayout(PatientProgram program) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppSizes.clinicalContentMaxWidth),
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(programDetailProvider(widget.programId));
          await ref.read(programDetailProvider(widget.programId).future);
        },
        child: ListView(
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
            ProgramDetailConditions(program: program),
            ProgramDetailFindings(program: program),
          ],
        ),
      ),
    ),
  );
}
