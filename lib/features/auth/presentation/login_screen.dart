/// Production login screen — Medics UI Kit inspired.
///
/// A clean, centered layout with a small medical mark, warm welcome
/// copy, and smooth fade+slide entrance. No legacy chrome, no clutter.
///
/// Rule 1 — under 200 lines.
/// Rule 3 — all state via Riverpod.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_strings_auth.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/auth_validators.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/app_text_input.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';
import 'package:spine_clinic_app/shared/widgets/primary_button.dart';

/// Single login screen used by all staff roles.
class LoginScreen extends ConsumerStatefulWidget {
  /// Creates a [LoginScreen].
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(currentUserProvider.notifier).clearError();

    await ref.read(currentUserProvider.notifier).login(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentUserProvider, (_, AsyncValue next) {
      if (next.hasError && next.error is AppException) {
        final AppException error = next.error! as AppException;
        final String message = error.code == 'auth/account-inactive'
            ? AppStringsAuth.pendingApproval
            : AppStrings.fromKey(error.userMessageKey);
        AppSnackbar.show(
          context,
          message: message,
          variant: AppSnackbarVariant.error,
        );
      }
    });

    final bool isLoading = ref.watch(currentUserProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LoadingOverlay(
        isLoading: isLoading,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p32,
              ),
              child: Form(
                key: _formKey,
                child: _buildContent(isLoading)
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(
                      begin: 0.06,
                      end: 0,
                      duration: 600.ms,
                      curve: Curves.easeOut,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isLoading) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSizes.p36),

        // ── Small medical mark ──
        const Icon(
          Icons.medical_services_outlined,
          size: 28,
          color: AppColors.primary,
        ),
        const SizedBox(height: AppSizes.p12),

        // ── Clinic wordmark ──
        Text(
          AppStrings.appName,
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.primary,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.p16),

        // ── Welcome copy ──
        Text(
          AppStringsAuth.welcomeBack,
          style: AppTextStyles.headingLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.p6),
        Text(
          AppStringsAuth.signInToContinue,
          style: AppTextStyles.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.p36),

        // ── Email ──
        AppTextInput(
          controller: _emailCtrl,
          labelText: AppStrings.email,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: AuthValidators.email,
          enabled: !isLoading,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSizes.p16),

        // ── Password ──
        AppTextInput(
          controller: _passwordCtrl,
          labelText: AppStringsAuth.password,
          prefixIcon: Icons.lock_outlined,
          obscureText: true,
          validator: AuthValidators.required,
          enabled: !isLoading,
          textInputAction: TextInputAction.done,
          onSubmitted: isLoading ? null : (_) => _handleLogin(),
        ),
        const SizedBox(height: AppSizes.p24),

        // ── Sign in ──
        PrimaryButton(
          label: AppStringsAuth.signIn,
          onPressed: isLoading ? null : _handleLogin,
          isLoading: isLoading,
        ),
        const SizedBox(height: AppSizes.p20),

        // ── Register link ──
        GestureDetector(
          onTap: () => context.go(AppRoutes.register),
          child: Text(
            AppStringsAuth.registerAsDoctor,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSizes.p36),
      ],
    );
  }
}
