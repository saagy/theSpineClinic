import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/record_action_menu.dart';

/// A selection control with the same popup as the app's record actions.
class RecordMenuSelect<T> extends StatelessWidget {
  const RecordMenuSelect({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.isField = false,
  });

  final String label;
  final T value;
  final List<RecordMenuAction<T>> options;
  final ValueChanged<T>? onChanged;
  final bool isField;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selection = options
        .where((option) => option.value == value)
        .firstOrNull;
    final enabled = onChanged != null && options.isNotEmpty;
    final foreground = enabled ? colors.onSurface : colors.onSurfaceVariant;
    final caption = Row(
      mainAxisSize: isField ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Flexible(
          fit: isField ? FlexFit.tight : FlexFit.loose,
          child: Text(
            selection?.label ?? label,
            style: AppTextStyles.bodyMedium.copyWith(color: foreground),
          ),
        ),
        const SizedBox(width: AppSizes.p8),
        Icon(
          Icons.expand_more,
          color: colors.onSurfaceVariant,
          size: AppSizes.iconSmall,
        ),
      ],
    );
    return RecordActionMenu<int>(
      tooltip: label,
      enabled: enabled,
      position: PopupMenuPosition.under,
      onSelected: (index) => onChanged?.call(options[index].value),
      actions: [
        for (final (index, option) in options.indexed)
          RecordMenuAction(
            index,
            option.label,
            option.icon,
            enabled: option.enabled,
            selected: option.value == value,
          ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.tappableMin),
        child: isField
            ? InputDecorator(
                decoration: InputDecoration(labelText: label, enabled: enabled),
                isEmpty: selection == null,
                child: selection == null
                    ? Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Icon(
                          Icons.expand_more,
                          color: colors.onSurfaceVariant,
                          size: AppSizes.iconSmall,
                        ),
                      )
                    : caption,
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: colors.outlineVariant),
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.p12,
                    vertical: AppSizes.p12,
                  ),
                  child: caption,
                ),
              ),
      ),
    );
  }
}
