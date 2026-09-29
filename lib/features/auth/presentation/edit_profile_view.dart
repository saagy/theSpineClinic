part of 'edit_profile_sheet.dart';

extension _ProfileView on _EditProfileSheetState {
  Widget _buildForm(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.p24,
        AppSizes.p24,
        AppSizes.p24,
        AppSizes.p24 + bottomInset,
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
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? AppStrings.fullNameRequired
                  : null,
            ),
            const SizedBox(height: AppSizes.p16),
            TextFormField(
              controller: _emailCtrl,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.emailAddress,
              decoration: _decoration(AppStrings.email),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return AppStrings.emailRequired;
                }
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
            Text(
              AppStrings.changePasswordOptional,
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: AppSizes.p12),
            TextFormField(
              controller: _passwordCtrl,
              enabled: !_isSubmitting,
              obscureText: _obscurePassword,
              decoration: _decoration(
                AppStrings.newPasswordHint,
                suffixIcon: PasswordVisibilityToggle(
                  isObscured: _obscurePassword,
                  onToggle: () =>
                      _mutate(() => _obscurePassword = !_obscurePassword),
                ),
              ),
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
              obscureText: _obscureConfirm,
              decoration: _decoration(
                AppStrings.confirmPassword,
                suffixIcon: PasswordVisibilityToggle(
                  isObscured: _obscureConfirm,
                  onToggle: () =>
                      _mutate(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
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
