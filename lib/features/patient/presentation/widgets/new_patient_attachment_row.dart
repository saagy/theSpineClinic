part of 'new_patient_form.dart';

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({
    required this.file,
    required this.isImage,
    required this.status,
    required this.onRemove,
    required this.cs,
  });

  final PlatformFile file;
  final bool isImage;
  final AttachmentStatus status;
  final VoidCallback? onRemove;
  final ColorScheme cs;

  Widget _leading() {
    if (isImage && file.bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.r4),
        child: Image.memory(
          file.bytes!,
          width: AppSizes.p40,
          height: AppSizes.p40,
          fit: BoxFit.cover,
          cacheWidth: 96,
        ),
      );
    }
    return Icon(
      isImage ? Icons.image_rounded : Icons.picture_as_pdf_outlined,
      color: isImage ? cs.primary : cs.error,
      size: AppSizes.iconLarge,
    );
  }

  Widget _statusChip(BuildContext context) {
    final Color chipColor = switch (status) {
      AttachmentStatus.idle => ClinicColors.of(context).textMuted,
      AttachmentStatus.uploading => cs.primary,
      AttachmentStatus.done => ClinicColors.of(context).success,
      AttachmentStatus.failed => cs.error,
    };
    final String label = switch (status) {
      AttachmentStatus.idle => AppStrings.uploadReady,
      AttachmentStatus.uploading => AppStrings.uploading,
      AttachmentStatus.done => AppStrings.uploadDone,
      AttachmentStatus.failed => AppStrings.uploadFailed,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: AppSizes.p2),
      decoration: BoxDecoration(
        color: chipColor.withAlpha(30),
        borderRadius: BorderRadius.circular(AppSizes.r12),
      ),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: chipColor)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppSizes.r8),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: [
          _leading(),
          const SizedBox(width: AppSizes.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  file.name,
                  style: AppTextStyles.bodyBold.copyWith(color: cs.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${(file.size / 1024).toStringAsFixed(1)} KB',
                  style: AppTextStyles.caption.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.p8),
          _statusChip(context),
          if (onRemove != null) ...[
            const SizedBox(width: AppSizes.p4),
            IconButton(
              icon: Icon(Icons.close_rounded, color: cs.error, size: 20),
              onPressed: onRemove,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}
