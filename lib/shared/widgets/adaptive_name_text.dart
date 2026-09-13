import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Fits near-overflow names on one line, then wraps without hiding text.
class AdaptiveNameText extends StatelessWidget {
  const AdaptiveNameText(this.name, {super.key, required this.style});
  final String name;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final sizes = AppTextStyles.appointmentNameSizes;
    if (MediaQuery.textScalerOf(context).scale(sizes.first) > sizes.first) {
      return Text(name, style: style);
    }
    return AutoSizeText(
      name,
      style: style,
      presetFontSizes: sizes,
      minFontSize: sizes.last,
      maxFontSize: sizes.first,
      maxLines: 1,
      overflowReplacement: Text(name, style: style.copyWith(fontSize: sizes.last)),
    );
  }
}
