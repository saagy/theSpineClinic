import 'dart:typed_data';
import 'package:spine_clinic_app/core/errors/app_exception.dart';

enum DocumentUploadStatus { queued, uploading, done, failed }

class DocumentUploadItem {
  const DocumentUploadItem({
    required this.fileName,
    required this.bytes,
    this.status = DocumentUploadStatus.queued,
    this.error,
  });
  final String fileName;
  final Uint8List? bytes;
  final DocumentUploadStatus status;
  final AppException? error;
  bool get isUnconfirmed => error?.code == 'mutation/unconfirmed';

  DocumentUploadItem copyWith({
    DocumentUploadStatus? status,
    AppException? error,
    bool clearError = false,
    bool releaseBytes = false,
  }) => DocumentUploadItem(
    fileName: fileName,
    bytes: releaseBytes ? null : bytes,
    status: status ?? this.status,
    error: clearError ? null : error ?? this.error,
  );
}

class DocumentUploadState {
  const DocumentUploadState({this.files = const [], this.isLoading = false});
  final List<DocumentUploadItem> files;
  final bool isLoading;
  bool get hasFailures => files.any((f) => f.status == DocumentUploadStatus.failed);
  bool get canPick => !isLoading && !hasFailures;
  int get completed => files.where((f) => f.status == DocumentUploadStatus.done).length;
  DocumentUploadItem? get active =>
      files.where((f) => f.status == DocumentUploadStatus.uploading).firstOrNull;

  DocumentUploadState copyWith({List<DocumentUploadItem>? files, bool? isLoading}) =>
      DocumentUploadState(files: files ?? this.files, isLoading: isLoading ?? this.isLoading);
}
