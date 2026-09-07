import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Labelled secondary action on wide viewports, or clean overflow menu on mobile.
class TodayDoctorReplacementAction extends StatelessWidget {
  const TodayDoctorReplacementAction({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    if (isWide) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(LucideIcons.arrow_left_right, size: 14.0, color: cs.onSurface),
        label: Text(
          AppStrings.replaceDoctor,
          style: AppTextStyles.captionBold.copyWith(color: cs.onSurface),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
          minimumSize: const Size(0, 40.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
          side: BorderSide(
            color: cs.outlineVariant.withAlpha(140),
            width: AppSizes.borderWidth,
          ),
        ),
      );
    }

    return PopupMenuButton<String>(
      tooltip: AppStrings.moreActions,
      icon: Icon(LucideIcons.ellipsis_vertical, size: 18.0, color: cs.onSurfaceVariant),
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.r12),
        side: BorderSide(color: cs.outlineVariant.withAlpha(120), width: AppSizes.borderWidth),
      ),
      onSelected: (_) => onPressed(),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'replace_doctor',
          height: AppSizes.buttonHeightSmall,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.arrow_left_right, size: 16.0, color: cs.onSurface),
              const SizedBox(width: AppSizes.p8),
              Text(
                AppStrings.replaceDoctor,
                style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Backward-compatible alias for [TodayDoctorReplacementAction].
typedef TodayReplaceDoctorButton = TodayDoctorReplacementAction;
