import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings_auth.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/shared/widgets/ambient_glow_background.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/clinic_brand_mark.dart';
import 'package:spine_clinic_app/shared/widgets/frosted_glass_card.dart';

/// Full-screen confirmation view shown after successful staff registration.
class RegisterSuccessView extends StatelessWidget {
  /// Creates a [RegisterSuccessView].
  const RegisterSuccessView({super.key, required this.onBackToLogin});

  /// Callback to reset the parent screen back to login mode.
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    final clinic = ClinicColors.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AmbientGlowBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p24,
                vertical: AppSizes.p32,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ClinicBrandMark(width: 200),
                    const SizedBox(height: AppSizes.p32),
                    FrostedGlassCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: clinic.success.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.check_rounded,
                                size: 40,
                                color: clinic.success,
                              ),
                            ),
                          )
                              .animate()
                              .scale(
                                begin: const Offset(0.5, 0.5),
                                end: const Offset(1, 1),
                                duration: 500.ms,
                                curve: Curves.easeOutBack,
                              ),
                          const SizedBox(height: AppSizes.p20),
                          Text(
                            AppStringsAuth.registrationSubmittedTitle,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSizes.p8),
                          Text(
                            AppStringsAuth.registrationSubmittedMessage,
                            style: AppTextStyles.bodySecondary.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSizes.p28),
                          AppButton(
                            labelText: AppStringsAuth.backToLogin,
                            onPressed: onBackToLogin,
                            shape: AppButtonShape.pill,
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
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
