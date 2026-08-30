/// One grid cell representing a program's attached documents.
///
/// Lives next to standalone document tiles in the documents tab and
/// triggers the shared gallery viewer for that program's docs when
/// tapped. Long-press and rename/delete actions are intentionally
/// not exposed here — program docs are managed from the program screen.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_document_groups.dart';

class ProgramDocumentFolderTile extends StatelessWidget {
  const ProgramDocumentFolderTile({
    super.key,
    required this.group,
    required this.onTap,
  });

  final ProgramDocumentGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final dateLabel = group.program == null
        ? AppStrings.program
        : '${AppStrings.program} · '
            '${Formatters.formatDateMedium(group.program!.createdAt)}';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppSizes.borderRadiusCard,
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withAlpha(64),
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.folder_rounded,
                      size: AppSizes.iconHero,
                      color: colors.primary,
                    ),
                  ),
                  Positioned(
                    top: AppSizes.p8,
                    right: AppSizes.p8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p8,
                        vertical: AppSizes.p2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppSizes.r999),
                      ),
                      child: Text(
                        AppStrings.scanCountLabel(group.count),
                        style: AppTextStyles.captionBold.copyWith(
                          color: colors.onPrimaryContainer,
                          fontSize: AppSizes.fontSizeXs,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dateLabel,
                    style: AppTextStyles.captionMedium.copyWith(
                      color: colors.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.p4),
                  Text(
                    AppStrings.scanCountLabel(group.count),
                    style: AppTextStyles.caption.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
