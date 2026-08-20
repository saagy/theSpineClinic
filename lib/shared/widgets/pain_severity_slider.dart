import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';

/// A tactile 0-10 clinical pain severity selector with smooth color
/// interpolation and haptic feedback on integer steps.
class PainSeveritySlider extends StatefulWidget {
  /// Creates a [PainSeveritySlider].
  const PainSeveritySlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// The current pain score (0 to 10).
  final int value;

  /// Callback when the pain score changes.
  final ValueChanged<int> onChanged;

  @override
  State<PainSeveritySlider> createState() => _PainSeveritySliderState();
}

class _PainSeveritySliderState extends State<PainSeveritySlider> {
  int _lastHapticVal = -1;

  Color _getColorForScore(int score, BuildContext context) {
    final ClinicColors clinic = ClinicColors.of(context);
    final Color errorColor = Theme.of(context).colorScheme.error;
    if (score <= 5) {
      return Color.lerp(clinic.success, clinic.warning, score / 5.0) ??
          clinic.success;
    }
    return Color.lerp(clinic.warning, errorColor, (score - 5.0) / 5.0) ??
        errorColor;
  }

  String _getDescriptor(int score) {
    if (score == 0) return 'No Pain';
    if (score <= 3) return 'Mild';
    if (score <= 6) return 'Moderate';
    if (score <= 9) return 'Severe';
    return 'Worst Possible';
  }

  void _handleChange(double val) {
    final int rounded = val.round();
    if (rounded != _lastHapticVal) {
      _lastHapticVal = rounded;
      if (!kIsWeb) {
        HapticFeedback.selectionClick();
      }
    }
    widget.onChanged(rounded);
  }

  @override
  Widget build(BuildContext context) {
    final Color activeColor = _getColorForScore(widget.value, context);
    final String descriptor = _getDescriptor(widget.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pain Severity Scale',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            AnimatedContainer(
              duration: kIsWeb
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p12,
                vertical: AppSizes.p4,
              ),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.15),
                borderRadius: AppSizes.borderRadiusPill,
                border: Border.all(color: activeColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                '${widget.value} / 10 • $descriptor',
                style: AppTextStyles.captionBold.copyWith(
                  color: activeColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.p8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: activeColor,
            inactiveTrackColor:
                Theme.of(context).colorScheme.outlineVariant,
            thumbColor: activeColor,
            overlayColor: activeColor.withValues(alpha: 0.2),
            trackHeight: 6.0,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 10.0,
            ),
          ),
          child: Slider(
            value: widget.value.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: _handleChange,
          ),
        ),
      ],
    );
  }
}
