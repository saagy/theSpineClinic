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
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: LoadingOverlay(
        isLoading: isLoading,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.p24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: _buildCardContent(context, isLoading)
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(
                          begin: 0.04,
                          end: 0,
                          duration: 600.ms,
                          curve: Curves.easeOut,
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

  Widget _buildCardContent(BuildContext context, bool isLoading) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Brand Lockup (Centered) ──
        Center(
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.spa_rounded,
                  color: cs.onPrimary,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSizes.p16),
              Text(
                'THE SPINE CLINIC',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: AppSizes.p4),
              Text(
                'Clinical Excellence Center',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.p36),

        // ── Form Card ──
        Container(
          padding: const EdgeInsets.all(AppSizes.p24),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r24)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Color(0x0E000000),
              width: AppSizes.borderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: AppSizes.p28),

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
                isPassword: true,
                validator: AuthValidators.required,
                enabled: !isLoading,
                textInputAction: TextInputAction.done,
                onSubmitted: isLoading ? null : (_) => _handleLogin(),
              ),
              const SizedBox(height: AppSizes.p24),

              // ── Sign in ──
              AppButton(
                labelText: AppStringsAuth.signIn,
                onPressed: isLoading ? null : () => _handleLogin(),
                isLoading: isLoading,
                shape: AppButtonShape.pill,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.p24),

        // ── Register link ──
        Center(
          child: TextButton(
            onPressed: () => context.go(AppRoutes.register),
            style: TextButton.styleFrom(
              foregroundColor: cs.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p16,
                vertical: AppSizes.p8,
              ),
            ),
            child: Text(
              AppStringsAuth.register,
              style: AppTextStyles.bodyMedium.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
