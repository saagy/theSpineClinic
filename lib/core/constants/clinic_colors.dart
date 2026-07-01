import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';

/// App-specific semantic colors that do not belong in Material [ColorScheme].
@immutable
class ClinicColors extends ThemeExtension<ClinicColors> {
  const ClinicColors({
    required this.textMuted,
    required this.outlineStrong,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.info,
    required this.infoContainer,
    required this.neutral,
    required this.neutralContainer,
    required this.checkedInContainer,
    required this.checkedInOutline,
    required this.cardShadow,
    required this.elevatedShadow,
    required this.overlayScrim,
  });

  final Color textMuted;
  final Color outlineStrong;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color info;
  final Color infoContainer;
  final Color neutral;
  final Color neutralContainer;
  final Color checkedInContainer;
  final Color checkedInOutline;
  final BoxShadow cardShadow;
  final BoxShadow elevatedShadow;
  final Color overlayScrim;

  static ClinicColors of(BuildContext context) {
    return Theme.of(context).extension<ClinicColors>() ??
        fromPalette(clinicalBluePaletteLight);
  }

  static ClinicColors fromPalette(AppPalette palette, {bool isDark = false}) {
    if (isDark) {
      return ClinicColors(
        textMuted: palette.textMuted,
        outlineStrong: palette.outlineStrong,
        success: const Color(0xFF34D399),
        successContainer: const Color(0xFF064E3B),
        warning: const Color(0xFFFBBF24),
        warningContainer: const Color(0xFF451A03),
        info: const Color(0xFF38BDF8),
        infoContainer: const Color(0xFF082F49),
        neutral: const Color(0xFFCBD5E1),
        neutralContainer: const Color(0xFF1E293B),
        checkedInContainer: const Color(0xFF123328),
        checkedInOutline: const Color(0xFF356B5A),
        cardShadow: const BoxShadow(
          color: Color(0x26000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
        elevatedShadow: const BoxShadow(
          color: Color(0x40000000),
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
        overlayScrim: const Color(0x99000000),
      );
    }

    return ClinicColors(
      textMuted: palette.textMuted,
      outlineStrong: palette.outlineStrong,
      success: const Color(0xFF059669),
      successContainer: const Color(0xFFECFDF5),
      warning: const Color(0xFFD97706),
      warningContainer: const Color(0xFFFFFBEB),
      info: const Color(0xFF0284C7),
      infoContainer: const Color(0xFFF0F9FF),
      neutral: const Color(0xFF475569),
      neutralContainer: const Color(0xFFF1F5F9),
      checkedInContainer: const Color(0xFFF0FAF6),
      checkedInOutline: const Color(0xFF9FE1CB),
      cardShadow: const BoxShadow(
        color: Color(0x08000000),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
      elevatedShadow: const BoxShadow(
        color: Color(0x0F000000),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
      overlayScrim: const Color(0x4D000000),
    );
  }

  @override
  ClinicColors copyWith({
    Color? textMuted,
    Color? outlineStrong,
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? info,
    Color? infoContainer,
    Color? neutral,
    Color? neutralContainer,
    Color? checkedInContainer,
    Color? checkedInOutline,
    BoxShadow? cardShadow,
    BoxShadow? elevatedShadow,
    Color? overlayScrim,
  }) {
    return ClinicColors(
      textMuted: textMuted ?? this.textMuted,
      outlineStrong: outlineStrong ?? this.outlineStrong,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      neutral: neutral ?? this.neutral,
      neutralContainer: neutralContainer ?? this.neutralContainer,
      checkedInContainer: checkedInContainer ?? this.checkedInContainer,
      checkedInOutline: checkedInOutline ?? this.checkedInOutline,
      cardShadow: cardShadow ?? this.cardShadow,
      elevatedShadow: elevatedShadow ?? this.elevatedShadow,
      overlayScrim: overlayScrim ?? this.overlayScrim,
    );
  }

  @override
  ClinicColors lerp(ThemeExtension<ClinicColors>? other, double t) {
    if (other is! ClinicColors) return this;
    return ClinicColors(
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      outlineStrong: Color.lerp(outlineStrong, other.outlineStrong, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      neutralContainer: Color.lerp(
        neutralContainer,
        other.neutralContainer,
        t,
      )!,
      checkedInContainer: Color.lerp(
        checkedInContainer,
        other.checkedInContainer,
        t,
      )!,
      checkedInOutline: Color.lerp(
        checkedInOutline,
        other.checkedInOutline,
        t,
      )!,
      cardShadow: BoxShadow.lerp(cardShadow, other.cardShadow, t)!,
      elevatedShadow: BoxShadow.lerp(elevatedShadow, other.elevatedShadow, t)!,
      overlayScrim: Color.lerp(overlayScrim, other.overlayScrim, t)!,
    );
  }
}
