library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_history_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/program_controller.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/services/program_pdf_service.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_status_badge.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

/// Top header banner displaying program regions, interactive status badge, and clinical actions.
class ProgramDetailHeader extends ConsumerWidget {
  const ProgramDetailHeader({super.key, required this.program});

  final PatientProgram program;

  Future<void> _changeStatus(BuildContext context, WidgetRef ref, ProgramStatus newStatus) async {
    final result = await ref.read(programControllerProvider.notifier).updateStatus(
          programId: program.id,
          patientId: program.patientId,
          status: newStatus,
        );

    if (!context.mounted) return;
    result.when(
      success: (_) => AppSnackbar.show(context, message: AppStrings.programSaved, variant: AppSnackbarVariant.success),
      failure: (e) => AppSnackbar.show(context, message: AppStrings.fromKey(e.userMessageKey), variant: AppSnackbarVariant.error),
    );
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref) async {
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

  Future<void> _deleteProgram(BuildContext context, WidgetRef ref) async {
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

  Widget _buildStatusChip(BuildContext context, WidgetRef ref, bool isSenior) {
    if (!isSenior) return ProgramStatusBadge(status: program.status);

    return PopupMenuButton<ProgramStatus>(
      tooltip: AppStrings.setStatus,
      onSelected: (st) => _changeStatus(context, ref, st),
      itemBuilder: (ctx) => [
        PopupMenuItem(value: ProgramStatus.active, child: Text(AppStrings.setStatusLabel(AppStrings.programActive))),
        PopupMenuItem(value: ProgramStatus.completed, child: Text(AppStrings.setStatusLabel(AppStrings.programCompleted))),
        PopupMenuItem(value: ProgramStatus.archived, child: Text(AppStrings.setStatusLabel(AppStrings.programArchived))),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProgramStatusBadge(status: program.status),
          const SizedBox(width: AppSizes.p2),
          const Icon(Icons.arrow_drop_down, size: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isSenior = ref.watch(currentUserProvider).value?.isSeniorDoctor ?? false;
    final title = program.affectedRegions.isNotEmpty
        ? program.affectedRegions.map((r) => r.displayName).join(' · ')
        : AppStrings.program;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSizes.r16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSizes.p8,
              runSpacing: AppSizes.p4,
              children: [
                Text(title, style: AppTextStyles.headingSmall.copyWith(color: cs.onSurface)),
                _buildStatusChip(context, ref, isSenior),
                Text(
                  '•  ${AppStrings.createdLabel(Formatters.formatDateMedium(program.createdAt))}',
                  style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            tooltip: AppStrings.exportPdf,
            onPressed: () => _exportPdf(context, ref),
          ),
          if (isSenior) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: AppStrings.edit,
              onPressed: () => context.push(
                AppRoutes.editPatientProgram.replaceAll(':id', program.patientId).replaceAll(':programId', program.id),
                extra: program,
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
              tooltip: AppStrings.delete,
              onPressed: () => _deleteProgram(context, ref),
            ),
          ],
        ],
      ),
    );
  }
}
