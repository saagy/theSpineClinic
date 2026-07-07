import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_management_controller.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_form_fields.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';

class StaffFormBody extends ConsumerStatefulWidget {
  const StaffFormBody({super.key, required this.currentUser, this.staff});

  final Staff currentUser;
  final Staff? staff;

  @override
  ConsumerState<StaffFormBody> createState() => _StaffFormBodyState();
}

class _StaffFormBodyState extends ConsumerState<StaffFormBody> {
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.staff != null;
    final isSelf = isEdit && widget.staff!.id == widget.currentUser.id;
    final formState = ref.watch(staffFormControllerProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
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
                  onPressed: _submit,
                  debounceMs: 1000,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    final values = _formKey.currentState!.value;
    final role = values['role'] as UserRole;
    final branch = values['branch'] as ClinicLocation?;
    final isEdit = widget.staff != null;
    final isActive = isEdit
        ? ((values['is_active'] as bool?) ?? widget.staff!.isActive)
        : true;
    if (await _blockedByDeactivationWarning(isActive)) return;

    final controller = ref.read(staffFormControllerProvider.notifier);
    final result = isEdit
        ? await controller.updateStaff(
            staff: _updatedStaff(values, role, branch, isActive),
            newPassword: (values['change_password'] as bool? ?? false)
                ? values['password'] as String
                : null,
          )
        : await controller.createStaff(
            fullName: values['full_name'] as String,
            email: values['email'] as String,
            role: role,
            password: values['password'] as String,
            canManagePayments: _canManagePayments(values, role),
            phone: values['phone'] as String?,
            branch: branch,
          );
    _handleResult(result, isEdit);
  }

  Staff _updatedStaff(
    Map<String, dynamic> values,
    UserRole role,
    ClinicLocation? branch,
    bool isActive,
  ) {
    return widget.staff!.copyWith(
      fullName: values['full_name'] as String,
      email: values['email'] as String,
      phone: values['phone'] as String?,
      role: role,
      isActive: isActive,
      canManagePayments: _canManagePayments(values, role),
      branch: role == UserRole.receptionist ? branch : null,
      deactivatedAt: isActive ? null : widget.staff!.deactivatedAt,
    );
  }

  bool _canManagePayments(Map<String, dynamic> values, UserRole role) {
    return role == UserRole.receptionist &&
        ((values['can_manage_payments'] as bool?) ??
            widget.staff?.canManagePayments ??
            false);
  }

  Future<bool> _blockedByDeactivationWarning(bool newIsActive) async {
    final staff = widget.staff;
    if (staff == null || !staff.isActive || newIsActive) return false;
    if (staff.role != UserRole.doctor && staff.role != UserRole.superAdmin) {
      return false;
    }
    final countResult = await ref
        .read(staffRepositoryProvider)
        .countUpcomingAppointments(staff.id);
    final count = countResult.when(success: (c) => c, failure: (_) => 0);
    if (count == 0 || !mounted) return false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: AppStrings.deactivateAccount,
        message: AppStrings.deactivateStaffWarning(count),
        confirmLabel: AppStrings.deactivateAccount,
        cancelLabel: AppStrings.keepActive,
        isDestructive: true,
      ),
    );
    return confirmed != true;
  }

  void _handleResult(Result<void> result, bool isEdit) {
    if (!mounted) return;
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
      failure: (error) => AppSnackbar.show(
        context,
        message: error.message,
        variant: AppSnackbarVariant.error,
      ),
    );
  }
}
