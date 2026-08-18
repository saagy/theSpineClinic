import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';

/// Standard brand mark widget rendering the official SVG logo of The Spine Clinic.
///
/// Can be displayed in varying widths with an optional subtitle.
/// Adheres to Medics UI Kit guidelines and Theme-driven colors.
class ClinicBrandMark extends StatelessWidget {
  /// Creates a [ClinicBrandMark].
  const ClinicBrandMark({
    super.key,
    this.width = 220,
    this.showSubtitle = true,
    this.customColor,
  });

  /// The width constraint for the brand mark.
  final double width;

  /// Whether to display the 'Clinical Excellence Center' subtitle below the logo.
  final bool showSubtitle;

  /// Optional custom color filter for the logo. Defaults to [ColorScheme.primary].
  final Color? customColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final Color logoColor = customColor ?? cs.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: width,
          child: SvgPicture.asset(
            'assets/spine_logo.svg',
            width: width,
            colorFilter: ColorFilter.mode(
              logoColor,
              BlendMode.srcIn,
            ),
          ),
        ),
        if (showSubtitle) ...[
          const SizedBox(height: AppSizes.p6),
          Text(
            'Clinical Excellence Center',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 1.2,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
