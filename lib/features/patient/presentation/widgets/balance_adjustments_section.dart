import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/patient/domain/balance_adjustment.dart';
import 'package:spine_clinic_app/features/patient/presentation/balance_adjustment_providers.dart';

const _t = AppStrings.balances;

/// The record of hand corrections to a patient's session balances, newest
/// first. Shows nothing while loading or when there are none.
class BalanceAdjustmentsSection extends ConsumerWidget {
  const BalanceAdjustmentsSection({super.key, required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextStyle muted = AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant);
    final value = ref.watch(balanceAdjustmentsProvider(patientId));
    final List<BalanceAdjustment>? list = value.value;
    if (value.hasError && list == null) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSizes.p20),
        child: Text(_t.historyError, style: muted),
      );
    }
    if (list == null || list.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_t.history, style: AppTextStyles.bodyBold.copyWith(color: colors.onSurface)),
          const SizedBox(height: AppSizes.p8),
          Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(AppSizes.r12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, item) in list.indexed) ...[
                  if (index > 0)
                    Divider(
                      height: AppSizes.borderWidth,
                      thickness: AppSizes.borderWidth,
                      color: colors.outlineVariant,
                    ),
                  Padding(
                    padding: AppSizes.paddingCell,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            if (item.changesPt) _t.change(_t.ptSessions, item.ptBefore, item.ptAfter),
                            if (item.changesTraction)
                              _t.change(_t.tractionSessions, item.tractionBefore, item.tractionAfter),
                          ].join(' · '),
                          style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurface),
                        ),
                        Text(item.reason, style: AppTextStyles.body.copyWith(color: colors.onSurface)),
                        Text(
                          _t.by(item.adjustedByName, Formatters.formatDateTime(item.adjustedAt)),
                          style: muted,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
