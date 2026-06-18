/// Inline bottom-sheet for doctors to edit their profile details.
///
/// Allows editing full name, email, and optionally changing the account
/// password. All writes are role‑checked and routed through the repository.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

/// Bottom-sheet allowing a doctor to edit name, email, and password.
class EditProfileSheet extends ConsumerStatefulWidget {
  /// Creates an [EditProfileSheet].
  const EditProfileSheet({super.key, required this.staff});

  /// The currently authenticated staff profile.
  final Staff staff;

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.staff.fullName);
    _emailCtrl = TextEditingController(text: widget.staff.email);
    _phoneCtrl = TextEditingController(text: widget.staff.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: AppSizes.paddingCell,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r6)),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final String? newPassword = _passwordCtrl.text.trim().isNotEmpty
        ? _passwordCtrl.text.trim()
        : null;

    try {
      final repo = ref.read(authRepositoryProvider);
      // Update staff profile fields
      final updated = widget.staff.copyWith(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );

      final updateResult = await repo.updateStaffProfile(
        staff: updated,
        newPassword: newPassword,
      );

      if (!mounted) return;

      updateResult.when(
        success: (_) {
          ref.invalidate(currentUserProvider);
          AppSnackbar.show(
            context,
            message: AppStrings.profileUpdatedSuccess,
            variant: AppSnackbarVariant.success,
          );
          Navigator.of(context).pop();
        },
        failure: (error) {
          AppSnackbar.show(
            context,
            message: error.message,
            variant: AppSnackbarVariant.error,
          );
        },
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.p24, AppSizes.p24, AppSizes.p24, AppSizes.p24 + bottomInset,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.editProfile, style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSizes.p20),
            TextFormField(
              controller: _nameCtrl,
              enabled: !_isSubmitting,
              textCapitalization: TextCapitalization.words,
              decoration: _decoration(AppStrings.fullName),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? AppStrings.fullNameRequired : null,
            ),
            const SizedBox(height: AppSizes.p16),
            TextFormField(
              controller: _emailCtrl,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.emailAddress,
              decoration: _decoration(AppStrings.email),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return AppStrings.emailRequired;
                if (!v.contains('@')) return AppStrings.emailInvalid;
                return null;
              },
            ),
            const SizedBox(height: AppSizes.p16),
            TextFormField(
              controller: _phoneCtrl,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.phone,
              decoration: _decoration(AppStrings.phone),
            ),
            const SizedBox(height: AppSizes.p20),
            Text(AppStrings.changePasswordOptional,
                style: AppTextStyles.bodySecondary),
            const SizedBox(height: AppSizes.p12),
            TextFormField(
              controller: _passwordCtrl,
              enabled: !_isSubmitting,
              obscureText: true,
              decoration: _decoration(AppStrings.newPasswordHint),
              validator: (v) {
                if (v != null && v.trim().isNotEmpty && v.trim().length < 8) {
                  return AppStrings.passwordMinLength;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.p12),
            TextFormField(
              controller: _confirmPasswordCtrl,
              enabled: !_isSubmitting,
              obscureText: true,
              decoration: _decoration(AppStrings.confirmPassword),
              validator: (v) {
                if (_passwordCtrl.text.trim().isNotEmpty) {
                  if (v != _passwordCtrl.text.trim()) {
                    return AppStrings.passwordsDoNotMatch;
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.p24),
            AppButton(
              labelText: AppStrings.save,
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _handleSave,
            ),
          ],
        ),
      ),
    );
  }
}
