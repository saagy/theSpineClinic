/// Helper widgets for [ReceptionistTodayTab]: replace doctor action button.
///
/// Extracted to keep the parent file under 200 lines.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';

/// Circular tonal icon button for replacing absent doctors.
class TodayReplaceDoctorButton extends StatelessWidget {
  const TodayReplaceDoctorButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton.filledTonal(
      style: IconButton.styleFrom(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.primary,
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.swap_horiz_rounded),
      tooltip: AppStrings.replaceDoctor,
    );
  }
}
