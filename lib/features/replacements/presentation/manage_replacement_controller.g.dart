// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manage_replacement_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the singleton [ReplacementRepository] backed by Supabase.

@ProviderFor(replacementRepository)
final replacementRepositoryProvider = ReplacementRepositoryProvider._();

/// Provides the singleton [ReplacementRepository] backed by Supabase.

final class ReplacementRepositoryProvider
    extends
        $FunctionalProvider<
          ReplacementRepository,
          ReplacementRepository,
          ReplacementRepository
        >
    with $Provider<ReplacementRepository> {
  /// Provides the singleton [ReplacementRepository] backed by Supabase.
  ReplacementRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'replacementRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$replacementRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReplacementRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReplacementRepository create(Ref ref) {
    return replacementRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReplacementRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReplacementRepository>(value),
    );
  }
}

String _$replacementRepositoryHash() =>
    r'13ac324e6bab9391e13f2aab9650334ce9a19909';

/// Multi-step async notifier driving the replacement wizard.

@ProviderFor(ManageReplacementController)
final manageReplacementControllerProvider =
    ManageReplacementControllerProvider._();

/// Multi-step async notifier driving the replacement wizard.
final class ManageReplacementControllerProvider
    extends
        $AsyncNotifierProvider<
          ManageReplacementController,
          ManageReplacementState
        > {
  /// Multi-step async notifier driving the replacement wizard.
  ManageReplacementControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'manageReplacementControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$manageReplacementControllerHash();

  @$internal
  @override
  ManageReplacementController create() => ManageReplacementController();
}

String _$manageReplacementControllerHash() =>
    r'd292f702c7f31d42e9c72b5fac07ce82166e7d86';

/// Multi-step async notifier driving the replacement wizard.

abstract class _$ManageReplacementController
    extends $AsyncNotifier<ManageReplacementState> {
  FutureOr<ManageReplacementState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<ManageReplacementState>, ManageReplacementState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ManageReplacementState>,
                ManageReplacementState
              >,
              AsyncValue<ManageReplacementState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
