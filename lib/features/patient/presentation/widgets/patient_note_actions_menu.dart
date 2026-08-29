/// Context and overflow actions menu for patient notes.
///
/// Rule 1  — under 200 lines.
/// Rule 15/16 — colorScheme and AppTextStyles tokens.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Trailing / context menu for note actions (Edit / Delete).
class PatientNoteActionsMenu extends StatelessWidget {
  const PatientNoteActionsMenu({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static List<PopupMenuItem<String>> buildMenuItems(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return [
      PopupMenuItem<String>(
        value: 'edit',
        height: AppSizes.buttonHeightSmall,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit_outlined,
              color: cs.primary,
              size: AppSizes.iconSmall,
            ),
            const SizedBox(width: AppSizes.p8),
            Text(
              AppStrings.edit,
              style: AppTextStyles.bodyMedium.copyWith(
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'delete',
        height: AppSizes.buttonHeightSmall,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: cs.error,
              size: AppSizes.iconSmall,
            ),
            const SizedBox(width: AppSizes.p8),
            Text(
              AppStrings.delete,
              style: AppTextStyles.bodyMedium.copyWith(
                color: cs.error,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  /// Displays the context menu at [globalPosition] (touch-anchored).
  static Future<void> showContextMenu(
    BuildContext context,
    Offset globalPosition, {
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(globalPosition, globalPosition),
      overlay.localToGlobal(Offset.zero) & overlay.size,
    );

    final String? selected = await showMenu<String>(
      context: context,
      position: position,
      color: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r12)),
      ),
      elevation: 2,
      items: buildMenuItems(context),
    );

    if (selected == null || !context.mounted) return;
    if (selected == 'edit') {
      onEdit();
    } else if (selected == 'delete') {
      onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz_rounded,
        color: cs.onSurfaceVariant,
        size: AppSizes.iconDefault,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      splashRadius: AppSizes.iconDefault,
      color: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r12)),
      ),
      elevation: 2,
      position: PopupMenuPosition.under,
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (context) => buildMenuItems(context),
    );
  }
}
