library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';

class AppointmentBadgeColors {
  const AppointmentBadgeColors({
    required this.textColor,
    required this.backgroundColor,
  });

  final Color textColor;
  final Color backgroundColor;
}

extension AppointmentStatusBadgeColors on AppointmentStatus {
  AppointmentBadgeColors badgeColors(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ClinicColors clinic = ClinicColors.of(context);

    return switch (this) {
      AppointmentStatus.scheduled => AppointmentBadgeColors(
          textColor: clinic.neutral,
          backgroundColor: clinic.neutralContainer,
        ),
      AppointmentStatus.checkedIn || AppointmentStatus.completed =>
        AppointmentBadgeColors(
          textColor: clinic.success,
          backgroundColor: clinic.successContainer,
        ),
      AppointmentStatus.cancelled || AppointmentStatus.noShow =>
        AppointmentBadgeColors(
          textColor: cs.onErrorContainer,
          backgroundColor: cs.errorContainer,
        ),
    };
  }
}

extension AppointmentTypeBadgeColors on AppointmentType {
  AppointmentBadgeColors badgeColors(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ClinicColors clinic = ClinicColors.of(context);

    return switch (this) {
      AppointmentType.normalPtSession => AppointmentBadgeColors(
          textColor: cs.onPrimaryContainer,
          backgroundColor: cs.primaryContainer,
        ),
      AppointmentType.spinalTractionSession => AppointmentBadgeColors(
          textColor: clinic.warning,
          backgroundColor: clinic.warningContainer,
        ),
      AppointmentType.initialAssessment || AppointmentType.reassessment =>
        AppointmentBadgeColors(
          textColor: clinic.info,
          backgroundColor: clinic.infoContainer,
        ),
    };
  }
}
