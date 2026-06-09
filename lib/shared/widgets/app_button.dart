/// Custom button widget matching the Stripe Dashboard styling design tokens.
///
/// Designed exclusively for phone/touch interactions: no hover states or MouseRegions.
/// Supports three variants (primary, secondary, danger), loading indicators,
/// and a mechanical tap shrink effect (0.98 scale transition).
///
/// Rule 1 — keep files under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Available button design variants.
enum AppButtonVariant {
  /// Stripe Blurple solid background, white text.
  primary,

  /// White background, Slate 200 border, dark text, and subtle card shadow.
  secondary,

  /// Rose 600 solid background, white text.
  danger,

  /// Amber 600 solid background, white text.
  warning,

  /// Emerald 600 solid background, white text.
  success,
}

/// A highly-polished button component built with Spine Clinic design tokens.
class AppButton extends StatefulWidget {
  /// Creates an [AppButton].
  const AppButton({
    super.key,
    required this.labelText,
    required this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.fullWidth = true,
  });

  /// The text label displayed inside the button.
  final String labelText;

  /// Callback when the button is tapped. If null, the button is disabled.
  final VoidCallback? onPressed;

  /// If true, displays a progress spinner and disables interactions.
  final bool isLoading;

  /// The visual theme variant of this button.
  final AppButtonVariant variant;

  /// If true, stretches the button to fill horizontal parent space.
  final bool fullWidth;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

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
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.reverse();
    }
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.forward();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null || widget.isLoading;

    // Resolve visual assets from design tokens
    final Color backgroundColor;
    final Color textColor;
    final BorderSide borderSide;
    final List<BoxShadow> shadows;

    if (isDisabled) {
      backgroundColor = widget.variant == AppButtonVariant.secondary
          ? AppColors.surface
          : AppColors.textMuted.withAlpha(50);
      textColor = AppColors.textMuted;
      borderSide = widget.variant == AppButtonVariant.secondary
          ? const BorderSide(color: AppColors.border, width: AppSizes.borderWidth)
          : BorderSide.none;
      shadows = const [];
    } else {
      switch (widget.variant) {
        case AppButtonVariant.primary:
          backgroundColor = AppColors.primary;
          textColor = AppColors.textOnPrimary;
          borderSide = BorderSide.none;
          shadows = const [];
          break;
        case AppButtonVariant.secondary:
          backgroundColor = AppColors.surface;
          textColor = AppColors.textSecondary;
          borderSide = const BorderSide(color: AppColors.border, width: AppSizes.borderWidth);
          shadows = const [AppColors.cardShadow];
          break;
        case AppButtonVariant.danger:
          backgroundColor = AppColors.error;
          textColor = AppColors.textOnPrimary;
          borderSide = BorderSide.none;
          shadows = const [];
          break;
        case AppButtonVariant.warning:
          backgroundColor = AppColors.warning;
          textColor = AppColors.textOnPrimary;
          borderSide = BorderSide.none;
          shadows = const [];
          break;
        case AppButtonVariant.success:
          backgroundColor = AppColors.success;
          textColor = AppColors.textOnPrimary;
          borderSide = BorderSide.none;
          shadows = const [];
          break;
      }
    }

    final Widget content = widget.isLoading
        ? Center(
            child: SizedBox(
              height: AppSizes.iconSmall,
              width: AppSizes.iconSmall,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            ),
          )
        : Center(
            child: Text(
              widget.labelText,
              style: AppTextStyles.button.copyWith(color: textColor),
              textAlign: TextAlign.center,
            ),
          );

    final Widget buttonDecoration = Container(
      height: AppSizes.h48, // Standardized comfortable height (48 px)
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r8)),
        border: borderSide != BorderSide.none
            ? Border.all(color: borderSide.color, width: borderSide.width)
            : null,
        boxShadow: shadows,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
      child: content,
    );

    return ScaleTransition(
      scale: _animationController,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: isDisabled ? null : widget.onPressed,
        child: widget.fullWidth
            ? SizedBox(width: double.infinity, child: buttonDecoration)
            : buttonDecoration,
      ),
    );
  }
}
