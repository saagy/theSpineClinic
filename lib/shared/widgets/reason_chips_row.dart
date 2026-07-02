import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Responsive rounded reason picker used by payment flows.
class ReasonChipsRow extends StatelessWidget {
  const ReasonChipsRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns = _columnsForWidth(constraints.maxWidth);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: options.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSizes.p8,
            mainAxisSpacing: AppSizes.p8,
            mainAxisExtent: 40.0, // Compact height
          ),
          itemBuilder: (context, index) {
            final String label = options[index];
            return _ReasonCard(
              label: label,
              selected: selected == label,
              enabled: enabled,
              onTap: () => onChanged(label),
            );
          },
        );
      },
    );
  }

  int _columnsForWidth(double width) {
    if (width >= 600) return 4;
    return 2; // Always at least 2 columns on mobile/portrait
  }
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color fill = selected ? cs.primaryContainer : cs.surface;
    final Color border = selected ? cs.primary : cs.outlineVariant;
    final Color text = selected ? cs.onPrimaryContainer : cs.onSurface;

    return Material(
      color: fill,
      borderRadius: AppSizes.borderRadiusCard,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: AppSizes.borderRadiusCard,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p12,
            vertical: AppSizes.p4,
          ),
          decoration: BoxDecoration(
            borderRadius: AppSizes.borderRadiusCard,
            border: Border.all(
              color: enabled ? border : cs.outlineVariant,
              width: selected
                  ? AppSizes.borderWidthFocused
                  : AppSizes.borderWidth,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: enabled ? text : cs.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: AppSizes.p4),
                Icon(
                  Icons.check_circle_rounded,
                  color: cs.primary,
                  size: AppSizes.iconSmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
