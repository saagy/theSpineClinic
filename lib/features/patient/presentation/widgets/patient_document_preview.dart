import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/utils/file_display_helper.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_document_bytes_provider.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

class PatientDocumentPreview extends ConsumerWidget {
  const PatientDocumentPreview({super.key, required this.document});
  final PatientDocument document;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    if (!FileDisplayHelper.isImage(document.fileName)) {
      return ColoredBox(
        color: cs.surfaceContainerHighest,
        child: Icon(Icons.picture_as_pdf_outlined, color: cs.primary, size: AppSizes.iconLarge),
      );
    }
    final provider = patientDocumentBytesProvider(document);
    return ref
        .watch(provider)
        .when(
          loading: () => const SkeletonBox(height: double.infinity),
          error: (_, _) => ColoredBox(
            color: cs.surfaceContainerHighest,
            child: IconButton(
              tooltip: AppStrings.retry,
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(provider),
            ),
          ),
          data: (bytes) => Image.memory(
            bytes,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => Icon(Icons.broken_image_outlined, color: cs.onSurfaceVariant),
          ),
        );
  }
}
