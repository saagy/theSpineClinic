import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/file_opener_helper.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_document_actions.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_document_preview.dart';
import 'package:spine_clinic_app/shared/widgets/app_file_viewer.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

/// Touch-first card for opening and managing one patient document.
class PatientDocumentItem extends StatefulWidget {
  const PatientDocumentItem({super.key, required this.document});

  final PatientDocument document;

  @override
  State<PatientDocumentItem> createState() => _PatientDocumentItemState();
}

class _PatientDocumentItemState extends State<PatientDocumentItem> {
  bool _isOpening = false;

  Future<void> _open() async {
    if (_isOpening) return;
    setState(() => _isOpening = true);
    try {
      final String extension = p
          .extension(widget.document.fileName)
          .toLowerCase();
      final bool isPdf = extension == '.pdf';
      final bool isImage =
          extension == '.png' || extension == '.jpg' || extension == '.jpeg';
      if (isPdf || isImage) {
        showAppFileViewer(
          context,
          fileUrl: widget.document.fileUrl,
          fileName: widget.document.fileName,
          isImage: isImage,
          isPdf: isPdf,
        );
      } else {
        await FileOpenerHelper.openFile(
          widget.document.fileUrl,
          widget.document.fileName,
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          message: AppStrings.errorUnknown,
          variant: AppSnackbarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String date = widget.document.uploadedAt
        .toIso8601String()
        .split('T')
        .first;

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
        onTap: _isOpening ? null : _open,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PatientDocumentPreview(document: widget.document),
                  if (_isOpening)
                    ColoredBox(
                      color: colors.scrim.withAlpha(100),
                      child: Center(
                        child: SizedBox.square(
                          dimension: AppSizes.iconDefault,
                          child: CircularProgressIndicator(
                            strokeWidth: AppSizes.strokeWidthThin,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: AppSizes.p8,
                    right: AppSizes.p8,
                    child: PatientDocumentActions(document: widget.document),
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
                    widget.document.fileName,
                    style: AppTextStyles.captionMedium.copyWith(
                      color: colors.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.p4),
                  Text(
                    date,
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
