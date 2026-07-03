/// Digital receipt-style booking ledger with right-aligned values
/// and thin dividers between calculation blocks.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

class BookingSlotsPreview extends StatelessWidget {
  const BookingSlotsPreview({
    super.key,
    required this.slots,
    required this.timeOfDay,
    required this.usePackage,
  });

  final List<DateTime> slots;
  final TimeOfDay? timeOfDay;
  final bool usePackage;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) return const SizedBox.shrink();
    final int count = slots.length;
    final String timeStr = timeOfDay != null
        ? '${timeOfDay!.hour.toString().padLeft(2, '0')}:${timeOfDay!.minute.toString().padLeft(2, '0')}'
        : '—';
    final int pkg = usePackage ? count : 0;

    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: AppSizes.borderWidth),
        boxShadow: [ClinicColors.of(context).cardShadow],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Header
        Text('Session Ledger',
            style: AppTextStyles.captionBold.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 0.5)),
        const SizedBox(height: AppSizes.p12),
        // Per-session rows
        ...slots.asMap().entries.map((e) {
          final d = e.value;
          final m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
            child: Row(children: [
              Text('${e.key + 1}. ${m[d.month - 1]} ${d.day}',
                  style: AppTextStyles.body.copyWith(color: Theme.of(context).colorScheme.onSurface)),
              const Spacer(),
              Text(timeStr,
                  style: AppTextStyles.body.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ]),
          );
        }),
        const _ThinDivider(),
        // Totals block
        _Row(label: 'Total sessions', value: count.toString()),
        const SizedBox(height: AppSizes.p4),
        _Row(label: 'Using package', value: pkg.toString()),
        const SizedBox(height: AppSizes.p4),
        _Row(label: 'Out-of-pocket', value: (count - pkg).toString()),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label, style: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const Spacer(),
      Text(value, style: AppTextStyles.number.copyWith(color: Theme.of(context).colorScheme.onSurface)),
    ]);
  }
}

class _ThinDivider extends StatelessWidget {
  const _ThinDivider();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
      child: Divider(height: 1, thickness: 0.5, color: Theme.of(context).colorScheme.outline),
    );
  }
}
