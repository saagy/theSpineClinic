import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/record_filter_sheet.dart';

/// Standardized modern 2026 action bar for Patient Workspace tabs.
class WorkspaceTabHeader extends StatelessWidget {
  const WorkspaceTabHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.actionIcon = Icons.add,
    this.onAction,
    this.filterButton,
    this.trailing,
  });

  final String title;
  final String? actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;
  final Widget? filterButton;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 480;

        final effectiveFilterButton = filterButton is RecordFilterButton
            ? RecordFilterButton(
                onPressed: (filterButton as RecordFilterButton).onPressed,
                compact: isNarrow,
                activeFiltersCount: (filterButton as RecordFilterButton).activeFiltersCount,
              )
            : filterButton;

        final actionBtn = onAction != null && actionLabel != null
            ? (isNarrow
                ? IconButton.filled(
                    onPressed: onAction,
                    tooltip: actionLabel,
                    icon: Icon(actionIcon, size: AppSizes.iconSmall),
                    style: IconButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      minimumSize: const Size(AppSizes.tappableMin, AppSizes.buttonHeightSmall),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: onAction,
                    icon: Icon(actionIcon, size: AppSizes.iconSmall),
                    label: Text(actionLabel!, style: AppTextStyles.captionBold),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(AppSizes.tappableMin, AppSizes.buttonHeightSmall),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
                    ),
                  ))
            : null;

        final trWidget = trailing != null
            ? (isNarrow
                ? ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.45),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: trailing!,
                    ),
                  )
                : trailing!)
            : null;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.headingSmall.copyWith(color: cs.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (effectiveFilterButton != null || trWidget != null || actionBtn != null) ...[
              const SizedBox(width: AppSizes.p8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (effectiveFilterButton != null) effectiveFilterButton,
                  if (effectiveFilterButton != null && (trWidget != null || actionBtn != null))
                    const SizedBox(width: AppSizes.p8),
                  if (trWidget != null) trWidget,
                  if (trWidget != null && actionBtn != null)
                    const SizedBox(width: AppSizes.p8),
                  if (actionBtn != null) actionBtn,
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
