import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Loads a document as in-memory bytes via the authenticated
/// [PatientDocumentsRepository] and exposes them to a [builder].
///
/// Owns the loading + error state machine so individual content viewers
/// (PDF, image, etc.) only render once bytes are available. Replaces the
/// earlier network-URL rendering paths (`Image.network`, `<iframe>` +
/// signed URL) which broke when the `patient-documents` Supabase bucket
/// is private and when mobile browsers stripped the iframe's zoom
/// toolbar.
///
/// Rule 26 — `mounted` guards every `setState` after the async gap.
/// Rule 7 / 25 — error messaging resolves through [AppException] →
/// `AppStrings.fromKey`, not inline literals.
class DocumentBytesLoader extends ConsumerStatefulWidget {
  const DocumentBytesLoader({
    required this.fileUrl,
    required this.fileName,
    required this.builder,
    super.key,
  });

  final String fileUrl;
  final String fileName;
  final Widget Function(BuildContext context, Uint8List bytes) builder;

  @override
  ConsumerState<DocumentBytesLoader> createState() =>
      _DocumentBytesLoaderState();
}

class _DocumentBytesLoaderState
    extends ConsumerState<DocumentBytesLoader> {
  Uint8List? _bytes;
  AppException? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(patientDocumentsRepositoryProvider);
    final Result<Uint8List> result = await repo.downloadDocumentBytes(
      fileUrl: widget.fileUrl,
      fileName: widget.fileName,
    );
    if (!mounted) return;
    result.when(
      success: (Uint8List bytes) => setState(() => _bytes = bytes),
      failure: (AppException exception) =>
          setState(() => _error = exception),
    );
  }

  Future<void> _retry() async {
    setState(() {
      _bytes = null;
      _error = null;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ErrorView(exception: _error!, onRetry: _retry);
    }
    if (_bytes == null) {
      final ColorScheme cs = Theme.of(context).colorScheme;
      return Center(
        child: CircularProgressIndicator(color: cs.primary),
      );
    }
    return widget.builder(context, _bytes!);
  }
}
