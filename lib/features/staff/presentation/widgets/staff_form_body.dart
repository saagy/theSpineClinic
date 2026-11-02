import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_management_controller.dart';
import 'package:spine_clinic_app/shared/widgets/form_page_body.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'staff_form_fields.dart';

part 'staff_form_submission.dart';

class StaffFormBody extends ConsumerStatefulWidget {
  const StaffFormBody({super.key, required this.currentUser, this.staff});
  final Staff currentUser;
  final Staff? staff;
  @override
  ConsumerState<StaffFormBody> createState() => _StaffFormBodyState();
}

class _StaffFormBodyState extends ConsumerState<StaffFormBody> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final ValueNotifier<bool> _dirty = ValueNotifier(false);
  bool _isSubmitting = false;
  bool _confirmingDiscard = false;
  bool _isReviewing = false;
  void _setReviewing(bool value) => setState(() => _isReviewing = value);
  void _setSubmitting(bool value) => setState(() => _isSubmitting = value);
  bool get _isSaving =>
      _isSubmitting || ref.read(staffFormControllerProvider).isLoading;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(staffFormControllerProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _dirty.dispose();
    super.dispose();
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.staffList);
    }
  }

  Future<void> _cancel() async {
    if (_isSaving || _confirmingDiscard) return;
    if (!_dirty.value) return _leave();
    _confirmingDiscard = true;
    final bool? discard = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(
        title: AppStrings.discardChanges,
        message: AppStrings.discardChangesMessage,
        confirmLabel: AppStrings.discard,
        cancelLabel: AppStrings.keepEditing,
      ),
    );
    _confirmingDiscard = false;
    if (mounted && discard == true) _leave();
  }

  void _onChanged() {
    _updateDirty();
    // Role changes register their dependent fields during the next build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateDirty());
  }

  void _updateDirty() {
    final FormBuilderState? form = _formKey.currentState;
    if (mounted && form != null) {
      _dirty.value = form.fields.values.any(
        (field) => field.value != field.initialValue,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.staff != null;
    final bool isSelf = isEdit && widget.staff!.id == widget.currentUser.id;
    final formState = ref.watch(staffFormControllerProvider);
    final bool saving = _isSubmitting || formState.isLoading;
    return ValueListenableBuilder<bool>(
      valueListenable: _dirty,
      builder: (BuildContext context, bool dirty, Widget? child) => PopScope(
        canPop: !saving && !dirty,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (!didPop) _cancel();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(isEdit ? AppStrings.editStaff : AppStrings.addStaff),
            leading: IconButton(
              icon: const BackButtonIcon(),
              tooltip: AppStrings.backTooltip,
              onPressed: saving ? null : _cancel,
            ),
          ),
          body: FormPageBody(
            maxWidth: AppSizes.formLayoutMaxWidth,
            isSaving: saving && !_isReviewing,
            saveLabel: isEdit ? AppStrings.saveChanges : AppStrings.addStaff,
            errorMessage: formState.error == null
                ? null
                : AppStrings.fromKey(formState.error!.userMessageKey),
            onSave: !saving && (!isEdit || dirty) ? _submit : null,
            onCancel: saving ? null : _cancel,
            child: AutofillGroup(
              onDisposeAction: AutofillContextAction.cancel,
              child: FormBuilder(
                key: _formKey,
                onChanged: _onChanged,
                child: StaffFormFields(
                  enabled: !saving,
                  isSelf: isSelf,
                  staff: widget.staff,
                  formKey: _formKey,
                  onSubmit: _submit,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
