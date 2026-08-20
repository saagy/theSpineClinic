import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// A morphing status badge that smoothly cross-fades background colors
/// and labels when status states change (e.g. Scheduled -> Checked In).
///
/// On Web ([kIsWeb]), color and text transitions are instant.
class AnimatedAppBadge extends StatelessWidget {
  /// Creates an [AnimatedAppBadge].
  const AnimatedAppBadge({
    super.key,
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    this.duration = const Duration(milliseconds: 180),
  });

  /// The text content displayed inside the badge.
  final String label;

  /// Foreground text color.
  final Color textColor;

  /// Background container color.
  final Color backgroundColor;

  /// Duration of the color and text morph animation.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final Duration effectiveDuration = kIsWeb ? Duration.zero : duration;

    return AnimatedContainer(
      duration: effectiveDuration,
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r4)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p8,
        vertical: AppSizes.p4,
      ),
      child: AnimatedSwitcher(
        duration: effectiveDuration,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: Text(
          label,
          key: ValueKey<String>(label),
          style: AppTextStyles.captionBold.copyWith(
            color: textColor,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
