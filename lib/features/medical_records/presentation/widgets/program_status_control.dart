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

class ProgramStatusControl extends ConsumerWidget {
  const ProgramStatusControl({super.key, required this.program});
  final PatientProgram program;

  Future<void> _change(BuildContext context, WidgetRef ref, ProgramStatus status) async {
    final user = ref.read(currentUserProvider).value;
    if (user?.isActive != true || user?.isSeniorDoctor != true || status == program.status) return;
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
    return PopupMenuButton<ProgramStatus>(
      tooltip: AppStrings.changeProgramStatus,
      enabled: !busy,
      onSelected: (status) => _change(context, ref, status),
      itemBuilder: (_) => [
        for (final status in ProgramStatus.values)
          CheckedPopupMenuItem(
            value: status,
            checked: status == program.status,
            enabled: status != program.status,
            height: AppSizes.tappableMin,
            child: Text(
              status == program.status
                  ? label
                  : switch (status) {
                      ProgramStatus.active => AppStrings.reactivateProgram,
                      ProgramStatus.completed => AppStrings.completeProgram,
                      ProgramStatus.archived => AppStrings.archiveProgram,
                    },
              style: AppTextStyles.bodyMedium,
            ),
          ),
      ],
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
