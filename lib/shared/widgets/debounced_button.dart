/// A wrapper around [ElevatedButton] that enforces a mandatory 1000 ms
/// cool-down after every tap, preventing double-submission bugs across
/// the app.
///
/// While cooling down the button shows a [CircularProgressIndicator]
/// and is non-interactive. Drop-in replacement for any [ElevatedButton]
/// whose [onPressed] performs a high-consequence state mutation.
///
/// Rule 1  — under 200 lines.
/// Rule 11 — touch-optimised.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// A drop-in replacement for [ElevatedButton] with built-in 1000 ms
/// debounce and visual loading feedback.
///
/// Use everywhere a double-tap could create duplicate records:
/// save, submit, upload, book, confirm, pay.
class DebouncedElevatedButton extends StatefulWidget {
  /// Creates a [DebouncedElevatedButton].
  const DebouncedElevatedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style,
    this.cooldownMs = 1000,
  });

  /// The text shown on the button (replaced by a spinner during cooldown).
  final String label;

  /// The async action to perform. The button stays locked until both the
  /// action completes AND the cooldown elapses.
  final Future<void> Function() onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional [ElevatedButton.styleFrom] overrides. If not provided a
  /// primary-themed style is used.
  final ButtonStyle? style;

  /// Milliseconds the button stays locked after each tap. Default 1000.
  final int cooldownMs;

  @override
  State<DebouncedElevatedButton> createState() =>
      _DebouncedElevatedButtonState();
}

class _DebouncedElevatedButtonState extends State<DebouncedElevatedButton> {
  bool _coolingDown = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_coolingDown) return;
    setState(() => _coolingDown = true);
    try {
      await widget.onPressed();
    } finally {
      _timer?.cancel();
      _timer = Timer(Duration(milliseconds: widget.cooldownMs), () {
        if (mounted) setState(() => _coolingDown = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle effectiveStyle = widget.style ??
        ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p24, vertical: AppSizes.p14),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppSizes.r12)),
          ),
          elevation: 0,
        );

    return ElevatedButton(
      onPressed: _coolingDown ? null : _handleTap,
      style: effectiveStyle,
      child: _coolingDown
          ? const SizedBox(
              width: AppSizes.iconDefault,
              height: AppSizes.iconDefault,
              child: CircularProgressIndicator(
                strokeWidth: AppSizes.strokeWidthThin,
                color: AppColors.textOnPrimary,
              ),
            )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon,
                        size: AppSizes.iconSmall,
                        color: AppColors.textOnPrimary),
                    const SizedBox(width: AppSizes.p8),
                  ],
                  // Strip the baked-in dark colour from bodyBold so the
                  // ElevatedButton's foregroundColor (white on teal) always
                  // wins — both light AND dark theme.
                  Text(
                    widget.label,
                    style: AppTextStyles.bodyBold.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ],
              ),
    );
  }
}
