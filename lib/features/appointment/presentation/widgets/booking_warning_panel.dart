import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';

/// A non-blocking booking warning: an optional headline, one line per
/// finding and a closing note saying the booking can still go ahead.
/// Announced to screen readers when it appears.
class BookingWarningPanel extends StatelessWidget {
  const BookingWarningPanel({
    super.key,
    required this.icon,
    required this.lines,
    required this.note,
    this.title,
  });

  final IconData icon;
  final String? title;
  final List<String> lines;
  final String note;

  @override
  Widget build(BuildContext context) {
    final ClinicColors clinic = ClinicColors.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.p12),
        decoration: BoxDecoration(
          color: clinic.warningContainer,
          borderRadius: BorderRadius.circular(AppSizes.r8),
          border: Border.all(color: clinic.warning.withAlpha(110), width: AppSizes.borderWidth),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: AppSizes.iconSmall, color: clinic.warning),
            const SizedBox(width: AppSizes.p8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.p4),
                      child: Text(title!, style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurface)),
                    ),
                  for (final String line in lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.p4),
                      child: Text(
                        line,
                        style: (title == null ? AppTextStyles.bodyMedium : AppTextStyles.body)
                            .copyWith(color: colors.onSurface),
                      ),
                    ),
                  Text(note, style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
