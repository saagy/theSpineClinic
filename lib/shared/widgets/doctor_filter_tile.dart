import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';

/// A modern selector tile for filtering or picking a single doctor.
class DoctorFilterTile extends StatelessWidget {
  const DoctorFilterTile({
    super.key,
    required this.selectedDoctor,
    required this.onTap,
    this.onClear,
    this.allDoctorsLabel = AppStrings.allDoctors,
    this.placeholderText,
  });

  final Staff? selectedDoctor;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final String allDoctorsLabel;
  final String? placeholderText;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ClinicColors clinic = ClinicColors.of(context);
    final bool hasSelection = selectedDoctor != null;
    final bool isDeactivated = selectedDoctor != null && !selectedDoctor!.isActive;

    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        side: BorderSide(
          color: hasSelection ? cs.primary : cs.outlineVariant,
          width: hasSelection ? AppSizes.borderWidthFocused : AppSizes.borderWidth,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p16,
            vertical: AppSizes.p12,
          ),
          child: Row(
            children: [
              if (hasSelection)
                AppAvatar(
                  name: selectedDoctor!.fullName,
                  radius: AppSizes.avatarSmall / 2,
                )
              else
                CircleAvatar(
                  radius: AppSizes.avatarSmall / 2,
                  backgroundColor: cs.primaryContainer,
                  child: Icon(
                    Icons.people_alt_rounded,
                    size: AppSizes.iconDefault,
                    color: cs.primary,
                  ),
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
                            hasSelection
                                ? selectedDoctor!.fullName
                                : (placeholderText ?? allDoctorsLabel),
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
                    if (hasSelection && selectedDoctor!.branch != null) ...[
                      const SizedBox(height: AppSizes.p2),
                      Text(
                        selectedDoctor!.branch!.displayLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (hasSelection && onClear != null)
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: AppSizes.iconDefault,
                    color: cs.onSurfaceVariant,
                  ),
                  onPressed: onClear,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                )
              else
                Icon(
                  Icons.unfold_more_rounded,
                  size: AppSizes.iconDefault,
                  color: cs.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
