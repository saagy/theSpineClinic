/// Date range filter section for the appointment filter sheet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';

/// Renders quick date presets and custom date range picker tile.
class AppointmentFilterDateSection extends StatelessWidget {
  const AppointmentFilterDateSection({
    super.key,
    required this.dateFrom,
    required this.dateTo,
    required this.onDateRangeChanged,
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final void Function(DateTime? from, DateTime? to) onDateRangeChanged;

  bool _isThisMonth(DateTime? from, DateTime? to) {
    if (from == null || to == null) return false;
    final now = DateTime.now();
    final nextM = now.month == 12 ? 1 : now.month + 1;
    final nextY = now.month == 12 ? now.year + 1 : now.year;
    return from.year == now.year &&
        from.month == now.month &&
        from.day == 1 &&
        to.year == nextY &&
        to.month == nextM &&
        to.day == 1;
  }

  bool _isToday(DateTime? from, DateTime? to) {
    if (from == null || to == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return from == today && to == today.add(const Duration(days: 1));
  }

  String get _dateText {
    if (dateFrom != null && dateTo != null) {
      final end = dateTo!.subtract(const Duration(days: 1));
      return '${Formatters.formatDateShort(dateFrom!)} – ${Formatters.formatDateShort(end)}';
    }
    if (dateFrom != null) return 'From ${Formatters.formatDateShort(dateFrom!)}';
    if (dateTo != null) {
      return 'Until ${Formatters.formatDateShort(dateTo!.subtract(const Duration(days: 1)))}';
    }
    return AppStrings.customDateRange;
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final range = dateFrom != null && dateTo != null
        ? DateTimeRange(
            start: dateFrom!,
            end: dateTo!.subtract(const Duration(days: 1)),
          )
        : null;
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: range,
    );
    if (picked != null) {
      onDateRangeChanged(picked.start, picked.end.add(const Duration(days: 1)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final isMonth = _isThisMonth(dateFrom, dateTo);
    final isDay = _isToday(dateFrom, dateTo);
    final isAll = dateFrom == null && dateTo == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSizes.p8,
          runSpacing: AppSizes.p8,
          children: [
            _chip(cs, AppStrings.allDates, isAll, () => onDateRangeChanged(null, null)),
            _chip(cs, AppStrings.thisMonth, isMonth, () {
              final s = DateTime(now.year, now.month, 1);
              final e = DateTime(now.year, now.month + 1, 1);
              onDateRangeChanged(s, e);
            }),
            _chip(cs, AppStrings.today, isDay, () {
              final s = DateTime(now.year, now.month, now.day);
              onDateRangeChanged(s, s.add(const Duration(days: 1)));
            }),
          ],
        ),
        const SizedBox(height: AppSizes.p10),
        InkWell(
          onTap: () => _pickCustomRange(context),
          borderRadius: BorderRadius.circular(AppSizes.r8),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p14,
              vertical: AppSizes.p12,
            ),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withAlpha(100),
              borderRadius: BorderRadius.circular(AppSizes.r8),
              border: Border.all(
                color: cs.outlineVariant.withAlpha(120),
                width: AppSizes.borderWidth,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.calendar,
                      size: 16,
                      color: !isAll ? cs.primary : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSizes.p10),
                    Text(
                      _dateText,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: cs.onSurface,
                        fontWeight:
                            !isAll ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                Icon(
                  LucideIcons.chevron_right,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(ColorScheme cs, String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.r8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p12,
          vertical: AppSizes.p8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primaryContainer
              : cs.surfaceContainerHighest.withAlpha(120),
          borderRadius: BorderRadius.circular(AppSizes.r8),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant.withAlpha(100),
            width: AppSizes.borderWidth,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.captionBold.copyWith(
            color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
          ),
        ),
      ),
    );
  }
}
