/// Touch-first app button with themed variants and tap feedback.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/app_button_style.dart';

export 'package:spine_clinic_app/shared/widgets/app_button_style.dart'
    show AppButtonShape, AppButtonVariant;

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.labelText,
    required this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.fullWidth = true,
    this.debounceMs = 0,
    this.shape = AppButtonShape.rounded,
    this.icon,
  });

  final String labelText;
  final FutureOr<void> Function()? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final bool fullWidth;
  final int debounceMs;
  final AppButtonShape shape;
  final IconData? icon;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  bool _coolingDown = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      lowerBound: 0.98,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onPressed == null || widget.isLoading || _coolingDown) return;
    final FutureOr<void> result = widget.onPressed!();
    if (widget.debounceMs > 0) {
      setState(() => _coolingDown = true);
      _timer?.cancel();
      _timer = Timer(Duration(milliseconds: widget.debounceMs), () {
        if (mounted) setState(() => _coolingDown = false);
      });
    }
    if (result is Future<void>) {
      unawaited(result.catchError((Object _) {}));
    }
  }

  void _press(bool isDown) {
    if (widget.onPressed == null || widget.isLoading || _coolingDown) return;
    if (isDown) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled =
        widget.onPressed == null || widget.isLoading || _coolingDown;
    final AppButtonColors colors = AppButtonColors.resolve(
      context,
      widget.variant,
      isDisabled,
    );
    final bool showSpinner = widget.isLoading || _coolingDown;
    final Widget button = Container(
      height: AppSizes.buttonHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: appButtonBorderRadius(widget.shape),
        border: colors.border,
        boxShadow: colors.shadows,
      ),
      child: Center(
        child: showSpinner
            ? SizedBox(
                height: AppSizes.iconSmall,
                width: AppSizes.iconSmall,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.foreground),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: colors.foreground,
                      size: AppSizes.iconSmall,
                    ),
                    const SizedBox(width: AppSizes.p8),
                  ],
                  Text(
                    widget.labelText,
                    style: AppTextStyles.button.copyWith(
                      color: colors.foreground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );

    return ScaleTransition(
      scale: _animationController,
      child: GestureDetector(
        onTapDown: (_) => _press(true),
        onTapUp: (_) => _press(false),
        onTapCancel: () => _press(false),
        onTap: isDisabled ? null : _handleTap,
        child: widget.fullWidth
            ? SizedBox(width: double.infinity, child: button)
            : button,
      ),
    );
  }
}
