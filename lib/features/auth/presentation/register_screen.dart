/// Unified staff self-registration screen (doctor or receptionist).
///
/// On submission, creates a Supabase Auth user AND inserts a Staff
/// row with `is_active = false` — admin approval required before login.
/// The session is cleared immediately (AGENT_CONTEXT §8).
///
/// On success, swaps the form for [RegisterSuccessView].
/// Form validation is delegated to [AuthValidators].
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
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/auth_validators.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/register_success_view.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/app_text_field.dart';
import 'package:spine_clinic_app/shared/widgets/filter_chip.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';

/// Public registration form screen for doctors and receptionists.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  UserRole _selectedRole = UserRole.doctor;
  ClinicLocation? _selectedBranch;
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

    final result = await ref.read(authRepositoryProvider).registerStaff(
          role: _selectedRole,
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          password: _passwordCtrl.text,
          branch:
              _selectedRole == UserRole.receptionist ? _selectedBranch : null,
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
    if (_isSuccess) return const RegisterSuccessView();

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
                      AppStringsAuth.registration,
                      style: AppTextStyles.headingLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.p24),

                    // ── Role Selection ──
                    Text(
                      AppStringsAuth.accountType,
                      style: AppTextStyles.bodySecondary,
                    ),
                    const SizedBox(height: AppSizes.p12),
                    Row(
                      children: [
                        Expanded(
                          child: AppFilterChip(
                            label: AppStrings.doctorRoleLabel,
                            isActive: _selectedRole == UserRole.doctor,
                            onTap: _isLoading
                                ? null
                                : () => setState(
                                    () => _selectedRole = UserRole.doctor),
                          ),
                        ),
                        const SizedBox(width: AppSizes.p12),
                        Expanded(
                          child: AppFilterChip(
                            label: AppStrings.receptionistRoleLabel,
                            isActive:
                                _selectedRole == UserRole.receptionist,
                            onTap: _isLoading
                                ? null
                                : () => setState(() =>
                                    _selectedRole = UserRole.receptionist),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.p24),

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

                    // ── Branch (receptionist only, optional) ──
                    if (_selectedRole == UserRole.receptionist) ...[
                      DropdownButtonFormField<ClinicLocation>(
                        initialValue: _selectedBranch,
                        decoration: const InputDecoration(
                          labelText: AppStrings.branch,
                          hintText: AppStrings.selectBranch,
                        ),
                        items: ClinicLocation.values
                            .map((loc) => DropdownMenuItem(
                                  value: loc,
                                  child: Text(loc.displayLabel),
                                ))
                            .toList(),
                        onChanged: _isLoading
                            ? null
                            : (ClinicLocation? next) =>
                                setState(() => _selectedBranch = next),
                      ),
                      const SizedBox(height: AppSizes.p16),
                    ],

                    // ── Password ──
                    AppTextField(
                      controller: _passwordCtrl,
                      labelText: AppStringsAuth.password,
                      isPassword: true,
                      validator: AuthValidators.password,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: AppSizes.p16),

                    // ── Confirm Password ──
                    AppTextField(
                      controller: _confirmCtrl,
                      labelText: AppStringsAuth.confirmPassword,
                      isPassword: true,
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
