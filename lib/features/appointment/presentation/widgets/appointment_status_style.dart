/// Status-driven colour tokens shared by [ReceptionistAppointmentCard].
///
/// Extracted to keep the card file under 200 lines (Rule 1).
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';

/// Colour tokens for each appointment status: background, border, time colour,
/// avatar background, name decoration, and name colour.
class AppointmentStatusStyle {
  const AppointmentStatusStyle({
    required this.bg,
    required this.border,
    required this.timeColor,
    required this.avatarBg,
    required this.nameDecoration,
    required this.nameColor,
  });

  final Color bg;
  final Color border;
  final Color timeColor;
  final Color avatarBg;
  final TextDecoration? nameDecoration;
  final Color nameColor;

  static AppointmentStatusStyle forStatus(AppointmentStatus s) => switch (s) {
    AppointmentStatus.checkedIn => const AppointmentStatusStyle(
        bg: Color(0xFFF0FAF6),
        border: Color(0xFF9FE1CB),
        timeColor: Color(0xFF085041),
        avatarBg: AppColors.primary,
        nameDecoration: null,
        nameColor: AppColors.textPrimary,
      ),
    AppointmentStatus.cancelled => const AppointmentStatusStyle(
        bg: AppColors.surface,
        border: AppColors.border,
        timeColor: AppColors.textMuted,
        avatarBg: AppColors.textMuted,
        nameDecoration: TextDecoration.lineThrough,
        nameColor: AppColors.textMuted,
      ),
    _ => const AppointmentStatusStyle(
        bg: AppColors.surface,
        border: AppColors.border,
        timeColor: AppColors.textPrimary,
        avatarBg: AppColors.primary,
        nameDecoration: null,
        nameColor: AppColors.textPrimary,
      ),
  };
}
