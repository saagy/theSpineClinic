import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';

/// Segmented role selector component with smooth animated active state.
class AuthRoleSelector extends StatelessWidget {
  /// Creates an [AuthRoleSelector].
  const AuthRoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
    this.enabled = true,
  });

  /// The currently selected [UserRole].
  final UserRole selectedRole;

  /// Callback when a new role is selected.
  final ValueChanged<UserRole> onRoleChanged;

  /// Whether the selector is interactive.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSizes.p4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppSizes.r16),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.4),
          width: AppSizes.borderWidth,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RoleButton(
              title: AppStrings.doctorRoleLabel,
              icon: LucideIcons.stethoscope,
              isSelected: selectedRole == UserRole.doctor,
              onTap: enabled ? () => onRoleChanged(UserRole.doctor) : null,
            ),
          ),
          const SizedBox(width: AppSizes.p4),
          Expanded(
            child: _RoleButton(
              title: AppStrings.receptionistRoleLabel,
              icon: LucideIcons.user_round_check,
              isSelected: selectedRole == UserRole.receptionist,
              onTap: enabled ? () => onRoleChanged(UserRole.receptionist) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.p10,
          horizontal: AppSizes.p12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.r12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: AppSizes.p6),
            Flexible(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected ? cs.onPrimary : cs.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
