import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_strings_auth.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/auth_validators.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/password_strength_meter.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_text_input.dart';

/// Step 2 of registration: Security credentials and password strength verification.
class RegisterStepCredentials extends StatefulWidget {
  /// Creates a [RegisterStepCredentials].
  const RegisterStepCredentials({
    super.key,
    required this.formKey,
    required this.passwordController,
    required this.confirmController,
    required this.onBack,
    required this.onSubmit,
    required this.isLoading,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final bool isLoading;

  @override
  State<RegisterStepCredentials> createState() =>
      _RegisterStepCredentialsState();
}

class _RegisterStepCredentialsState extends State<RegisterStepCredentials> {
  String _currentPassword = '';

  @override
  void initState() {
    super.initState();
    _currentPassword = widget.passwordController.text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStringsAuth.stepCredentials,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.p4),
          Text(
            'Create a strong password for your account',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.p20),

          // Password
          AppTextInput(
            controller: widget.passwordController,
            labelText: AppStringsAuth.password,
            prefixIcon: LucideIcons.lock,
            isPassword: true,
            validator: AuthValidators.password,
            enabled: !widget.isLoading,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: (val) => setState(() => _currentPassword = val),
          ),
          // Dynamic Password Strength Meter with animated expansion
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            child: _currentPassword.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.p16),
                    child: PasswordStrengthMeter(password: _currentPassword),
                  )
                : const SizedBox.shrink(),
          ),

          // Confirm Password
          AppTextInput(
            controller: widget.confirmController,
            labelText: AppStringsAuth.confirmPassword,
            prefixIcon: LucideIcons.lock,
            isPassword: true,
            validator: AuthValidators.confirmPassword(
              () => widget.passwordController.text,
            ),
            enabled: !widget.isLoading,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: widget.isLoading ? null : (_) => widget.onSubmit(),
          ),
          const SizedBox(height: AppSizes.p24),

          // Actions: Back and Submit
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: widget.isLoading ? null : widget.onBack,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.p16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.r999),
                    ),
                    side: BorderSide(color: cs.outline),
                  ),
                  child: Text(
                    AppStringsAuth.back,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                flex: 2,
                child: AppButton(
                  labelText: AppStrings.submit,
                  onPressed: widget.isLoading ? null : widget.onSubmit,
                  isLoading: widget.isLoading,
                  shape: AppButtonShape.pill,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
