/// Pill-shaped status badge with colour-coded variants.
///
/// Renders a compact label inside a fully rounded pill container.
/// Colour is determined by the [AppointmentStatus] or explicit
/// [color] / [backgroundColor] overrides.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';

/// Predefined status variants that drive the badge colour scheme.
enum StatusVariant {
  /// Primary color — scheduled, confirmed, active.
  active,

  /// Amber — pending, waiting, under review.
  pending,

  /// Rose — cancelled, rejected, inactive.
  cancelled,

  /// Emerald — completed, approved, resolved.
  completed,

  /// Sky — informational, neutral.
  info,
}

/// A compact pill-shaped badge that communicates record status.
class StatusBadge extends StatelessWidget {
  /// Creates a [StatusBadge].
  const StatusBadge({
    super.key,
    required this.label,
    this.variant = StatusVariant.info,
    this.color,
    this.backgroundColor,
  });

  /// The text displayed inside the badge.
  final String label;

  /// The semantic variant that drives the colour scheme.
  final StatusVariant variant;

  /// Override the default foreground colour.
  final Color? color;

  /// Override the default background colour.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final (Color fg, Color bg) = _resolveColors(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p8,
        vertical: AppSizes.p4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppSizes.borderRadiusPill,
      ),
      child: Text(label, style: AppTextStyles.captionBold.copyWith(color: fg)),
    );
  }

  (Color, Color) _resolveColors(BuildContext context) {
    if (color != null && backgroundColor != null) {
      return (color!, backgroundColor!);
    }

    final ColorScheme cs = Theme.of(context).colorScheme;
    final ClinicColors clinic = ClinicColors.of(context);
    switch (variant) {
      case StatusVariant.active:
        return (cs.onPrimary, cs.primary);
      case StatusVariant.pending:
        return (clinic.warning, clinic.warningContainer);
      case StatusVariant.cancelled:
        return (cs.onError, cs.error);
      case StatusVariant.completed:
        return (cs.onPrimary, clinic.success);
      case StatusVariant.info:
        return (clinic.info, clinic.infoContainer);
    }
  }
}
