import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';

class PatientIdLabel extends StatelessWidget {
  const PatientIdLabel(this.number, {super.key});
  final int number;

  @override
  Widget build(BuildContext context) => Text(
    AppStrings.patientIdLabel(number),
    style: AppTextStyles.captionMedium.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    ),
  );
}
