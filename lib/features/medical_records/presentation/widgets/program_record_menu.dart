import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/program_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/record_action_menu.dart';

/// Program-level actions, shared by the patient list and program detail.
class ProgramRecordMenu extends ConsumerWidget {
  const ProgramRecordMenu({super.key, required this.program, this.inDetail = false});
  final PatientProgram program;
  final bool inDetail;

  Future<void> _select(BuildContext context, WidgetRef ref, String action) async {
    if (action == 'view') {
      context.push(
        AppRoutes.patientProgramDetail.replaceAll(':id', program.patientId).replaceAll(':programId', program.id),
        extra: program,
      );
      return;
    }
    final user = ref.read(currentUserProvider).value;
    if (user?.isActive != true || user?.isSeniorDoctor != true) return;
    if (action == 'edit') {
      context.push(
        AppRoutes.editPatientProgram.replaceAll(':id', program.patientId).replaceAll(':programId', program.id),
        extra: program,
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(
        title: AppStrings.deleteProgram,
        message: AppStrings.deleteProgramConfirm,
        confirmLabel: AppStrings.delete,
        isDestructive: true,
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await ref
        .read(programControllerProvider.notifier)
        .deleteProgram(programId: program.id, patientId: program.patientId);
    if (!context.mounted) return;
    result.when(
      success: (_) {
        AppSnackbar.show(context, message: AppStrings.programDeleted, variant: AppSnackbarVariant.success);
        if (inDetail) context.pop();
      },
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
    final canEdit = user?.isActive == true && user?.isSeniorDoctor == true;
    if (inDetail && !canEdit) return const SizedBox.shrink();
    return RecordActionMenu<String>(
      tooltip: AppStrings.programActions,
      enabled: !ref.watch(programControllerProvider).isLoading,
      actions: [
        if (!inDetail) const RecordMenuAction('view', AppStrings.viewDetails, Icons.open_in_new),
        if (canEdit && !inDetail) const RecordMenuAction('edit', AppStrings.editProgramDetails, Icons.edit_outlined),
        if (canEdit)
          const RecordMenuAction('delete', AppStrings.deleteProgram, Icons.delete_outline, destructive: true),
      ],
      onSelected: (action) => _select(context, ref, action),
    );
  }
}
