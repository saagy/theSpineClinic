import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/program_controller.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_status_badge.dart';
import 'package:spine_clinic_app/shared/widgets/record_action_menu.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

class ProgramDetailHeader extends ConsumerWidget {
  const ProgramDetailHeader({super.key, required this.program});
  final PatientProgram program;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final cs = Theme.of(context).colorScheme;
    final title = program.affectedRegions.isEmpty
        ? AppStrings.program
        : program.affectedRegions.map((r) => r.displayName).join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.p16),
      padding: const EdgeInsets.all(AppSizes.p20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.r12),
        border: Border.all(color: cs.outlineVariant.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.headingLarge.copyWith(color: cs.onSurface),
                ),
              ),
              if (user?.isActive == true && user?.isSeniorDoctor == true)
                RecordActionMenu<ProgramStatus>(
                  tooltip: AppStrings.setStatus,
                  actions: const [
                    RecordMenuAction(ProgramStatus.active, AppStrings.programActive, Icons.play_circle_outline),
                    RecordMenuAction(ProgramStatus.completed, AppStrings.programCompleted, Icons.task_alt),
                    RecordMenuAction(ProgramStatus.archived, AppStrings.programArchived, Icons.archive_outlined),
                  ],
                  onSelected: (status) async {
                    final currentUser = ref.read(currentUserProvider).value;
                    if (currentUser?.isActive != true || currentUser?.isSeniorDoctor != true || status == program.status) {
                      return;
                    }
                    final result = await ref
                        .read(programControllerProvider.notifier)
                        .updateStatus(programId: program.id, patientId: program.patientId, status: status);
                    if (!context.mounted) return;
                    result.when(
                      success: (_) => AppSnackbar.show(context, message: AppStrings.programSaved, variant: AppSnackbarVariant.success),
                      failure: (e) => AppSnackbar.show(context, message: AppStrings.fromKey(e.userMessageKey), variant: AppSnackbarVariant.error),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSizes.p12),
          Wrap(
            spacing: AppSizes.p10,
            runSpacing: AppSizes.p6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ProgramStatusBadge(status: program.status),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p2),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh.withAlpha(120),
                  borderRadius: BorderRadius.circular(AppSizes.r6),
                ),
                child: Text(
                  AppStrings.createdLabel(Formatters.formatDateMedium(program.createdAt)),
                  style: AppTextStyles.captionBold.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
