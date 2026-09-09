import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/delete_patient_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/record_action_menu.dart';

class WorkspacePatientMenu extends ConsumerWidget {
  const WorkspacePatientMenu({super.key, required this.patientId});
  final String patientId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null || (user.role == UserRole.doctor && !user.isSeniorDoctor)) {
      return const SizedBox.shrink();
    }
    final empty = ref.watch(patientIsEmptyProvider(patientId)).value ?? false;
    if (!empty) return const SizedBox.shrink();
    return RecordActionMenu<String>(
      actions: const [
        RecordMenuAction('delete', AppStrings.deletePatient, Icons.delete_outline, destructive: true),
      ],
      onSelected: (action) async {
        final user = ref.read(currentUserProvider).value;
        if (user == null || !user.isActive || (user.role == UserRole.doctor && !user.isSeniorDoctor)) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => const ConfirmationDialog(
            title: AppStrings.deletePatient,
            message: AppStrings.deletePatientWarning,
            confirmLabel: AppStrings.delete,
            isDestructive: true,
          ),
        );
        if (confirmed != true || !context.mounted) return;
        final result = await ref.read(deletePatientControllerProvider.notifier).deletePatient(patientId);
        if (!context.mounted) return;
        result.when(
          success: (_) => context.canPop() ? context.pop() : context.go(AppRoutes.patientList),
          failure: (e) => AppSnackbar.show(
            context,
            message: AppStrings.fromKey(e.userMessageKey),
            variant: AppSnackbarVariant.error,
          ),
        );
      },
    );
  }
}

class WorkspacePatientEditAction extends ConsumerWidget {
  const WorkspacePatientEditAction({super.key, required this.patientId});
  final String patientId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null || !user.isActive || (user.role == UserRole.doctor && !user.isSeniorDoctor)) {
      return const SizedBox.shrink();
    }
    return IconButton(
      tooltip: AppStrings.editPatient,
      icon: const Icon(Icons.edit_outlined),
      onPressed: () {
        final user = ref.read(currentUserProvider).value;
        if (user == null || !user.isActive || (user.role == UserRole.doctor && !user.isSeniorDoctor)) return;
        context.push(AppRoutes.editPatient.replaceFirst(':id', patientId));
      },
    );
  }
}
