/// Quick stats strip for the patient info tab.
library;

import 'package:flutter/material.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

class PatientInfoStatsStrip extends StatelessWidget {
  const PatientInfoStatsStrip({
    super.key,
    required this.apptCount,
    required this.apptLoading,
    required this.nextVisitText,
    required this.nextVisitSet,
    required this.nextVisitIsMutating,
    required this.nextVisitInPast,
    required this.amountDue,
    required this.paymentsLoading,
    required this.isDoctor,
    required this.onAppointmentsTap,
    required this.onNextVisitTap,
    required this.onPaymentsTap,
  });

  final int apptCount;
  final bool apptLoading;
  final String nextVisitText;
  final bool nextVisitSet;
  final bool nextVisitIsMutating;
  final bool nextVisitInPast;
  final double amountDue;
  final bool paymentsLoading;
  final bool isDoctor;
  final VoidCallback onAppointmentsTap;
  final VoidCallback onNextVisitTap;
  final VoidCallback? onPaymentsTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final List<_InfoStat> stats = <_InfoStat>[
      _InfoStat(
        value: '$apptCount',
        isLoading: apptLoading,
        label: AppStrings.totalAppointments,
        onTap: onAppointmentsTap,
        trailingIcon: _TrailingIcon.chevron,
      ),
      _InfoStat(
        value: nextVisitText,
        isLoading: nextVisitIsMutating,
        label: AppStrings.nextVisit,
        onTap: nextVisitIsMutating ? null : onNextVisitTap,
        trailingIcon: nextVisitSet
            ? _TrailingIcon.chevron
            : _TrailingIcon.edit,
        muted: !nextVisitSet,
        isWarning: nextVisitInPast,
      ),
    ];
    if (!isDoctor) {
      stats.add(
        _InfoStat(
          value: amountDue.toCurrencyString(),
          isLoading: paymentsLoading,
          label: AppStrings.amountDue,
          onTap: onPaymentsTap,
          isWarning: amountDue > 0,
          trailingIcon: _TrailingIcon.chevron,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p24,
        vertical: AppSizes.p16,
      ),
      child: Row(
        children: [
          for (int i = 0; i < stats.length; i++) ...[
            if (i > 0)
              Container(
                width: AppSizes.borderWidth,
                height: AppSizes.iconHero / 2,
                color: cs.outlineVariant,
                margin: const EdgeInsets.symmetric(horizontal: AppSizes.p8),
              ),
            Expanded(child: _InfoStatItem(stat: stats[i])),
          ],
        ],
      ),
    );
  }
}

enum _TrailingIcon { chevron, edit, none }

class _InfoStat {
  const _InfoStat({
    required this.value,
    required this.label,
    this.isLoading = false,
    this.onTap,
    this.isWarning = false,
    this.muted = false,
    this.trailingIcon = _TrailingIcon.none,
  });

  final String value;
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;
  final bool isWarning;
  final bool muted;
  final _TrailingIcon trailingIcon;
}

class _InfoStatItem extends StatelessWidget {
  const _InfoStatItem({required this.stat});

  final _InfoStat stat;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool isTappable = stat.onTap != null;
    final Color valueColor = stat.isWarning
        ? cs.error
        : (stat.muted ? cs.onSurfaceVariant : cs.onSurface);

    Widget valueRow;
    if (stat.isLoading) {
      valueRow = const KeyedSubtree(
        key: ValueKey('stat_loading'),
        child: SizedBox(
          height: 24,
          child: Center(
            child: SkeletonBox(width: 36, height: 16, borderRadius: 4),
          ),
        ),
      );
    } else if (stat.trailingIcon != _TrailingIcon.none) {
      final IconData iconData = stat.trailingIcon == _TrailingIcon.chevron
          ? Icons.chevron_right_rounded
          : Icons.edit_outlined;
      valueRow = Row(
        key: ValueKey('stat_data_${stat.value}'),
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              stat.value,
              style: AppTextStyles.numberLarge.copyWith(color: valueColor),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: AppSizes.p4),
          Icon(
            iconData,
            size: AppSizes.iconSmall,
            color: cs.onSurfaceVariant,
          ),
        ],
      );
    } else {
      valueRow = Text(
        stat.value,
        key: ValueKey('stat_data_${stat.value}'),
        style: AppTextStyles.numberLarge.copyWith(color: valueColor),
        maxLines: 1,
      );
    }

    final Widget content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.tappableMin),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: valueRow,
            ),
          ),
          const SizedBox(height: AppSizes.p4),
          Text(
            stat.label,
            style: AppTextStyles.captionMedium.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (!isTappable) return content;
    return Semantics(
      button: true,
      child: Material(
        color: cs.surface.withAlpha(0),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
          onTap: stat.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
            child: content,
          ),
        ),
      ),
    );
  }
}
