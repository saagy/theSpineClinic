import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';

class EmptyDoctorSelectorCard extends StatelessWidget {
  const EmptyDoctorSelectorCard({
    super.key,
    required this.hasError,
    required this.enabled,
    required this.onTap,
  });

  final bool hasError;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        side: BorderSide(
          color: hasError ? cs.error : cs.outlineVariant,
          width: AppSizes.borderWidth,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Row(
            children: [
              Container(
                width: AppSizes.avatarMedium,
                height: AppSizes.avatarMedium,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
                ),
                child: Icon(
                  Icons.person_add_alt_1_rounded,
                  color: cs.primary,
                  size: AppSizes.iconLarge,
                ),
              ),
              const SizedBox(width: AppSizes.p16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.selectDoctors,
                      style: AppTextStyles.bodyBold.copyWith(color: cs.onSurface),
                    ),
                    const SizedBox(height: AppSizes.p2),
                    Text(
                      AppStrings.tapToSelectDoctors,
                      style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant,
                size: AppSizes.iconLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SelectedDoctorsCard extends StatelessWidget {
  const SelectedDoctorsCard({
    super.key,
    required this.selected,
    required this.hasError,
    required this.enabled,
    required this.onAddOrChange,
    required this.onRemove,
  });

  final List<Staff> selected;
  final bool hasError;
  final bool enabled;
  final VoidCallback onAddOrChange;
  final ValueChanged<Staff> onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        border: Border.all(
          color: hasError ? cs.error : cs.outlineVariant,
          width: AppSizes.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.assignedCount(selected.length),
                  style: AppTextStyles.captionBold.copyWith(color: cs.onSurfaceVariant),
                ),
                if (enabled)
                  InkWell(
                    onTap: onAddOrChange,
                    borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r8)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p8,
                        vertical: AppSizes.p4,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add_rounded, size: AppSizes.iconSmall, color: cs.primary),
                          const SizedBox(width: AppSizes.p4),
                          Text(
                            AppStrings.addDoctor,
                            style: AppTextStyles.captionBold.copyWith(color: cs.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.p8),
          ...selected.map((doc) => _DoctorItemRow(
                doctor: doc,
                enabled: enabled,
                onRemove: () => onRemove(doc),
              )),
        ],
      ),
    );
  }
}

class _DoctorItemRow extends StatelessWidget {
  const _DoctorItemRow({
    required this.doctor,
    required this.enabled,
    required this.onRemove,
  });

  final Staff doctor;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p12,
          vertical: AppSizes.p8,
        ),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
        ),
        child: Row(
          children: [
            AppAvatar(name: doctor.fullName, radius: AppSizes.avatarSmall / 2),
            const SizedBox(width: AppSizes.p12),
            Expanded(
              child: Text(
                doctor.fullName,
                style: AppTextStyles.bodyBold.copyWith(color: cs.onSurface),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (enabled)
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: AppSizes.iconSmall,
                  color: cs.onSurfaceVariant,
                ),
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}
