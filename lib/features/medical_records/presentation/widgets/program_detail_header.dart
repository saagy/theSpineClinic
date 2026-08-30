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
import 'package:spine_clinic_app/features/medical_records/presentation/program_controller.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_status_badge.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

/// Top header card for the Program Detail screen displaying status, date, and actions.
class ProgramDetailHeader extends ConsumerWidget {
  const ProgramDetailHeader({super.key, required this.program});

  final PatientProgram program;

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    ProgramStatus newStatus,
  ) async {
    final result = await ref
        .read(programControllerProvider.notifier)
        .updateStatus(
          programId: program.id,
          patientId: program.patientId,
          status: newStatus,
        );

    if (!context.mounted) return;
    result.when(
      success: (_) => AppSnackbar.show(
        context,
        message: AppStrings.programSaved,
        variant: AppSnackbarVariant.success,
      ),
      failure: (e) => AppSnackbar.show(
        context,
        message: AppStrings.fromKey(e.userMessageKey),
        variant: AppSnackbarVariant.error,
      ),
    );
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

    final result = await ref
        .read(programControllerProvider.notifier)
        .deleteProgram(
          programId: program.id,
          patientId: program.patientId,
        );

    if (!context.mounted) return;
    result.when(
      success: (_) {
        AppSnackbar.show(
          context,
          message: 'Program deleted.',
          variant: AppSnackbarVariant.success,
        );
        context.pop();
      },
      failure: (e) => AppSnackbar.show(
        context,
        message: AppStrings.fromKey(e.userMessageKey),
        variant: AppSnackbarVariant.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider).value;
    final bool isSenior = user?.isSeniorDoctor ?? false;

    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSizes.r16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rehabilitation Episode',
                style: AppTextStyles.cardTitle.copyWith(color: cs.onSurface),
              ),
              ProgramStatusBadge(status: program.status),
            ],
          ),
          const SizedBox(height: AppSizes.p8),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: AppSizes.iconSmall,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: AppSizes.p6),
              Text(
                'Created: ${Formatters.formatDateLong(program.createdAt)}',
                style: AppTextStyles.caption.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (isSenior) ...[
            const SizedBox(height: AppSizes.p12),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text(AppStrings.edit),
                  onPressed: () => context.push(
                    AppRoutes.editPatientProgram
                        .replaceAll(':id', program.patientId)
                        .replaceAll(':programId', program.id),
                    extra: program,
                  ),
                ),
                const SizedBox(width: AppSizes.p8),
                PopupMenuButton<ProgramStatus>(
                  onSelected: (st) => _changeStatus(context, ref, st),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: ProgramStatus.active,
                      child: Text('Set Active'),
                    ),
                    const PopupMenuItem(
                      value: ProgramStatus.completed,
                      child: Text('Set Completed'),
                    ),
                    const PopupMenuItem(
                      value: ProgramStatus.archived,
                      child: Text('Set Archived'),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p12,
                      vertical: AppSizes.p8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: cs.outlineVariant),
                      borderRadius: BorderRadius.circular(AppSizes.r8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Status', style: AppTextStyles.captionBold),
                        const Icon(Icons.arrow_drop_down, size: 18),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: cs.error),
                  onPressed: () => _deleteProgram(context, ref),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
