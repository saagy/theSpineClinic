import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_strings_auth.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/auth_controllers.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/auth_form_switcher.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/frosted_auth_card.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/register_success_view.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/shared/widgets/ambient_glow_background.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/clinic_brand_mark.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';

/// Unified morphing frosted-glass authentication screen.
class LoginScreen extends ConsumerStatefulWidget {
  /// Creates a [LoginScreen].
  const LoginScreen({super.key, this.initialRegister = false});

  /// Whether to initialize in registration mode.
  final bool initialRegister;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final AuthControllers _ctrls = AuthControllers();

  late AuthMode _mode;
  UserRole _selectedRole = UserRole.doctor;
  ClinicLocation? _selectedBranch;
  bool _isRegisterLoading = false;
  bool _isRegisterSuccess = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialRegister ? AuthMode.registerIdentity : AuthMode.login;
  }

  @override
  void dispose() {
    _ctrls.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_ctrls.loginKey.currentState!.validate()) return;
    ref.read(currentUserProvider.notifier).clearError();
    await ref.read(currentUserProvider.notifier).login(
          _ctrls.loginEmailCtrl.text.trim(),
          _ctrls.loginPasswordCtrl.text,
        );
  }

  Future<void> _handleRegister() async {
    if (!_ctrls.regStep2Key.currentState!.validate()) return;
    setState(() => _isRegisterLoading = true);

    final result = await ref.read(authRepositoryProvider).registerStaff(
          role: _selectedRole,
          fullName: _ctrls.regNameCtrl.text.trim(),
          email: _ctrls.regEmailCtrl.text.trim(),
          phone: _ctrls.regPhoneCtrl.text.trim(),
          password: _ctrls.regPasswordCtrl.text,
          branch:
              _selectedRole == UserRole.receptionist ? _selectedBranch : null,
        );

    if (!mounted) return;
    result.when(
      success: (_) => setState(() => _isRegisterSuccess = true),
      failure: (AppException error) {
        setState(() => _isRegisterLoading = false);
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
    if (_isRegisterSuccess) {
      return RegisterSuccessView(
        onBackToLogin: () => setState(() {
          _isRegisterSuccess = false;
          _isRegisterLoading = false;
          _mode = AuthMode.login;
        }),
      );
    }

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

    final bool isBusy =
        ref.watch(currentUserProvider).isLoading || _isRegisterLoading;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AmbientGlowBackground(
        child: LoadingOverlay(
          isLoading: isBusy,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p20,
                  vertical: AppSizes.p16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: AutofillGroup(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: ClinicBrandMark(width: 175))
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .scale(
                                begin: const Offset(0.96, 0.96),
                                end: const Offset(1, 1),
                                duration: 400.ms,
                              ),
                          const SizedBox(height: AppSizes.p16),
                          FrostedAuthCard(
                            mode: _mode,
                            isBusy: isBusy,
                            ctrls: _ctrls,
                            selectedRole: _selectedRole,
                            selectedBranch: _selectedBranch,
                            onTabChanged: (reg) => setState(() {
                              _mode = reg
                                  ? AuthMode.registerIdentity
                                  : AuthMode.login;
                            }),
                            onRoleChanged: (r) =>
                                setState(() => _selectedRole = r),
                            onBranchChanged: (b) =>
                                setState(() => _selectedBranch = b),
                            onLoginSubmit: _handleLogin,
                            onNextToCredentials: () {
                              if (_ctrls.regStep1Key.currentState!.validate()) {
                                setState(
                                  () => _mode = AuthMode.registerCredentials,
                                );
                              }
                            },
                            onBackToIdentity: () => setState(
                              () => _mode = AuthMode.registerIdentity,
                            ),
                            onRegisterSubmit: _handleRegister,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}




