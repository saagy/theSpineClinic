/// Modern pill-shaped primary action button.
///
/// Full-width teal pill button with scale-down press animation,
/// loading spinner state, and soft shadow. Follows the Medics
/// Medical App UI Kit style.
///
/// Rule 1 — under 200 lines.
/// Rule 11 — touch-optimised, no hover states.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// A full-width pill-shaped primary button with press animation.
class PrimaryButton extends StatefulWidget {
  /// Creates a [PrimaryButton].
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = PrimaryButtonVariant.primary,
  });

  /// The text displayed on the button.
  final String label;

  /// Called when the button is tapped. Set to `null` to disable.
  final VoidCallback? onPressed;

  /// When `true`, shows a loading spinner and disables interaction.
  final bool isLoading;

  /// The visual variant of the button.
  final PrimaryButtonVariant variant;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

/// Visual variants for [PrimaryButton].
enum PrimaryButtonVariant {
  /// Teal fill with white text — the dominant action.
  primary,

  /// White fill with teal border and teal text — secondary action.
  secondary,

  /// Rose fill with white text — destructive action.
  danger,
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    _isPressed = true;
    _scaleCtrl.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (_isPressed) {
      _isPressed = false;
      _scaleCtrl.reverse();
    }
  }

  void _onTapCancel() {
    if (_isPressed) {
      _isPressed = false;
      _scaleCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null || widget.isLoading;

    final Color bgColor;
    final Color fgColor;
    final BorderSide? borderSide;

    switch (widget.variant) {
      case PrimaryButtonVariant.primary:
        bgColor = isDisabled
            ? AppColors.textMuted.withAlpha(80)
            : AppColors.primary;
        fgColor = AppColors.textOnPrimary;
        borderSide = null;
        break;
      case PrimaryButtonVariant.secondary:
        bgColor = AppColors.surface;
        fgColor = isDisabled ? AppColors.textMuted : AppColors.primary;
        borderSide = BorderSide(
          color: isDisabled ? AppColors.border : AppColors.primary,
          width: AppSizes.borderWidth,
        );
        break;
      case PrimaryButtonVariant.danger:
        bgColor = isDisabled
            ? AppColors.textMuted.withAlpha(80)
            : AppColors.error;
        fgColor = AppColors.textOnPrimary;
        borderSide = null;
        break;
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: AppSizes.buttonHeight,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppSizes.borderRadiusPill,
            border: borderSide != null ? Border.fromBorderSide(borderSide) : null,
            boxShadow: widget.variant == PrimaryButtonVariant.primary &&
                    !isDisabled
                ? [AppColors.cardShadow]
                : null,
          ),
          child: Center(
            child: _buildContent(fgColor),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color fgColor) {
    if (widget.isLoading) {
      return SizedBox(
        width: AppSizes.iconLarge,
        height: AppSizes.iconLarge,
        child: CircularProgressIndicator(
          strokeWidth: AppSizes.strokeWidthThin,
          valueColor: AlwaysStoppedAnimation<Color>(fgColor),
        ),
      );
    }

    return Text(
      widget.label,
      style: AppTextStyles.button.copyWith(color: fgColor),
    );
  }
}
