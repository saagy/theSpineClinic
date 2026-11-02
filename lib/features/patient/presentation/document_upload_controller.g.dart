// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_upload_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Retains unfinished bytes within this signed-in session, including after navigation.

@ProviderFor(DocumentUploadController)
final documentUploadControllerProvider = DocumentUploadControllerFamily._();

/// Retains unfinished bytes within this signed-in session, including after navigation.
final class DocumentUploadControllerProvider
    extends $NotifierProvider<DocumentUploadController, DocumentUploadState> {
  /// Retains unfinished bytes within this signed-in session, including after navigation.
  DocumentUploadControllerProvider._({
    required DocumentUploadControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'documentUploadControllerProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$documentUploadControllerHash();

  @override
  String toString() {
    return r'documentUploadControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DocumentUploadController create() => DocumentUploadController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DocumentUploadState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DocumentUploadState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DocumentUploadControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$documentUploadControllerHash() =>
    r'1824e31bcf3d2960120360df77f3a733f10abe94';

/// Retains unfinished bytes within this signed-in session, including after navigation.

final class DocumentUploadControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          DocumentUploadController,
          DocumentUploadState,
          DocumentUploadState,
          DocumentUploadState,
          String
        > {
  DocumentUploadControllerFamily._()
    : super(
        retry: null,
        name: r'documentUploadControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Retains unfinished bytes within this signed-in session, including after navigation.

  DocumentUploadControllerProvider call(String patientId) =>
      DocumentUploadControllerProvider._(argument: patientId, from: this);

  @override
  String toString() => r'documentUploadControllerProvider';
}

/// Retains unfinished bytes within this signed-in session, including after navigation.

abstract class _$DocumentUploadController
    extends $Notifier<DocumentUploadState> {
  late final _$args = ref.$arg as String;
  String get patientId => _$args;

  DocumentUploadState build(String patientId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DocumentUploadState, DocumentUploadState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DocumentUploadState, DocumentUploadState>,
              DocumentUploadState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
