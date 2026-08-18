import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings_auth.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';

/// Password requirement evaluation model.
class PasswordRequirement {
  const PasswordRequirement({
    required this.label,
    required this.test,
  });

  final String label;
  final bool Function(String) test;
}

/// A dynamic password strength meter with animated progress and requirement pills.
class PasswordStrengthMeter extends StatelessWidget {
  /// Creates a [PasswordStrengthMeter].
  const PasswordStrengthMeter({
    super.key,
    required this.password,
  });

  /// The active password text to evaluate.
  final String password;

  static final List<PasswordRequirement> requirements = [
    PasswordRequirement(
      label: AppStringsAuth.reqMinLength,
      test: (pwd) => pwd.length >= 8,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final clinic = ClinicColors.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final double progress = (password.length / 8.0).clamp(0.0, 1.0);
    final bool isMet = password.length >= 8;

    final Color statusColor = isMet
        ? clinic.success
        : (password.length >= 5 ? clinic.warning : cs.error);

    final String statusLabel = isMet
        ? AppStringsAuth.strengthStrong
        : '${password.length}/8';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStringsAuth.passwordStrength,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            Text(
              statusLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.r999),
          child: Container(
            height: 4,
            color: cs.outline.withValues(alpha: 0.35),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0.0, end: progress),
              builder: (context, val, _) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: val.clamp(0.05, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(AppSizes.r999),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSizes.p10),
        Wrap(
          spacing: AppSizes.p8,
          runSpacing: AppSizes.p4,
          children: requirements.map((req) {
            final bool isMet = req.test(password);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isMet
                        ? clinic.success.withValues(alpha: 0.15)
                        : cs.onSurfaceVariant.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isMet ? Icons.check : Icons.circle,
                      size: isMet ? 10 : 4,
                      color: isMet ? clinic.success : cs.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.p4),
                Text(
                  req.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isMet ? cs.onSurface : cs.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
