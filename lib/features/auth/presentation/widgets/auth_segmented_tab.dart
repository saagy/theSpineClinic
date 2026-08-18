import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings_auth.dart';

/// Segmented pill tab switch for toggling between Sign In and Registration.
class AuthSegmentedTab extends StatelessWidget {
  /// Creates an [AuthSegmentedTab].
  const AuthSegmentedTab({
    super.key,
    required this.isRegister,
    required this.onTabChanged,
    this.enabled = true,
  });

  /// Whether the active tab is Registration.
  final bool isRegister;

  /// Triggered when the user taps a tab.
  final ValueChanged<bool> onTabChanged;

  /// Whether interaction is enabled.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      height: 44,
      padding: const EdgeInsets.all(AppSizes.p4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSizes.r999),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.35),
          width: AppSizes.borderWidth,
        ),
      ),
      child: Stack(
        children: [
          // Animated sliding pill indicator
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            alignment: isRegister ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(AppSizes.r999),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tab labels row
          Row(
            children: [
              Expanded(
                child: _TabButton(
                  label: AppStringsAuth.signIn,
                  isSelected: !isRegister,
                  onTap: enabled ? () => onTabChanged(false) : null,
                ),
              ),
              Expanded(
                child: _TabButton(
                  label: AppStringsAuth.register,
                  isSelected: isRegister,
                  onTap: enabled ? () => onTabChanged(true) : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.r999),
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: theme.textTheme.bodyMedium!.copyWith(
            color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
