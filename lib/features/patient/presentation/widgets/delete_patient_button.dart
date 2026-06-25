import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/delete_patient_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

/// Button to delete a patient. Only visible for empty patients
/// (no appointments, payments, notes, or documents) and for
/// super_admin / receptionist roles.
class DeletePatientButton extends ConsumerWidget {
  const DeletePatientButton({super.key, required this.patient});
  final Patient patient;

  Future<void> _onPressed(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(
        title: AppStrings.deletePatient,
        message: AppStrings.deletePatientWarning,
        isDestructive: true,
      ),
    );

    if (confirm != true) return;

    final result = await ref.read(deletePatientControllerProvider.notifier).deletePatient(patient.id);

    result.when(
      success: (_) {
        AppSnackbar.show(
          context,
          message: AppStrings.patientDeleted,
          variant: AppSnackbarVariant.success,
        );
        context.pop();
      },
      failure: (e) {
        AppSnackbar.show(
          context,
          message: AppStrings.fromKey(e.userMessageKey),
          variant: AppSnackbarVariant.error,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null || (user.role != UserRole.superAdmin && user.role != UserRole.receptionist)) {
      return const SizedBox.shrink();
    }

    final isEmptyAsync = ref.watch(patientIsEmptyProvider(patient.id));
    final bool isEmpty = isEmptyAsync.value ?? false;
    if (!isEmpty) return const SizedBox.shrink();

    final deleteState = ref.watch(deletePatientControllerProvider);
    final isLoading = deleteState.isLoading;

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.p16),
      child: AppButton(
        labelText: AppStrings.deletePatient,
        onPressed: isLoading ? null : () => _onPressed(context, ref),
        isLoading: isLoading,
        variant: AppButtonVariant.danger,
        icon: Icons.delete_outline,
        shape: AppButtonShape.pill,
      ),
    );
  }
}
