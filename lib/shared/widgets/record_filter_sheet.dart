import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';

class RecordFilterButton extends StatelessWidget {
  const RecordFilterButton({super.key, required this.onPressed, this.compact = false});
  final VoidCallback onPressed;
  final bool compact;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: compact
        ? IconButton.outlined(
            tooltip: AppStrings.filterSort,
            onPressed: onPressed,
            icon: const Icon(LucideIcons.sliders_horizontal, size: AppSizes.iconSmall),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(AppSizes.tappableMin, AppSizes.tappableMin),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
            ),
            icon: const Icon(LucideIcons.sliders_horizontal, size: AppSizes.iconSmall),
            label: const Text(AppStrings.filterSort),
          ),
  );
}
