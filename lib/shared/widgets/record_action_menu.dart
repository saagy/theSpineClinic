import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

class RecordMenuAction<T> {
  const RecordMenuAction(this.value, this.label, this.icon, {this.destructive = false, this.enabled = true});
  final T value;
  final String label;
  final IconData icon;
  final bool destructive;
  final bool enabled;
}

/// Same icon-led, bordered popup treatment as the schedule agenda.
class RecordActionMenu<T> extends StatelessWidget {
  const RecordActionMenu({
    super.key,
    required this.actions,
    required this.onSelected,
    this.tooltip = AppStrings.moreActions,
    this.enabled = true,
    this.child,
  });
  final List<RecordMenuAction<T>> actions;
  final ValueChanged<T> onSelected;
  final String tooltip;
  final bool enabled;
  final Widget? child;

  static RoundedRectangleBorder _shape(BuildContext context) => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppSizes.r12),
    side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
  );

  /// Opens a follow-up menu at the same record action button.
  static Future<V?> show<V>(BuildContext context, {required List<RecordMenuAction<V>> actions}) {
    final anchor = context.findRenderObject()! as RenderBox;
    final overlay = Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    RelativeRect position() => RelativeRect.fromRect(
      anchor.localToGlobal(Offset.zero, ancestor: overlay) & anchor.size,
      Offset.zero & overlay.size,
    );
    final fallback = position();
    return showMenu<V>(
      context: context,
      positionBuilder: (_, _) => anchor.attached && overlay.attached ? position() : fallback,
      color: Theme.of(context).colorScheme.surface,
      constraints: const BoxConstraints(minWidth: AppSizes.recordMenuWidth),
      shape: _shape(context),
      items: _items(context, actions),
    );
  }

  static List<PopupMenuEntry<V>> _items<V>(BuildContext context, List<RecordMenuAction<V>> actions) {
    final cs = Theme.of(context).colorScheme;
    return [
      for (final action in actions)
        PopupMenuItem<V>(
          value: action.value,
          enabled: action.enabled,
          height: AppSizes.tappableMin,
          child: Row(
            children: [
              Icon(action.icon, size: AppSizes.iconSmall, color: action.destructive ? cs.error : cs.onSurfaceVariant),
              const SizedBox(width: AppSizes.p12),
              Flexible(
                child: Text(
                  action.label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: action.destructive
                        ? cs.error
                        : action.enabled
                        ? cs.onSurface
                        : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<T>(
      tooltip: tooltip,
      enabled: enabled,
      onSelected: onSelected,
      icon: child == null ? const Icon(LucideIcons.ellipsis_vertical, size: AppSizes.iconSmall) : null,
      color: cs.surface,
      constraints: const BoxConstraints(minWidth: AppSizes.recordMenuWidth),
      shape: _shape(context),
      itemBuilder: (context) => _items(context, actions),
      child: child,
    );
  }
}
