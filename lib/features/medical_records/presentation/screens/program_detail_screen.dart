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
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

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
    if (widget.autoOpenPlanBuilder && !_planBuilderOpened) {
      _planBuilderOpened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
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

  Future<void> _exportPdf(PatientProgram program) async {
    try {
      final patient = await ref.read(patientDetailProvider(program.patientId).future);
      final history = await ref.read(patientMedicalHistoryProvider(program.patientId).future);
      await ProgramPdfService.printProgramReport(program: program, patient: patient, medicalHistory: history);
    } catch (_) {
      if (mounted) AppSnackbar.show(context, message: AppStrings.pdfExportError, variant: AppSnackbarVariant.error);
    }
  }

  Future<void> _deleteProgram(PatientProgram program) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => const ConfirmationDialog(title: AppStrings.deleteProgram, message: AppStrings.deleteProgramConfirm, isDestructive: true),
    );
    if (confirmed != true || !mounted) return;

    final result = await ref.read(programControllerProvider.notifier).deleteProgram(programId: program.id, patientId: program.patientId);
    if (!mounted) return;
    result.when(
      success: (_) {
        AppSnackbar.show(context, message: AppStrings.programDeleted, variant: AppSnackbarVariant.success);
        context.pop();
      },
      failure: (e) => AppSnackbar.show(context, message: AppStrings.fromKey(e.userMessageKey), variant: AppSnackbarVariant.error),
    );
  }

  List<Widget> _buildAppBarActions(PatientProgram? program, {required bool isDeleting}) {
    if (program == null || isDeleting) return const [];
    final cs = Theme.of(context).colorScheme;
    final isSenior = ref.watch(currentUserProvider).value?.isSeniorDoctor ?? false;

    return [
      IconButton(icon: const Icon(Icons.picture_as_pdf_outlined), tooltip: AppStrings.exportPdf, onPressed: () => _exportPdf(program)),
      if (isSenior) ...[
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: AppStrings.edit,
          onPressed: () => context.push(AppRoutes.editPatientProgram.replaceAll(':id', program.patientId).replaceAll(':programId', program.id), extra: program),
        ),
        IconButton(icon: Icon(Icons.delete_outline, color: cs.error), tooltip: AppStrings.delete, onPressed: () => _deleteProgram(program)),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDeleting = ref.watch(programControllerProvider).isLoading;
    final isPlanBusy = ref.watch(treatmentPlanControllerProvider).isLoading;
    final isBusy = isDeleting || isPlanBusy;
    final asyncDetail = ref.watch(programDetailProvider(widget.programId));
    final program = asyncDetail.value ?? widget.initialProgram;
    if (program != null) _checkAutoOpen(program);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text(AppStrings.programDetails),
        actions: _buildAppBarActions(program, isDeleting: isBusy),
      ),
      body: LoadingOverlay(
        isLoading: isBusy,
        child: SafeArea(
          child: asyncDetail.when(
            loading: () => program != null ? _buildLayout(program) : const Padding(padding: EdgeInsets.all(AppSizes.p16), child: SkeletonTileList(count: 4)),
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
              final effective = prog ?? widget.initialProgram;
              if (effective == null) return const EmptyState(message: AppStrings.programNotFound, icon: Icons.search_off_rounded);
              return _buildLayout(effective);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLayout(PatientProgram program) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 900;
        final maxW = isWide ? 1280.0 : AppSizes.formLayoutMaxWidth;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.p16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                ProgramDetailHeader(program: program),
                const SizedBox(height: AppSizes.p16),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: Column(children: [ProgramDetailConditions(program: program), const SizedBox(height: AppSizes.p16), ProgramDetailFindings(program: program)])),
                      const SizedBox(width: AppSizes.p16),
                      Expanded(flex: 6, child: ProgramDetailTreatment(program: program)),
                    ],
                  )
                else ...[
                  ProgramDetailConditions(program: program),
                  const SizedBox(height: AppSizes.p16),
                  ProgramDetailFindings(program: program),
                  const SizedBox(height: AppSizes.p16),
                  ProgramDetailTreatment(program: program),
                ],
                const SizedBox(height: AppSizes.p24),
              ],
            ),
          ),
        );
      },
    );
  }
}
