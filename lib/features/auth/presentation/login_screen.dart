/// Production login screen for all staff roles.
///
/// After successful authentication, the router's redirect engine
/// automatically navigates the user to their role-appropriate home.
/// If `is_active == false`, the notifier emits an error with code
/// `'auth/account-inactive'` which is caught here and surfaced via
/// [AppSnackbar].
///
/// Rule 1 — under 200 lines.
/// Rule 3 — all state via Riverpod.
library;

import 'package:flutter/material.dart';
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
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/app_text_field.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';

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
              padding: AppSizes.paddingScreenH,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Clinic header ──
                    const SizedBox(height: AppSizes.p32),
                    const Icon(
                      Icons.local_hospital_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppSizes.p12),
                    Text(
                      AppStrings.appName,
                      style: AppTextStyles.headingLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.p4),
                    Text(
                      AppStrings.appTagline,
                      style: AppTextStyles.bodySecondary,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.p40),

                    // ── Email field ──
                    AppTextField(
                      controller: _emailCtrl,
                      labelText: AppStrings.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: AuthValidators.email,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: AppSizes.p16),

                    // ── Password field ──
                    AppTextField(
                      controller: _passwordCtrl,
                      labelText: AppStringsAuth.password,
                      obscureText: true,
                      validator: AuthValidators.required,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: AppSizes.p24),

                    // ── Login button ──
                    AppButton(
                      labelText: AppStringsAuth.signIn,
                      onPressed: isLoading ? null : _handleLogin,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: AppSizes.p24),

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
                    const SizedBox(height: AppSizes.p32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
