library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/program_controller.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_status_badge.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

/// Top header summary card displaying program regions, interactive status badge, and creation date.
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

  Widget _buildStatusChip(BuildContext context, WidgetRef ref, bool isSenior) {
    if (!isSenior) return ProgramStatusBadge(status: program.status);

    final cs = Theme.of(context).colorScheme;
    final clinic = ClinicColors.of(context);

    PopupMenuItem<ProgramStatus> buildItem(ProgramStatus st, IconData icon, Color color, String label) {
      final isCurrent = program.status == st;
      return PopupMenuItem<ProgramStatus>(
        value: st,
        height: AppSizes.buttonHeightSmall,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSizes.iconSmall, color: color),
            const SizedBox(width: AppSizes.p8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isCurrent ? color : cs.onSurface,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isCurrent) ...[
              const SizedBox(width: AppSizes.p8),
              Icon(Icons.check_rounded, size: 16, color: color),
            ],
          ],
        ),
      );
    }

    return PopupMenuButton<ProgramStatus>(
      tooltip: AppStrings.setStatus,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      splashRadius: AppSizes.iconDefault,
      color: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r12)),
      ),
      elevation: 2,
      position: PopupMenuPosition.under,
      onSelected: (st) {
        if (st != program.status) {
          _changeStatus(context, ref, st);
        }
      },
      itemBuilder: (ctx) => [
        buildItem(ProgramStatus.active, Icons.play_circle_outline_rounded, cs.primary, AppStrings.programActive),
        buildItem(ProgramStatus.completed, Icons.task_alt_rounded, clinic.success, AppStrings.programCompleted),
        buildItem(ProgramStatus.archived, Icons.archive_outlined, clinic.neutral, AppStrings.programArchived),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProgramStatusBadge(status: program.status),
          const SizedBox(width: AppSizes.p2),
          Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: cs.onSurfaceVariant),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p14),
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
              spacing: AppSizes.p10,
              runSpacing: AppSizes.p6,
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
        ],
      ),
    );
  }
}
