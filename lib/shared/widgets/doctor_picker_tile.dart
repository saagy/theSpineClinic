import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';

/// A modern Material 3 doctor tile used inside doctor picker sheets and selection dialogs.
class DoctorPickerTile extends StatelessWidget {
  const DoctorPickerTile({
    super.key,
    required this.doctor,
    required this.isSelected,
    required this.onTap,
    this.isMultiSelect = true,
  });

  final Staff doctor;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isMultiSelect;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ClinicColors clinic = ClinicColors.of(context);
    final bool isDeactivated = !doctor.isActive;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p4,
      ),
      child: Material(
        color: isSelected
            ? cs.primaryContainer.withValues(alpha: 0.5)
            : cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
          side: BorderSide(
            color: isSelected
                ? cs.primary
                : cs.outlineVariant.withValues(alpha: 0.7),
            width: isSelected ? AppSizes.borderWidthFocused : AppSizes.borderWidth,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Row(
              children: [
                AppAvatar(
                  name: doctor.fullName,
                  radius: AppSizes.avatarMedium / 2,
                ),
                const SizedBox(width: AppSizes.p12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              doctor.fullName,
                              style: AppTextStyles.bodyBold.copyWith(
                                color: isDeactivated
                                    ? cs.onSurface.withValues(alpha: 0.6)
                                    : cs.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isDeactivated) ...[
                            const SizedBox(width: AppSizes.p6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.p6,
                                vertical: AppSizes.p2,
                              ),
                              decoration: BoxDecoration(
                                color: clinic.warningContainer,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(AppSizes.r4),
                                ),
                              ),
                              child: Text(
                                AppStrings.deactivated,
                                style: AppTextStyles.caption.copyWith(
                                  color: clinic.warning,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (doctor.branch != null) ...[
                        const SizedBox(height: AppSizes.p2),
                        Text(
                          doctor.branch!.displayLabel,
                          style: AppTextStyles.caption.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.p8),
                _SelectionIndicator(
                  isSelected: isSelected,
                  isMultiSelect: isMultiSelect,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({
    required this.isSelected,
    required this.isMultiSelect,
  });

  final bool isSelected;
  final bool isMultiSelect;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    if (isMultiSelect) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: AppSizes.iconLarge,
        height: AppSizes.iconLarge,
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : Colors.transparent,
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outline,
            width: AppSizes.borderWidthFocused,
          ),
        ),
        child: isSelected
            ? Icon(
                Icons.check_rounded,
                size: AppSizes.iconSmall,
                color: cs.onPrimary,
              )
            : null,
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: AppSizes.iconLarge,
      height: AppSizes.iconLarge,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? cs.primary : cs.outline,
          width: AppSizes.borderWidthFocused,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: AppSizes.p10,
                height: AppSizes.p10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primary,
                ),
              ),
            )
          : null,
    );
  }
}
