import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_management_controller.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_form_fields.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';

/// Screen allowing Super Admins to create or edit non-doctor staff members.
class StaffFormScreen extends ConsumerStatefulWidget {
  /// Creates a [StaffFormScreen].
  const StaffFormScreen({super.key, this.staff});

  /// The staff profile being edited (null for creation mode).
  final Staff? staff;

  @override
  ConsumerState<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends ConsumerState<StaffFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  Future<void> _submit(bool isSelf) async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      final String fullName = values['full_name'] as String;
      final String email = values['email'] as String;
      final String? phone = values['phone'] as String?;
      final UserRole role = values['role'] as UserRole;

      final isEdit = widget.staff != null;
      final bool newIsActive = isEdit
          ? ((values['is_active'] as bool?) ?? widget.staff!.isActive)
          : true;
      final bool isDeactivating = isEdit && widget.staff!.isActive && !newIsActive;

      // ── Soft warning before deactivating a doctor ──
      if (isDeactivating &&
          (widget.staff!.role == UserRole.doctor ||
              widget.staff!.role == UserRole.superAdmin)) {
        final repo = ref.read(staffRepositoryProvider);
        final countResult = await repo.countUpcomingAppointments(widget.staff!.id);
        final int upcomingCount = countResult.when(
          success: (c) => c,
          failure: (_) => 0, // Query failed — don't block
        );
        if (upcomingCount > 0) {
          if (!mounted) return;
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => ConfirmationDialog(
              title: 'Deactivate Doctor?',
              message: 'This doctor has $upcomingCount upcoming appointment(s). '
                  'Deactivating will not cancel them, but the doctor will '
                  'appear as inactive on historical records.\n\n'
                  'Deactivate anyway?',
              confirmLabel: 'Deactivate',
              cancelLabel: 'Keep Active',
              isDestructive: true,
            ),
          );
          if (confirmed != true) return;
        }
      }

      final resultNotifier = ref.read(staffFormControllerProvider.notifier);

      final result = isEdit
          ? await resultNotifier.updateStaff(
              staff: widget.staff!.copyWith(
                fullName: fullName,
                email: email,
                phone: phone,
                role: role,
                isActive: newIsActive,
              ),
              newPassword: (values['change_password'] as bool? ?? false)
                  ? values['password'] as String
                  : null,
            )
          : await resultNotifier.createStaff(
              fullName: fullName,
              email: email,
              role: role,
              password: values['password'] as String,
              phone: phone,
            );

      if (mounted) {
        result.when(
          success: (_) {
            AppSnackbar.show(
              context,
              message: isEdit
                  ? AppStrings.staffUpdateSuccess
                  : AppStrings.staffCreateSuccess,
              variant: AppSnackbarVariant.success,
            );
            context.pop();
          },
          failure: (error) {
            AppSnackbar.show(
              context,
              message: error.message,
              variant: AppSnackbarVariant.error,
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncUser = ref.watch(currentUserProvider);

    return asyncUser.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: ErrorView(
          exception: error is AppException
              ? error
              : const UnknownException(message: AppStrings.errorDatabaseQueryFailed),
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
      ),
      data: (currentUser) {
        if (currentUser == null || currentUser.role != UserRole.superAdmin) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: ErrorView(
              exception: UnknownException(
                message: AppStrings.errorDatabasePermissionDenied,
                code: 'security/blocked',
              ),
            ),
          );
        }

        final isEdit = widget.staff != null;
        final isSelf = isEdit && widget.staff!.id == currentUser.id;
        final formState = ref.watch(staffFormControllerProvider);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            title: Text(isEdit ? AppStrings.editStaff : AppStrings.addStaff),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          body: LoadingOverlay(
            isLoading: formState.isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.p16),
              child: FormBuilder(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StaffFormFields(
                      enabled: !formState.isLoading,
                      isSelf: isSelf,
                      staff: widget.staff,
                      formKey: _formKey,
                    ),
                    const SizedBox(height: AppSizes.p32),
                    AppButton(
                      labelText: AppStrings.save,
                      isLoading: formState.isLoading,
                      onPressed: () => _submit(isSelf),
                      debounceMs: 1000,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
