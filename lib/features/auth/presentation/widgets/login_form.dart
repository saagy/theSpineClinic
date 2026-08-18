import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_strings_auth.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/auth_validators.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_text_input.dart';

/// Extracted login form inputs with email, password, and submission button.
class LoginForm extends StatelessWidget {
  /// Creates a [LoginForm].
  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onSubmit,
  });

  /// The form key used for validation.
  final GlobalKey<FormState> formKey;

  /// Email field controller.
  final TextEditingController emailController;

  /// Password field controller.
  final TextEditingController passwordController;

  /// Whether authentication is currently processing.
  final bool isLoading;

  /// Triggered on valid form submission.
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Welcome back',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.p4),
          Text(
            'Sign in to your clinical account',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.p24),

          // Email input
          AppTextInput(
            controller: emailController,
            labelText: AppStrings.email,
            prefixIcon: LucideIcons.mail,
            keyboardType: TextInputType.emailAddress,
            validator: AuthValidators.email,
            enabled: !isLoading,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
          ),
          const SizedBox(height: AppSizes.p16),

          // Password input
          AppTextInput(
            controller: passwordController,
            labelText: AppStringsAuth.password,
            prefixIcon: LucideIcons.lock,
            isPassword: true,
            validator: AuthValidators.required,
            enabled: !isLoading,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: isLoading ? null : (_) => onSubmit(),
          ),
          const SizedBox(height: AppSizes.p24),

          // Sign In Action
          AppButton(
            labelText: AppStringsAuth.signIn,
            onPressed: isLoading ? null : onSubmit,
            isLoading: isLoading,
            shape: AppButtonShape.pill,
          ),
        ],
      ),
    );
  }
}
