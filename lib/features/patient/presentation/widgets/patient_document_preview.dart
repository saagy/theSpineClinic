import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_documents_repository.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';

/// Cached image thumbnail or PDF placeholder for a document card.
class PatientDocumentPreview extends ConsumerStatefulWidget {
  const PatientDocumentPreview({super.key, required this.document});

  final PatientDocument document;

  @override
  ConsumerState<PatientDocumentPreview> createState() =>
      _PatientDocumentPreviewState();
}

class _PatientDocumentPreviewState
    extends ConsumerState<PatientDocumentPreview> {
  late final Future<Uint8List>? _imageBytes;

  @override
  void initState() {
    super.initState();
    final String extension = p
        .extension(widget.document.fileName)
        .toLowerCase();
    final bool isImage =
        extension == '.png' || extension == '.jpg' || extension == '.jpeg';
    _imageBytes = isImage ? _loadImage() : null;
  }

  Future<Uint8List> _loadImage() async {
    final PatientDocumentsRepository repository = ref.read(
      patientDocumentsRepositoryProvider,
    );
    final result = await repository.downloadDocumentBytes(
      fileUrl: widget.document.fileUrl,
      fileName: widget.document.fileName,
    );
    return result.when(
      success: (Uint8List bytes) => bytes,
      failure: (error) => throw error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    if (_imageBytes == null) {
      return ColoredBox(
        color: colors.surfaceContainerHighest,
        child: Icon(
          Icons.picture_as_pdf_outlined,
          color: colors.error,
          size: AppSizes.iconHero,
        ),
      );
    }
    return FutureBuilder<Uint8List>(
      future: _imageBytes,
      builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ColoredBox(
            color: colors.surfaceContainerHighest,
            child: const Center(
              child: SizedBox.square(
                dimension: AppSizes.iconDefault,
                child: CircularProgressIndicator(
                  strokeWidth: AppSizes.strokeWidthThin,
                ),
              ),
            ),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return ColoredBox(
            color: colors.errorContainer,
            child: Icon(
              Icons.broken_image_outlined,
              color: colors.error,
              size: AppSizes.iconLarge,
            ),
          );
        }
        return Image.memory(snapshot.data!, fit: BoxFit.cover);
      },
    );
  }
}
