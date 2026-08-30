// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_document_groups.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Resolves patient documents into [ProgramDocumentGroup]s.
///
/// Folders are ordered by program `createdAt` descending. Standalone
/// documents (no `programId`) are returned separately so the caller can
/// render them as ordinary doc tiles.

@ProviderFor(patientDocumentGroups)
final patientDocumentGroupsProvider = PatientDocumentGroupsFamily._();

/// Resolves patient documents into [ProgramDocumentGroup]s.
///
/// Folders are ordered by program `createdAt` descending. Standalone
/// documents (no `programId`) are returned separately so the caller can
/// render them as ordinary doc tiles.

final class PatientDocumentGroupsProvider
    extends
        $FunctionalProvider<
          AsyncValue<DocumentGroups>,
          DocumentGroups,
          FutureOr<DocumentGroups>
        >
    with $FutureModifier<DocumentGroups>, $FutureProvider<DocumentGroups> {
  /// Resolves patient documents into [ProgramDocumentGroup]s.
  ///
  /// Folders are ordered by program `createdAt` descending. Standalone
  /// documents (no `programId`) are returned separately so the caller can
  /// render them as ordinary doc tiles.
  PatientDocumentGroupsProvider._({
    required PatientDocumentGroupsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'patientDocumentGroupsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$patientDocumentGroupsHash();

  @override
  String toString() {
    return r'patientDocumentGroupsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DocumentGroups> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DocumentGroups> create(Ref ref) {
    final argument = this.argument as String;
    return patientDocumentGroups(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PatientDocumentGroupsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$patientDocumentGroupsHash() =>
    r'90cd5ec4adb2f8af6740be8f951b4378804c2aad';

/// Resolves patient documents into [ProgramDocumentGroup]s.
///
/// Folders are ordered by program `createdAt` descending. Standalone
/// documents (no `programId`) are returned separately so the caller can
/// render them as ordinary doc tiles.

final class PatientDocumentGroupsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DocumentGroups>, String> {
  PatientDocumentGroupsFamily._()
    : super(
        retry: null,
        name: r'patientDocumentGroupsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Resolves patient documents into [ProgramDocumentGroup]s.
  ///
  /// Folders are ordered by program `createdAt` descending. Standalone
  /// documents (no `programId`) are returned separately so the caller can
  /// render them as ordinary doc tiles.

  PatientDocumentGroupsProvider call(String patientId) =>
      PatientDocumentGroupsProvider._(argument: patientId, from: this);

  @override
  String toString() => r'patientDocumentGroupsProvider';
}
