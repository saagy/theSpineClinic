/// Status-driven colour tokens shared by [ReceptionistAppointmentCard].
///
/// Extracted to keep the card file under 200 lines (Rule 1).
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
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

  static AppointmentStatusStyle forStatus(
    BuildContext context,
    AppointmentStatus s,
  ) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ClinicColors clinic = ClinicColors.of(context);

    return switch (s) {
      AppointmentStatus.checkedIn => AppointmentStatusStyle(
        bg: clinic.checkedInContainer,
        border: clinic.checkedInOutline,
        timeColor: cs.onPrimaryContainer,
        avatarBg: cs.primary,
        nameDecoration: null,
        nameColor: cs.onSurface,
      ),
      AppointmentStatus.cancelled => AppointmentStatusStyle(
        bg: cs.surface,
        border: cs.outline,
        timeColor: clinic.textMuted,
        avatarBg: clinic.textMuted,
        nameDecoration: TextDecoration.lineThrough,
        nameColor: clinic.textMuted,
      ),
      _ => AppointmentStatusStyle(
        bg: cs.surface,
        border: cs.outline,
        timeColor: cs.onSurface,
        avatarBg: cs.primary,
        nameDecoration: null,
        nameColor: cs.onSurface,
      ),
    };
  }
}
