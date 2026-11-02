part of 'staff_form_body.dart';

extension _StaffFormSubmission on _StaffFormBodyState {
  Future<void> _submit() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.saveAndValidate(
          autoScrollWhenFocusOnInvalid: true,
        ) ??
        false)) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(staffFormControllerProvider.notifier).clearError();
    _setSubmitting(true);
    try {
      final Map<String, Object?> values = _formKey.currentState!.value;
      final UserRole role = values['role'] as UserRole;
      final ClinicLocation? branch = values['branch'] as ClinicLocation?;
      final bool isEdit = widget.staff != null;
      final bool active = isEdit
          ? (values['is_active'] as bool? ?? widget.staff!.isActive)
          : true;
      if (await _blockedByDeactivationWarning(active) || !mounted) return;
      final controller = ref.read(staffFormControllerProvider.notifier);
      final Result<void> result = isEdit
          ? await controller.updateStaff(
              staff: _updatedStaff(values, role, branch, active),
              newPassword: values['change_password'] == true
                  ? values['password'] as String
                  : null,
            )
          : await controller.createStaff(
              fullName: values['full_name'] as String,
              email: values['email'] as String,
              role: role,
              password: values['password'] as String,
              canManagePayments: _canManagePayments(values, role),
              isSenior:
                  role == UserRole.doctor &&
                  (values['is_senior'] as bool? ?? false),
              phone: _phone(values),
              branch: branch,
            );
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
          _leave();
        },
        failure: controller.reportFailure,
      );
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  String? _phone(Map<String, Object?> values) {
    final String? phone = values['phone'] as String?;
    return phone == null || phone.isEmpty ? null : phone;
  }

  Staff _updatedStaff(
    Map<String, Object?> values,
    UserRole role,
    ClinicLocation? branch,
    bool active,
  ) => widget.staff!.copyWith(
    fullName: values['full_name'] as String,
    email: values['email'] as String,
    phone: _phone(values),
    role: role,
    isActive: active,
    canManagePayments: _canManagePayments(values, role),
    isSenior:
        role == UserRole.doctor && (values['is_senior'] as bool? ?? false),
    branch: role == UserRole.receptionist ? branch : null,
    deactivatedAt: active ? null : widget.staff!.deactivatedAt,
  );
  bool _canManagePayments(Map<String, Object?> values, UserRole role) =>
      role == UserRole.receptionist &&
      (values['can_manage_payments'] as bool? ??
          widget.staff?.canManagePayments ??
          false);
  Future<bool> _blockedByDeactivationWarning(bool active) async {
    final Staff? staff = widget.staff;
    if (staff == null || !staff.isActive || active) return false;
    final Result<int> appointments = await ref
        .read(staffFormControllerProvider.notifier)
        .deactivationAppointments(staff);
    if (!mounted || appointments.isFailure) return true;
    final int count = appointments.dataOrNull!;
    _setReviewing(true);
    try {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => ConfirmationDialog(
          title: AppStrings.deactivateStaffTitle(staff.fullName),
          message: count > 0
              ? AppStrings.deactivateStaffWarning(count)
              : AppStrings.deactivateStaffConfirm,
          confirmLabel: AppStrings.deactivateAccount,
          cancelLabel: AppStrings.keepEditing,
          isDestructive: true,
        ),
      );
      return confirmed != true;
    } finally {
      if (mounted) _setReviewing(false);
    }
  }
}
