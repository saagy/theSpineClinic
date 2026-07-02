/// Quick stats strip for the patient info tab.
library;

import 'package:flutter/material.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';

class PatientInfoStatsStrip extends StatelessWidget {
  const PatientInfoStatsStrip({
    super.key,
    required this.apptCount,
    required this.apptLoading,
    required this.lastVisitText,
    required this.amountDue,
    required this.paymentsLoading,
    required this.isDoctor,
    required this.onAppointmentsTap,
    required this.onPaymentsTap,
  });

  static const String _emptyValue = '-';

  final int apptCount;
  final bool apptLoading;
  final String lastVisitText;
  final double amountDue;
  final bool paymentsLoading;
  final bool isDoctor;
  final VoidCallback onAppointmentsTap;
  final VoidCallback? onPaymentsTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final List<_InfoStat> stats = <_InfoStat>[
      _InfoStat(
        value: apptLoading ? _emptyValue : '$apptCount',
        label: AppStrings.totalAppointments,
        onTap: onAppointmentsTap,
      ),
      _InfoStat(value: lastVisitText, label: AppStrings.lastVisit),
    ];
    if (!isDoctor) {
      stats.add(
        _InfoStat(
          value: paymentsLoading ? _emptyValue : amountDue.toCurrencyString(),
          label: AppStrings.amountDue,
          onTap: onPaymentsTap,
          isWarning: amountDue > 0,
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

class _InfoStat {
  const _InfoStat({
    required this.value,
    required this.label,
    this.onTap,
    this.isWarning = false,
  });

  final String value;
  final String label;
  final VoidCallback? onTap;
  final bool isWarning;
}

class _InfoStatItem extends StatelessWidget {
  const _InfoStatItem({required this.stat});

  final _InfoStat stat;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool isTappable = stat.onTap != null;
    final Widget content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.tappableMin),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              stat.value,
              style: AppTextStyles.numberLarge.copyWith(
                color: stat.isWarning ? cs.error : cs.onSurface,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: AppSizes.p4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  stat.label,
                  style: AppTextStyles.captionMedium.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isTappable) ...[
                const SizedBox(width: AppSizes.p2),
                Icon(
                  Icons.chevron_right_rounded,
                  size: AppSizes.iconSmall,
                  color: cs.primary,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (!isTappable) return content;
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
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
