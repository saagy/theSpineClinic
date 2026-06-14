/// Root screen for the doctor replacement management wizard.
///
/// Switches between Step 1 (setup form) and Step 2 (affected
/// appointments checklist) based on the controller state.
///
/// Rule 1 — under 200 lines; widgets split into sub-files.
/// Rule 5 — no dynamic types.
/// Rule 9 — handles loading, error, empty, and data states.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/replacements/presentation/manage_replacement_controller.dart';
import 'package:spine_clinic_app/features/replacements/presentation/widgets/affected_appointments_checklist.dart';
import 'package:spine_clinic_app/features/replacements/presentation/widgets/replacement_setup_form.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// ManageReplacementScreen — admin/receptionist wizard for doctor coverage.
class ManageReplacementScreen extends ConsumerWidget {
  /// Creates a [ManageReplacementScreen].
  const ManageReplacementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Role guard: restrict doctors (Rule 6)
    final AsyncValue<Staff?> asyncUser = ref.watch(currentUserProvider);
    final Staff? currentUser = asyncUser.value;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (currentUser.role == UserRole.doctor) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            AppStrings.manageReplacement,
            style: AppTextStyles.headingSmall,
          ),
          backgroundColor: AppColors.surface,
        ),
        body: const ErrorView(
          exception: AuthException(
            code: 'auth/role-denied',
            message: AppStrings.replacementAccessDenied,
          ),
        ),
      );
    }

    final AsyncValue<ManageReplacementState> controllerState =
        ref.watch(manageReplacementControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.manageReplacement,
          style: AppTextStyles.headingSmall,
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: controllerState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (Object error, _) => ErrorView(
          exception: error is AppException
              ? error
              : UnknownException(message: error.toString()),
          onRetry: () =>
              ref.invalidate(manageReplacementControllerProvider),
        ),
        data: (ManageReplacementState state) {
          // Show error snackbar if there's an error message
          if (state.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AppSnackbar.show(
                context,
                message: state.errorMessage!,
                variant: AppSnackbarVariant.error,
              );
            });
          }

          final Widget content = switch (state.step) {
            ReplacementStep.form => ReplacementSetupForm(
                state: state,
                controller: ref.read(
                  manageReplacementControllerProvider.notifier,
                ),
              ),
            ReplacementStep.checklist =>
              AffectedAppointmentsChecklist(
                state: state,
                controller: ref.read(
                  manageReplacementControllerProvider.notifier,
                ),
                onSwapComplete: () {
                  AppSnackbar.show(
                    context,
                    message: AppStrings.replacementSwapSuccess,
                    variant: AppSnackbarVariant.success,
                  );
                  context.pop();
                },
                onSkip: () => context.pop(),
              ),
          };

          if (state.isSaving) {
            return Stack(
              children: [
                content,
                AbsorbPointer(
                  absorbing: true,
                  child: Container(
                    color: AppColors.overlayScrim,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return content;
        },
      ),
    );
  }
}
