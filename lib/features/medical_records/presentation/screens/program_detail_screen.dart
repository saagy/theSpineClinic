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
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_detail_conditions.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_detail_findings.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_detail_header.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_detail_treatment.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

/// Screen displaying comprehensive details of a single rehabilitation program.
class ProgramDetailScreen extends ConsumerWidget {
  const ProgramDetailScreen({
    super.key,
    required this.patientId,
    required this.programId,
    this.initialProgram,
  });

  final String patientId;
  final String programId;
  final PatientProgram? initialProgram;

  Future<void> _exportPdf(BuildContext context, WidgetRef ref, PatientProgram program) async {
    try {
      final patient = await ref.read(patientDetailProvider(program.patientId).future);
      final history = await ref.read(patientMedicalHistoryProvider(program.patientId).future);
      await ProgramPdfService.printProgramReport(program: program, patient: patient, medicalHistory: history);
    } catch (e, st) {
      debugPrint('PDF export error: $e\n$st');
      if (context.mounted) {
        AppSnackbar.show(context, message: AppStrings.pdfExportError, variant: AppSnackbarVariant.error);
      }
    }
  }

  Future<void> _deleteProgram(BuildContext context, WidgetRef ref, PatientProgram program) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => const ConfirmationDialog(
        title: AppStrings.deleteProgram,
        message: AppStrings.deleteProgramConfirm,
        isDestructive: true,
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref.read(programControllerProvider.notifier).deleteProgram(
          programId: program.id,
          patientId: program.patientId,
        );

    if (!context.mounted) return;
    result.when(
      success: (_) {
        AppSnackbar.show(context, message: AppStrings.programDeleted, variant: AppSnackbarVariant.success);
        context.pop();
      },
      failure: (e) => AppSnackbar.show(context, message: AppStrings.fromKey(e.userMessageKey), variant: AppSnackbarVariant.error),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context, WidgetRef ref, PatientProgram? program) {
    if (program == null) return const [];
    final cs = Theme.of(context).colorScheme;
    final isSenior = ref.watch(currentUserProvider).value?.isSeniorDoctor ?? false;

    return [
      IconButton(
        icon: const Icon(Icons.picture_as_pdf_outlined),
        tooltip: AppStrings.exportPdf,
        onPressed: () => _exportPdf(context, ref, program),
      ),
      if (isSenior) ...[
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: AppStrings.edit,
          onPressed: () => context.push(
            AppRoutes.editPatientProgram.replaceAll(':id', program.patientId).replaceAll(':programId', program.id),
            extra: program,
          ),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline, color: cs.error),
          tooltip: AppStrings.delete,
          onPressed: () => _deleteProgram(context, ref, program),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(programDetailProvider(programId));
    final program = asyncDetail.value ?? initialProgram;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text(AppStrings.programDetails),
        actions: _buildAppBarActions(context, ref, program),
      ),
      body: SafeArea(
        child: asyncDetail.when(
          loading: () {
            if (initialProgram != null) return _buildResponsiveLayout(context, initialProgram!);
            return const Padding(padding: EdgeInsets.all(AppSizes.p16), child: SkeletonTileList(count: 4));
          },
          error: (err, _) {
            if (initialProgram != null) return _buildResponsiveLayout(context, initialProgram!);
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.p24),
                child: ErrorView(
                  exception: err is AppException ? err : AppException.fromSupabaseException(err),
                  onRetry: () => ref.invalidate(programDetailProvider(programId)),
                ),
              ),
            );
          },
          data: (prog) {
            final effective = prog ?? initialProgram;
            if (effective == null) {
              return const EmptyState(message: AppStrings.programNotFound, icon: Icons.search_off_rounded);
            }
            return _buildResponsiveLayout(context, effective);
          },
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(BuildContext context, PatientProgram program) {
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
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            ProgramDetailConditions(program: program),
                            const SizedBox(height: AppSizes.p16),
                            ProgramDetailFindings(program: program),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSizes.p16),
                      Expanded(
                        flex: 6,
                        child: ProgramDetailTreatment(program: program),
                      ),
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
