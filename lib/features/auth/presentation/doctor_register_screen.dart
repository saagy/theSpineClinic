/// Doctor self-registration screen.
///
/// On submission, creates a Supabase Auth user AND inserts a Staff
/// row with `role = 'doctor'` and `is_active = false`. The session
/// is cleared immediately — the user is NOT logged in after
/// registration (AGENT_CONTEXT §8).
///
/// On success, swaps the form for [RegisterSuccessView].
/// Form validation is delegated to [AuthValidators].
///
/// Rule 1 — under 200 lines (validation + success view split out).
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
import 'package:spine_clinic_app/features/auth/presentation/widgets/register_success_view.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/app_text_field.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';

/// Public doctor registration form screen.
class DoctorRegisterScreen extends ConsumerStatefulWidget {
  /// Creates a [DoctorRegisterScreen].
  const DoctorRegisterScreen({super.key});

  @override
  ConsumerState<DoctorRegisterScreen> createState() =>
      _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends ConsumerState<DoctorRegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await ref.read(authRepositoryProvider).registerDoctor(
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

    if (!mounted) return;

    result.when(
      success: (_) => setState(() => _isSuccess = true),
      failure: (AppException error) {
        setState(() => _isLoading = false);
        AppSnackbar.show(
          context,
          message: AppStrings.fromKey(error.userMessageKey),
          variant: AppSnackbarVariant.error,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Success state: full-screen confirmation ──
    if (_isSuccess) return const RegisterSuccessView();

    // ── Default state: registration form ──
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LoadingOverlay(
        isLoading: _isLoading,
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
                    const SizedBox(height: AppSizes.p24),
                    Text(
                      AppStringsAuth.doctorRegistration,
                      style: AppTextStyles.headingLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.p32),

                    // ── Full Name ──
                    AppTextField(
                      controller: _nameCtrl,
                      labelText: AppStrings.fullName,
                      validator: AuthValidators.fullName,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: AppSizes.p16),

                    // ── Email ──
                    AppTextField(
                      controller: _emailCtrl,
                      labelText: AppStrings.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: AuthValidators.email,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: AppSizes.p16),

                    // ── Phone ──
                    AppTextField(
                      controller: _phoneCtrl,
                      labelText: AppStrings.phone,
                      keyboardType: TextInputType.phone,
                      validator: AuthValidators.phone,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: AppSizes.p16),

                    // ── Password ──
                    AppTextField(
                      controller: _passwordCtrl,
                      labelText: AppStringsAuth.password,
                      obscureText: true,
                      validator: AuthValidators.password,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: AppSizes.p16),

                    // ── Confirm Password ──
                    AppTextField(
                      controller: _confirmCtrl,
                      labelText: AppStringsAuth.confirmPassword,
                      obscureText: true,
                      validator: AuthValidators.confirmPassword(
                        () => _passwordCtrl.text,
                      ),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: AppSizes.p24),

                    // ── Submit ──
                    AppButton(
                      labelText: AppStrings.submit,
                      onPressed: _isLoading ? null : _handleSubmit,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: AppSizes.p24),

                    // ── Login link ──
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.login),
                      child: Text.rich(
                        TextSpan(
                          text: '${AppStringsAuth.alreadyHaveAccount} ',
                          style: AppTextStyles.bodySecondary,
                          children: [
                            TextSpan(
                              text: AppStringsAuth.signIn,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
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
