library;

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/file_display_helper.dart';

/// Thumbnail card for form pickers with live image previews and remove buttons.
class ProgramPickerCard extends StatelessWidget {
  const ProgramPickerCard({
    super.key,
    required this.fileName,
    this.imageBytes,
    this.previewWidget,
    required this.onDelete,
  });

  final String fileName;
  final Uint8List? imageBytes;
  final Widget? previewWidget;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPdf = FileDisplayHelper.isPdf(fileName);
    final cleanName = FileDisplayHelper.sanitizeFileName(fileName);
    final extBadge = FileDisplayHelper.getExtensionBadge(fileName);

    return Container(
      width: AppSizes.mediaPickerCardWidth,
      height: AppSizes.mediaPickerCardHeight,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.r12),
        border: Border.all(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (isPdf)
                  ColoredBox(
                    color: cs.errorContainer.withAlpha(80),
                    child: Center(
                      child: Icon(
                        Icons.picture_as_pdf_rounded,
                        color: cs.error,
                        size: AppSizes.iconLarge,
                      ),
                    ),
                  )
                else if (imageBytes != null)
                  Image.memory(
                    imageBytes!,
                    fit: BoxFit.cover,
                    cacheWidth: AppSizes.mediaPickerDecodeWidth,
                    gaplessPlayback: true,
                  )
                else if (previewWidget != null)
                  previewWidget!
                else
                  ColoredBox(
                    color: cs.surfaceContainerHighest,
                    child: Icon(Icons.image_outlined, color: cs.primary, size: AppSizes.iconLarge),
                  ),
                Positioned(
                  top: AppSizes.p4,
                  right: AppSizes.p4,
                  child: IconButton(
                    tooltip: AppStrings.removeAttachment,
                    onPressed: onDelete,
                    style: IconButton.styleFrom(
                      minimumSize: const Size.square(AppSizes.tappableMin),
                      backgroundColor: cs.surface.withAlpha(220),
                      foregroundColor: cs.error,
                    ),
                    icon: const Icon(Icons.close_rounded, size: AppSizes.iconSmall),
                  ),
                ),
                Positioned(
                  bottom: AppSizes.p4,
                  left: AppSizes.p4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p4,
                      vertical: AppSizes.p2,
                    ),
                    decoration: BoxDecoration(
                      color: isPdf
                          ? cs.error.withAlpha(200)
                          : cs.surfaceContainerHighest.withAlpha(200),
                      borderRadius: BorderRadius.circular(AppSizes.r4),
                    ),
                    child: Text(
                      extBadge,
                      style: AppTextStyles.captionBold.copyWith(
                        fontSize: AppSizes.fontSizeXs,
                        color: isPdf ? cs.onError : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p6, vertical: AppSizes.p4),
            child: Text(
              cleanName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.captionMedium.copyWith(color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
