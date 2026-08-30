library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/medical_records/domain/body_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_status_badge.dart';

/// Card component rendering a program summary in the patient programs list.
///
/// Conditions are grouped under their affected region (max 3 shown, the
/// rest collapsed into a "+N more" line). Raw clinical text is intentionally
/// omitted (Rule 22): it lives in the detail screen.
class ProgramCard extends StatelessWidget {
  const ProgramCard({
    super.key,
    required this.program,
    required this.onTap,
  });

  final PatientProgram program;
  final VoidCallback onTap;

  static const int _maxVisibleConditions = 3;

  /// Groups condition names by body region, regions sorted alphabetically.
  Map<BodyRegion, List<String>> _conditionsByRegion() {
    final map = <BodyRegion, List<String>>{};
    for (final pc in program.conditions) {
      final condition = pc.condition;
      if (condition == null) continue;
      map.putIfAbsent(condition.region, () => []).add(condition.conditionName);
    }
    final sortedKeys = map.keys.toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    return {for (final key in sortedKeys) key: map[key]!};
  }

  Widget _regionPill(BuildContext context, BodyRegion region) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p8,
        vertical: AppSizes.p2,
      ),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(AppSizes.r999),
      ),
      child: Text(
        region.displayName,
        style: AppTextStyles.captionBold.copyWith(
          color: cs.onSecondaryContainer,
        ),
      ),
    );
  }

  Widget _conditionBullet(BuildContext context, String name) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSizes.p8,
        top: AppSizes.p4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.bodySecondary.copyWith(color: cs.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final grouped = _conditionsByRegion();

    // Cap visible conditions across all regions to keep cards uniform.
    final sections = <Widget>[];
    var shown = 0;
    var hidden = 0;
    for (final entry in grouped.entries) {
      final visible =
          entry.value.take(_maxVisibleConditions - shown).toList();
      hidden += entry.value.length - visible.length;
      shown += visible.length;
      if (visible.isEmpty) continue;
      sections.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.p8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _regionPill(context, entry.key),
              ...visible.map((name) => _conditionBullet(context, name)),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p8,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSizes.r16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.r16),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: AppSizes.iconSmall,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSizes.p6),
                      Text(
                        Formatters.formatDateMedium(program.createdAt),
                        style: AppTextStyles.captionBold.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  ProgramStatusBadge(status: program.status),
                ],
              ),
              const SizedBox(height: AppSizes.p12),
              ...sections,
              if (hidden > 0)
                Text(
                  AppStrings.moreConditions(hidden),
                  style: AppTextStyles.caption.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
