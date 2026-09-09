// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_document_bytes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Private R2/Supabase keys are resolved by the repository, never Image.network.

@ProviderFor(patientDocumentBytes)
final patientDocumentBytesProvider = PatientDocumentBytesFamily._();

/// Private R2/Supabase keys are resolved by the repository, never Image.network.

final class PatientDocumentBytesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Uint8List>,
          Uint8List,
          FutureOr<Uint8List>
        >
    with $FutureModifier<Uint8List>, $FutureProvider<Uint8List> {
  /// Private R2/Supabase keys are resolved by the repository, never Image.network.
  PatientDocumentBytesProvider._({
    required PatientDocumentBytesFamily super.from,
    required PatientDocument super.argument,
  }) : super(
         retry: null,
         name: r'patientDocumentBytesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$patientDocumentBytesHash();

  @override
  String toString() {
    return r'patientDocumentBytesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Uint8List> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Uint8List> create(Ref ref) {
    final argument = this.argument as PatientDocument;
    return patientDocumentBytes(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PatientDocumentBytesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$patientDocumentBytesHash() =>
    r'f7f251584fa6856506ef91e2c8d985af57f69099';

/// Private R2/Supabase keys are resolved by the repository, never Image.network.

final class PatientDocumentBytesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Uint8List>, PatientDocument> {
  PatientDocumentBytesFamily._()
    : super(
        retry: null,
        name: r'patientDocumentBytesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Private R2/Supabase keys are resolved by the repository, never Image.network.

  PatientDocumentBytesProvider call(PatientDocument document) =>
      PatientDocumentBytesProvider._(argument: document, from: this);

  @override
  String toString() => r'patientDocumentBytesProvider';
}
