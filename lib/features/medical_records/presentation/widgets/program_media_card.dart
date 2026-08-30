library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/file_display_helper.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_document_preview.dart';

/// Compact visual card representing a single image or PDF attachment.
class ProgramMediaCard extends StatelessWidget {
  const ProgramMediaCard({
    super.key,
    required this.document,
    this.onTap,
  });

  final PatientDocument document;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPdf = FileDisplayHelper.isPdf(document.fileName);
    final cleanName = FileDisplayHelper.sanitizeFileName(document.fileName);
    final extBadge = FileDisplayHelper.getExtensionBadge(document.fileName);

    return Container(
      width: 116,
      height: 136,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.r12),
        border: Border.all(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.r12),
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
                            size: 32,
                          ),
                        ),
                      )
                    else
                      PatientDocumentPreview(document: document),
                    Positioned(
                      top: AppSizes.p6,
                      right: AppSizes.p6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.p4,
                          vertical: AppSizes.p2,
                        ),
                        decoration: BoxDecoration(
                          color: isPdf
                              ? cs.error.withAlpha(220)
                              : cs.surfaceContainerHighest.withAlpha(220),
                          borderRadius: BorderRadius.circular(AppSizes.r4),
                        ),
                        child: Text(
                          extBadge,
                          style: AppTextStyles.captionBold.copyWith(
                            fontSize: AppSizes.fontSizeXs,
                            color: isPdf ? cs.onError : cs.onSurfaceVariant,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p8,
                  vertical: AppSizes.p6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cleanName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.captionMedium.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.p2),
                    Row(
                      children: [
                        Icon(
                          isPdf
                              ? Icons.description_outlined
                              : Icons.image_outlined,
                          size: 11,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSizes.p4),
                        Expanded(
                          child: Text(
                            isPdf ? 'PDF Doc' : 'Image Scan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
