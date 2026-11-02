import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/program_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/record_action_menu.dart';

class ProgramStatusControl extends ConsumerWidget {
  const ProgramStatusControl({super.key, required this.program});
  final PatientProgram program;

  static Future<void> show(BuildContext context, WidgetRef ref, PatientProgram program) async {
    final user = ref.read(currentUserProvider).value;
    if (user?.isActive != true || user?.isSeniorDoctor != true || ref.read(programControllerProvider).isLoading) {
      return;
    }
    final status = await RecordActionMenu.show<ProgramStatus>(context, actions: _actions(program));
    if (status == null || !context.mounted) return;
    await _change(context, ref, program, status);
  }

  static List<RecordMenuAction<ProgramStatus>> _actions(PatientProgram program) => [
    for (final status in ProgramStatus.values)
      RecordMenuAction(
        status,
        status == program.status
            ? AppStrings.programStatusLabel(status.displayLabel)
            : switch (status) {
                ProgramStatus.active => AppStrings.reactivateProgram,
                ProgramStatus.completed => AppStrings.completeProgram,
                ProgramStatus.archived => AppStrings.archiveProgram,
              },
        status == program.status
            ? Icons.check
            : switch (status) {
                ProgramStatus.active => Icons.play_circle_outline,
                ProgramStatus.completed => Icons.task_alt,
                ProgramStatus.archived => Icons.archive_outlined,
              },
        enabled: status != program.status,
      ),
  ];

  static Future<void> _change(BuildContext context, WidgetRef ref, PatientProgram program, ProgramStatus status) async {
    final user = ref.read(currentUserProvider).value;
    if (user?.isActive != true ||
        user?.isSeniorDoctor != true ||
        status == program.status ||
        ref.read(programControllerProvider).isLoading) {
      return;
    }
    final result = await ref
        .read(programControllerProvider.notifier)
        .updateStatus(programId: program.id, patientId: program.patientId, status: status);
    if (!context.mounted) return;
    result.when(
      success: (_) => AppSnackbar.show(
        context,
        message: AppStrings.programStatusUpdated(status.displayLabel),
        variant: AppSnackbarVariant.success,
      ),
      failure: (error) => AppSnackbar.show(
        context,
        message: AppStrings.fromKey(error.userMessageKey),
        variant: AppSnackbarVariant.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final label = AppStrings.programStatusLabel(program.status.displayLabel);
    if (user?.isActive != true || user?.isSeniorDoctor != true) {
      return Text(label, style: AppTextStyles.bodyBold);
    }
    final busy = ref.watch(programControllerProvider).isLoading;
    final cs = Theme.of(context).colorScheme;
    return RecordActionMenu<ProgramStatus>(
      tooltip: AppStrings.changeProgramStatus,
      enabled: !busy,
      onSelected: (status) => _change(context, ref, program, status),
      actions: _actions(program),
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.tappableMin),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12, vertical: AppSizes.p8),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(AppSizes.r8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(label, style: AppTextStyles.bodyBold.copyWith(color: cs.primary)),
            ),
            const SizedBox(width: AppSizes.p8),
            Icon(Icons.expand_more, size: AppSizes.iconSmall, color: cs.primary),
          ],
        ),
      ),
    );
  }
}
