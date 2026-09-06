import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';

/// A sleek, high-density pill displaying package balances (Sessions & Traction).
///
/// Formats balances as e.g. `8S • 2T` with tabular/monospaced numbers and
/// semantic color-coding. Zero balances display in a subtle warning tint.
class PatientBalancePill extends StatelessWidget {
  const PatientBalancePill({
    super.key,
    required this.sessionBalance,
    required this.tractionBalance,
    this.showLabels = false,
  });

  final int sessionBalance;
  final int tractionBalance;
  final bool showLabels;

  bool get _isDepleted => sessionBalance <= 0 && tractionBalance <= 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final clinic = ClinicColors.of(context);

    final Color bgColor = _isDepleted
        ? clinic.warningContainer.withAlpha(120)
        : cs.surfaceContainerHighest.withAlpha(160);

    final Color textColor = _isDepleted
        ? clinic.warning
        : cs.onSurfaceVariant;

    final String text = showLabels
        ? '${AppStrings.sessionsShort}: $sessionBalance  ${AppStrings.tractionShort}: $tractionBalance'
        : '$sessionBalance${AppStrings.sessionsShort}  •  $tractionBalance${AppStrings.tractionShort}';

    return Tooltip(
      message:
          '$sessionBalance ${AppStrings.sessionBalance}, $tractionBalance ${AppStrings.tractionBalance}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p8,
          vertical: AppSizes.p4,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSizes.r6),
          border: Border.all(
            color: _isDepleted
                ? clinic.warning.withAlpha(80)
                : cs.outlineVariant.withAlpha(100),
            width: AppSizes.borderWidth,
          ),
        ),
        child: Text(
          text,
          style: AppTextStyles.captionBold.copyWith(
            color: textColor,
            fontFeatures: const [FontFeature.tabularFigures()],
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
