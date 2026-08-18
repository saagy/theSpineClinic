import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_strings_auth.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/login_form.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/register_step_credentials.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/register_step_identity.dart';
import 'package:spine_clinic_app/features/auth/presentation/widgets/register_success_view.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/shared/widgets/ambient_glow_background.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/clinic_brand_mark.dart';
import 'package:spine_clinic_app/shared/widgets/frosted_glass_card.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';

enum _AuthMode { login, registerIdentity, registerCredentials }

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
  final GlobalKey<FormState> _loginKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _regStep1Key = GlobalKey<FormState>();
  final GlobalKey<FormState> _regStep2Key = GlobalKey<FormState>();

  final TextEditingController _loginEmailCtrl = TextEditingController();
  final TextEditingController _loginPasswordCtrl = TextEditingController();

  final TextEditingController _regNameCtrl = TextEditingController();
  final TextEditingController _regEmailCtrl = TextEditingController();
  final TextEditingController _regPhoneCtrl = TextEditingController();
  final TextEditingController _regPasswordCtrl = TextEditingController();
  final TextEditingController _regConfirmCtrl = TextEditingController();

  late _AuthMode _mode;
  UserRole _selectedRole = UserRole.doctor;
  ClinicLocation? _selectedBranch;
  bool _isRegisterLoading = false;
  bool _isRegisterSuccess = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialRegister
        ? _AuthMode.registerIdentity
        : _AuthMode.login;
  }

  @override
  void dispose() {
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPhoneCtrl.dispose();
    _regPasswordCtrl.dispose();
    _regConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginKey.currentState!.validate()) return;
    ref.read(currentUserProvider.notifier).clearError();
    await ref.read(currentUserProvider.notifier).login(
          _loginEmailCtrl.text.trim(),
          _loginPasswordCtrl.text,
        );
  }

  Future<void> _handleRegister() async {
    if (!_regStep2Key.currentState!.validate()) return;
    setState(() => _isRegisterLoading = true);

    final result = await ref.read(authRepositoryProvider).registerStaff(
          role: _selectedRole,
          fullName: _regNameCtrl.text.trim(),
          email: _regEmailCtrl.text.trim(),
          phone: _regPhoneCtrl.text.trim(),
          password: _regPasswordCtrl.text,
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
          _mode = _AuthMode.login;
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

    final bool isLoginLoading = ref.watch(currentUserProvider).isLoading;
    final bool isBusy = isLoginLoading || _isRegisterLoading;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AmbientGlowBackground(
        child: LoadingOverlay(
          isLoading: isBusy,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p24,
                  vertical: AppSizes.p32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: AutofillGroup(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: ClinicBrandMark(width: 230))
                              .animate()
                              .fadeIn(duration: 500.ms)
                              .scale(
                                begin: const Offset(0.95, 0.95),
                                end: const Offset(1, 1),
                                duration: 500.ms,
                              ),
                          const SizedBox(height: AppSizes.p28),
                          FrostedGlassCard(
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 380),
                              curve: Curves.easeInOutCubic,
                              alignment: Alignment.topCenter,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, anim) =>
                                    FadeTransition(
                                  opacity: anim,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.04, 0),
                                      end: Offset.zero,
                                    ).animate(anim),
                                    child: child,
                                  ),
                                ),
                                child: _buildCurrentForm(isBusy),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSizes.p24),
                          Center(
                            child: TextButton(
                              onPressed: isBusy
                                  ? null
                                  : () => setState(() {
                                        _mode = _mode == _AuthMode.login
                                            ? _AuthMode.registerIdentity
                                            : _AuthMode.login;
                                      }),
                              child: Text(
                                _mode == _AuthMode.login
                                    ? AppStringsAuth.register
                                    : AppStringsAuth.signIn,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
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

  Widget _buildCurrentForm(bool isBusy) {
    switch (_mode) {
      case _AuthMode.login:
        return LoginForm(
          key: const ValueKey('login'),
          formKey: _loginKey,
          emailController: _loginEmailCtrl,
          passwordController: _loginPasswordCtrl,
          isLoading: isBusy,
          onSubmit: _handleLogin,
        );
      case _AuthMode.registerIdentity:
        return RegisterStepIdentity(
          key: const ValueKey('reg_id'),
          formKey: _regStep1Key,
          nameController: _regNameCtrl,
          emailController: _regEmailCtrl,
          phoneController: _regPhoneCtrl,
          selectedRole: _selectedRole,
          selectedBranch: _selectedBranch,
          onRoleChanged: (r) => setState(() => _selectedRole = r),
          onBranchChanged: (b) => setState(() => _selectedBranch = b),
          onNext: () {
            if (_regStep1Key.currentState!.validate()) {
              setState(() => _mode = _AuthMode.registerCredentials);
            }
          },
          isLoading: isBusy,
        );
      case _AuthMode.registerCredentials:
        return RegisterStepCredentials(
          key: const ValueKey('reg_cred'),
          formKey: _regStep2Key,
          passwordController: _regPasswordCtrl,
          confirmController: _regConfirmCtrl,
          onBack: () => setState(() => _mode = _AuthMode.registerIdentity),
          onSubmit: _handleRegister,
          isLoading: isBusy,
        );
    }
  }
}
