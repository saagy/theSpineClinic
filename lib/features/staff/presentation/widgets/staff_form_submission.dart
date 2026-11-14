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
      final StaffSchedule schedule = values['schedule'] as StaffSchedule? ?? StaffSchedule.empty;
      // New receptionists start at their first branch; the database keeps an
      // existing one's working branch within their branches.
      final ClinicLocation? branch = role != UserRole.receptionist
          ? null
          : widget.staff?.branch ?? schedule.branches.firstOrNull;
      final bool isEdit = widget.staff != null;
      final bool active = isEdit
          ? (values['is_active'] as bool? ?? widget.staff!.isActive)
          : true;
      if (await _blockedByDeactivationWarning(active) || !mounted) return;
      if (await _blockedByBranchRemoval(role, schedule) || !mounted) return;
      final controller = ref.read(staffFormControllerProvider.notifier);
      final StaffDetails details = staffDetailsFromForm(values);
      final Result<void> result = isEdit
          ? await controller.updateStaff(
              staff: _updatedStaff(values, role, branch, active),
              newPassword: values['change_password'] == true
                  ? values['password'] as String
                  : null,
              // Unchanged details are not sent, so the save leaves them alone.
              details: details == widget.details ? null : details,
              schedule: schedule == widget.schedule ? null : schedule,
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
              details: details.isEmpty ? null : details,
              schedule: schedule.isEmpty ? null : schedule,
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
  /// Asks before a doctor leaves a branch where they still have upcoming
  /// visits. The visits stay booked either way.
  Future<bool> _blockedByBranchRemoval(UserRole role, StaffSchedule schedule) async {
    final Staff? staff = widget.staff;
    if (staff == null || role != UserRole.doctor) return false;
    final List<ClinicLocation> removed = [
      for (final b in widget.schedule.branches) if (!schedule.branches.contains(b)) b,
    ];
    if (removed.isEmpty) return false;
    final Result<Map<ClinicLocation, int>> counts = await ref
        .read(staffFormControllerProvider.notifier)
        .upcomingAtBranches(staff, removed);
    if (!mounted || counts.isFailure) return true;
    final Map<ClinicLocation, int> found = counts.dataOrNull!;
    if (found.isEmpty) return false;
    _setReviewing(true);
    try {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => ConfirmationDialog(
          title: AppStrings.staffSchedule.removeBranchTitle,
          message: AppStrings.staffSchedule.removeBranchMessage(staff.fullName, {
            for (final e in found.entries) e.key.displayLabel: e.value,
          }),
          confirmLabel: AppStrings.staffSchedule.removeBranchConfirm,
          cancelLabel: AppStrings.staffSchedule.keepBranch,
        ),
      );
      return confirmed != true;
    } finally {
      if (mounted) _setReviewing(false);
    }
  }

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
