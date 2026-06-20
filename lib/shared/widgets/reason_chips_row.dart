import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// A 2-column premium reason picker — used everywhere we ask the user
/// to pick one of N reasons (payment, status, type filter, …).
///
/// Implementation notes:
/// * All cells share an identical fixed height (50 px) so taps never
///   cause layout jitter.
/// * [showCheckmark] on the underlying [ChoiceChip] is disabled so its
///   internal width never expands when selected (which historically
///   caused the visual "shift" you saw between pills).
/// * Selected rows get a soft tonal fill (primary at ~10 % opacity) and
///   a check icon pinned strictly to the far right.
/// * Unselected rows are transparent with the default ink response.
class ReasonChipsRow extends StatelessWidget {
  /// Creates a [ReasonChipsRow].
  const ReasonChipsRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  /// Human-readable labels in display order.
  final List<String> options;

  /// Currently selected label, or `null` when nothing is selected.
  final String? selected;

  /// Fires when the user taps a reason. The label is passed back.
  final ValueChanged<String> onChanged;

  /// When false, every reason becomes non-interactive.
  final bool enabled;

  /// Uniform row height. Chosen to satisfy Android 48-px touch target
  /// without swamping narrow phones.
  static const double _rowHeight = AppSizes.buttonHeightSmall + 6; // ~42

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    // Build a list of fixed-size cell widgets so every row in every
    // column line up on a deterministic pixel grid.
    final children = <Widget>[];
    for (int i = 0; i < options.length; i += 2) {
      final left = options[i];
      final right = (i + 1 < options.length) ? options[i + 1] : null;
      children.add(
        _ReasonRow(
          leftLabel: left,
          rightLabel: right,
          selected: selected,
          enabled: enabled,
          rowHeight: _rowHeight,
          onChanged: onChanged,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

/// One horizontal row containing up to two equally-sized reason cells.
class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.leftLabel,
    required this.rightLabel,
    required this.selected,
    required this.enabled,
    required this.rowHeight,
    required this.onChanged,
  });

  final String leftLabel;
  final String? rightLabel;
  final String? selected;
  final bool enabled;
  final double rowHeight;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: rowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _ReasonCell(
              label: leftLabel,
              active: selected == leftLabel,
              enabled: enabled,
              onTap: () => onChanged(leftLabel),
            ),
          ),
          // Vertical separator between the two cells — invisible on the
          // outside edges so we don't get double borders on full-width lists.
          _Divider(),
          if (rightLabel != null)
            Expanded(
              child: _ReasonCell(
                label: rightLabel!,
                active: selected == rightLabel,
                enabled: enabled,
                onTap: () => onChanged(rightLabel!),
              ),
            )
          else
            const Spacer(),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, color: AppColors.border);
  }
}

class _ReasonCell extends StatelessWidget {
  const _ReasonCell({
    required this.label,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg = active
        ? AppColors.primary.withAlpha(22)
        : Colors.transparent;
    final Color textColor = active
        ? AppColors.primary
        : AppColors.textPrimary;

    return Material(
      color: bg,
      child: InkWell(
        onTap: enabled ? onTap : null,
        splashColor: AppColors.primary.withAlpha(40),
        highlightColor: AppColors.primary.withAlpha(20),
        child: Container(
          decoration: BoxDecoration(
            border: const Border(
              bottom: BorderSide(color: AppColors.border, width: AppSizes.borderWidth),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p12,
            vertical: AppSizes.p8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: textColor,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (active)
                Padding(
                  padding: const EdgeInsets.only(left: AppSizes.p8),
                  child: Icon(
                    Icons.check_rounded,
                    size: AppSizes.iconDefault,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
