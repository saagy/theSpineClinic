import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/profile_editor_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/app_text_field.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/form_page_body.dart';
import 'package:spine_clinic_app/shared/widgets/form_section.dart';

part 'profile_editor_view.dart';

class ProfileEditorForm extends ConsumerStatefulWidget {
  const ProfileEditorForm({
    super.key,
    required this.staff,
    this.passwordOnly = false,
  });
  final Staff staff;
  final bool passwordOnly;

  @override
  ConsumerState<ProfileEditorForm> createState() => _ProfileEditorFormState();
}

class _ProfileEditorFormState extends ConsumerState<ProfileEditorForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  late final Listenable _edits;
  bool _confirmingDiscard = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.staff.fullName);
    _email = TextEditingController(text: widget.staff.email);
    _phone = TextEditingController(text: widget.staff.phone ?? '');
    _edits = Listenable.merge([_name, _email, _phone, _password, _confirm]);
    Future.microtask(() {
      if (mounted) ref.read(_provider.notifier).clearError();
    });
  }

  ProfileEditorControllerProvider get _provider =>
      profileEditorControllerProvider(
        widget.staff.id,
        passwordOnly: widget.passwordOnly,
      );

  bool get _hasChanges => widget.passwordOnly
      ? _password.text.isNotEmpty || _confirm.text.isNotEmpty
      : _name.text.trim() != widget.staff.fullName ||
            _email.text.trim() != widget.staff.email ||
            _phone.text.trim() != (widget.staff.phone ?? '');

  @override
  void dispose() {
    for (final TextEditingController field in [
      _name,
      _email,
      _phone,
      _password,
      _confirm,
    ]) {
      field.dispose();
    }
    super.dispose();
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(switch (widget.staff.role) {
        UserRole.doctor => AppRoutes.doctorProfile,
        UserRole.receptionist => AppRoutes.receptionistProfile,
        UserRole.superAdmin => AppRoutes.adminHub,
      });
    }
  }

  Future<void> _cancel() async {
    if (ref.read(_provider).isSaving || _confirmingDiscard) return;
    if (!_hasChanges) return _leave();
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

  Future<void> _save() async {
    if (ref.read(_provider).isSaving ||
        !_hasChanges ||
        !_formKey.currentState!.validate()) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final controller = ref.read(_provider.notifier);
    final bool saved = widget.passwordOnly
        ? await controller.changePassword(_password.text)
        : await controller.saveDetails(
            fullName: _name.text,
            email: _email.text,
            phone: _phone.text,
          );
    if (!mounted || !saved) return;
    TextInput.finishAutofillContext();
    AppSnackbar.show(
      context,
      message: widget.passwordOnly
          ? AppStrings.passwordUpdatedSuccess
          : AppStrings.profileUpdatedSuccess,
      variant: AppSnackbarVariant.success,
    );
    _leave();
  }

  @override
  Widget build(BuildContext context) {
    final ProfileEditorState state = ref.watch(_provider);
    return ListenableBuilder(
      listenable: _edits,
      builder: (BuildContext context, Widget? child) => PopScope(
        canPop: !state.isSaving && !_hasChanges,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (!didPop) _cancel();
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const BackButtonIcon(),
              tooltip: AppStrings.backTooltip,
              onPressed: state.isSaving ? null : _cancel,
            ),
            title: Text(
              widget.passwordOnly
                  ? AppStrings.changePassword
                  : AppStrings.editProfile,
            ),
          ),
          body: FormPageBody(
            maxWidth: AppSizes.formLayoutMaxWidth,
            isSaving: state.isSaving,
            errorMessage: state.errorMessage,
            saveLabel: widget.passwordOnly
                ? AppStrings.updatePassword
                : AppStrings.saveChanges,
            onSave: _hasChanges ? _save : null,
            onCancel: _cancel,
            child: AutofillGroup(
              onDisposeAction: AutofillContextAction.cancel,
              child: Form(
                key: _formKey,
                child: _content(context, state.isSaving),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
