/// Inline bottom-sheet for any authenticated staff member to edit their
/// profile details.
///
/// Allows editing full name, email, and optionally changing the account
/// password. All writes are role-checked and routed through the repository.
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
import 'package:spine_clinic_app/shared/widgets/password_visibility_toggle.dart';

part 'edit_profile_view.dart';

/// Bottom-sheet allowing a staff member to edit name, email, and password.
class EditProfileSheet extends ConsumerStatefulWidget {
  /// Creates an [EditProfileSheet].
  const EditProfileSheet({super.key, required this.staff});

  /// The currently authenticated staff profile.
  final Staff staff;

  /// Opens the sheet above the current route with the standardized chrome
  /// (scroll-controlled, softened top corners). Centralizes the launch
  /// plumbing so callers don't need their own `showModalBottomSheet` glue.
  static Future<void> show(BuildContext context, Staff staff) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r12)),
      ),
      builder: (_) => EditProfileSheet(staff: staff),
    );
  }

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
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

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

  InputDecoration _decoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: AppSizes.paddingCell,
      suffixIcon: suffixIcon,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r6)),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    final actor = ref.read(currentUserProvider).value;
    if (actor == null || !actor.isActive || actor.id != widget.staff.id) {
      AppSnackbar.show(
        context,
        message: AppStrings.errorDatabasePermissionDenied,
        variant: AppSnackbarVariant.error,
      );
      return;
    }

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
          if (error.code == 'auth/profile-saved-password-unconfirmed') {
            ref.invalidate(currentUserProvider);
          }
          AppSnackbar.show(
            context,
            message: AppStrings.fromKey(error.userMessageKey),
            variant: AppSnackbarVariant.error,
          );
        },
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _mutate(VoidCallback change) => setState(change);

  @override
  Widget build(BuildContext context) => _buildForm(context);
}
