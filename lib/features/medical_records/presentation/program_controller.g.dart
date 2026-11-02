// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Mutation controller managing program creation, updates, status changes, and deletion (Rule 28).

@ProviderFor(ProgramController)
final programControllerProvider = ProgramControllerProvider._();

/// Mutation controller managing program creation, updates, status changes, and deletion (Rule 28).
final class ProgramControllerProvider
    extends $NotifierProvider<ProgramController, ProgramMutationState> {
  /// Mutation controller managing program creation, updates, status changes, and deletion (Rule 28).
  ProgramControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'programControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$programControllerHash();

  @$internal
  @override
  ProgramController create() => ProgramController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProgramMutationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProgramMutationState>(value),
    );
  }
}

String _$programControllerHash() => r'ce857379d1ede4e7ccfc139ade1c792ed48acbed';

/// Mutation controller managing program creation, updates, status changes, and deletion (Rule 28).

abstract class _$ProgramController extends $Notifier<ProgramMutationState> {
  ProgramMutationState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ProgramMutationState, ProgramMutationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProgramMutationState, ProgramMutationState>,
              ProgramMutationState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
