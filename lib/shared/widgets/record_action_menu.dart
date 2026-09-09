import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

class RecordMenuAction<T> {
  const RecordMenuAction(this.value, this.label, this.icon, {this.destructive = false});
  final T value;
  final String label;
  final IconData icon;
  final bool destructive;
}

/// Same icon-led, bordered popup treatment as the schedule agenda.
class RecordActionMenu<T> extends StatelessWidget {
  const RecordActionMenu({
    super.key,
    required this.actions,
    required this.onSelected,
    this.tooltip = AppStrings.moreActions,
    this.enabled = true,
  });
  final List<RecordMenuAction<T>> actions;
  final ValueChanged<T> onSelected;
  final String tooltip;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<T>(
      tooltip: tooltip,
      enabled: enabled,
      onSelected: onSelected,
      icon: const Icon(LucideIcons.ellipsis_vertical, size: AppSizes.iconSmall),
      color: cs.surface,
      constraints: const BoxConstraints(minWidth: AppSizes.recordMenuWidth),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.r12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      itemBuilder: (_) => [
        for (final action in actions)
          PopupMenuItem<T>(
            value: action.value,
            height: AppSizes.tappableMin,
            child: Row(
              children: [
                Icon(
                  action.icon,
                  size: AppSizes.iconSmall,
                  color: action.destructive ? cs.error : cs.onSurfaceVariant,
                ),
                const SizedBox(width: AppSizes.p12),
                Flexible(
                  child: Text(
                    action.label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: action.destructive ? cs.error : cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
