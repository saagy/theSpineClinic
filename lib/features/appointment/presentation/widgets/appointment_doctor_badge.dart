import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Contextual doctor badge for appointment agenda rows.
///
/// Displays a single doctor, or `Dr. First +N` badge when multiple doctors
/// are assigned to an appointment. Hovering (or long-pressing on mobile)
/// reveals a tooltip listing all assigned doctors.
class AppointmentDoctorBadge extends StatelessWidget {
  const AppointmentDoctorBadge({
    super.key,
    this.doctorNames = const <String>[],
    this.fallbackDoctorName,
    this.isCompact = false,
  });

  final List<String> doctorNames;
  final String? fallbackDoctorName;
  final bool isCompact;

  static String formatDoctorName(String name) {
    final trimmed = name.trim();
    if (trimmed.toLowerCase().startsWith('dr.') ||
        trimmed.toLowerCase().startsWith('dr ')) {
      return trimmed;
    }
    return 'Dr. $trimmed';
  }

  List<String> get _resolvedDoctors {
    if (doctorNames.isNotEmpty) return doctorNames;
    if (fallbackDoctorName != null && fallbackDoctorName!.trim().isNotEmpty) {
      return fallbackDoctorName!
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  @override
  Widget build(BuildContext context) {
    final doctors = _resolvedDoctors;
    if (doctors.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final allFormatted = doctors.map(formatDoctorName).toList();
    final String tooltipMessage = allFormatted.join('\n');

    final TextStyle textStyle = isCompact
        ? AppTextStyles.caption.copyWith(
            color: cs.onSurfaceVariant,
            fontSize: 10.5,
          )
        : AppTextStyles.caption.copyWith(
            color: cs.onSurfaceVariant,
            fontSize: 12.0,
          );

    if (doctors.length == 1) {
      final displayName =
          isCompact ? '• ${allFormatted.first}' : allFormatted.first;
      return Tooltip(
        message: tooltipMessage,
        waitDuration: const Duration(milliseconds: 200),
        child: Text(
          displayName,
          style: textStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    final String primary =
        isCompact ? '• ${allFormatted.first}' : allFormatted.first;
    final int extraCount = doctors.length - 1;
    final String badgeText = '+$extraCount';

    return Tooltip(
      message: tooltipMessage,
      waitDuration: const Duration(milliseconds: 200),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              primary,
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSizes.p4),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 3.5 : 5.0,
              vertical: isCompact ? 0.5 : 1.0,
            ),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withAlpha(120),
              borderRadius: BorderRadius.circular(AppSizes.r4),
            ),
            child: Text(
              badgeText,
              style: AppTextStyles.captionBold.copyWith(
                fontSize: isCompact ? 9.5 : 10.5,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
