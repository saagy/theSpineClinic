import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/form_field_label.dart';

class TreatmentDurationControl extends StatelessWidget {
  const TreatmentDurationControl({super.key, required this.minutes, required this.onChanged});
  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => FormFieldLabel(
    label: AppStrings.durationMinutes,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          tooltip: AppStrings.decreaseDuration,
          onPressed: minutes > 5 ? () => onChanged((minutes - 5).clamp(5, 60)) : null,
          style: IconButton.styleFrom(minimumSize: const Size.square(AppSizes.tappableMin)),
          icon: const Icon(Icons.remove, size: AppSizes.iconSmall),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
          child: Semantics(
            liveRegion: true,
            child: Text(AppStrings.durationFormat(minutes), style: AppTextStyles.bodyBold),
          ),
        ),
        IconButton.outlined(
          tooltip: AppStrings.increaseDuration,
          onPressed: minutes < 60 ? () => onChanged((minutes + 5).clamp(5, 60)) : null,
          style: IconButton.styleFrom(minimumSize: const Size.square(AppSizes.tappableMin)),
          icon: const Icon(Icons.add, size: AppSizes.iconSmall),
        ),
      ],
    ),
  );
}
