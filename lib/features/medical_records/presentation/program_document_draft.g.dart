// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program_document_draft.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One draft per mounted form; removal never changes the shared document list.

@ProviderFor(ProgramDocumentDraft)
final programDocumentDraftProvider = ProgramDocumentDraftFamily._();

/// One draft per mounted form; removal never changes the shared document list.
final class ProgramDocumentDraftProvider
    extends $NotifierProvider<ProgramDocumentDraft, ProgramDocumentDraftState> {
  /// One draft per mounted form; removal never changes the shared document list.
  ProgramDocumentDraftProvider._({
    required ProgramDocumentDraftFamily super.from,
    required Object super.argument,
  }) : super(
         retry: null,
         name: r'programDocumentDraftProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$programDocumentDraftHash();

  @override
  String toString() {
    return r'programDocumentDraftProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProgramDocumentDraft create() => ProgramDocumentDraft();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProgramDocumentDraftState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProgramDocumentDraftState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProgramDocumentDraftProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$programDocumentDraftHash() =>
    r'b618ae208aacfa0aef5da838e6468a070e80f7a9';

/// One draft per mounted form; removal never changes the shared document list.

final class ProgramDocumentDraftFamily extends $Family
    with
        $ClassFamilyOverride<
          ProgramDocumentDraft,
          ProgramDocumentDraftState,
          ProgramDocumentDraftState,
          ProgramDocumentDraftState,
          Object
        > {
  ProgramDocumentDraftFamily._()
    : super(
        retry: null,
        name: r'programDocumentDraftProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// One draft per mounted form; removal never changes the shared document list.

  ProgramDocumentDraftProvider call(Object formIdentity) =>
      ProgramDocumentDraftProvider._(argument: formIdentity, from: this);

  @override
  String toString() => r'programDocumentDraftProvider';
}

/// One draft per mounted form; removal never changes the shared document list.

abstract class _$ProgramDocumentDraft
    extends $Notifier<ProgramDocumentDraftState> {
  late final _$args = ref.$arg as Object;
  Object get formIdentity => _$args;

  ProgramDocumentDraftState build(Object formIdentity);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<ProgramDocumentDraftState, ProgramDocumentDraftState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProgramDocumentDraftState, ProgramDocumentDraftState>,
              ProgramDocumentDraftState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
