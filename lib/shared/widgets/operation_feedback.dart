import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'operation_progress_track.dart';

/// Inline status; estimated progress is reserved for document uploads.
class OperationFeedback extends StatelessWidget {
  const OperationFeedback({
    super.key,
    required this.message,
    this.detail,
    this.isBusy = true,
    this.showUploadProgress = false,
    this.isError = false,
    this.action,
  });

  final String message;
  final String? detail;
  final bool isBusy;
  final bool showUploadProgress;
  final bool isError;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: AppTextStyles.captionBold.copyWith(
              color: isError ? colors.error : colors.onSurface,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: AppSizes.p4),
            Text(detail!, style: AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant)),
          ],
          if (isBusy && showUploadProgress) ...[
            const SizedBox(height: AppSizes.p8),
            const OperationProgressTrack(),
          ],
          if (action != null) Align(alignment: AlignmentDirectional.centerEnd, child: action!),
        ],
      ),
    );
  }
}
