// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Mutation controller for creating, updating, and deleting rehabilitation programs.

@ProviderFor(ProgramController)
final programControllerProvider = ProgramControllerProvider._();

/// Mutation controller for creating, updating, and deleting rehabilitation programs.
final class ProgramControllerProvider
    extends $NotifierProvider<ProgramController, AsyncValue<void>> {
  /// Mutation controller for creating, updating, and deleting rehabilitation programs.
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
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$programControllerHash() => r'f660809c67e69db9985a77071928d8cc980e1cac';

/// Mutation controller for creating, updating, and deleting rehabilitation programs.

abstract class _$ProgramController extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
