// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'treatment_plan_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a singleton instance of [TreatmentPlanRepository].

@ProviderFor(treatmentPlanRepository)
final treatmentPlanRepositoryProvider = TreatmentPlanRepositoryProvider._();

/// Provides a singleton instance of [TreatmentPlanRepository].

final class TreatmentPlanRepositoryProvider
    extends
        $FunctionalProvider<
          TreatmentPlanRepository,
          TreatmentPlanRepository,
          TreatmentPlanRepository
        >
    with $Provider<TreatmentPlanRepository> {
  /// Provides a singleton instance of [TreatmentPlanRepository].
  TreatmentPlanRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'treatmentPlanRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$treatmentPlanRepositoryHash();

  @$internal
  @override
  $ProviderElement<TreatmentPlanRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TreatmentPlanRepository create(Ref ref) {
    return treatmentPlanRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TreatmentPlanRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TreatmentPlanRepository>(value),
    );
  }
}

String _$treatmentPlanRepositoryHash() =>
    r'5ad7a9e34f5340ebbd86be8c034eaf369b8cd942';

/// Mutation controller managing treatment plan creation, updates, and deletion.
///
/// Rule 28 — declared with `keepAlive: true` to prevent premature disposal during in-flight requests.

@ProviderFor(TreatmentPlanController)
final treatmentPlanControllerProvider = TreatmentPlanControllerProvider._();

/// Mutation controller managing treatment plan creation, updates, and deletion.
///
/// Rule 28 — declared with `keepAlive: true` to prevent premature disposal during in-flight requests.
final class TreatmentPlanControllerProvider
    extends $NotifierProvider<TreatmentPlanController, AsyncValue<void>> {
  /// Mutation controller managing treatment plan creation, updates, and deletion.
  ///
  /// Rule 28 — declared with `keepAlive: true` to prevent premature disposal during in-flight requests.
  TreatmentPlanControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'treatmentPlanControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$treatmentPlanControllerHash();

  @$internal
  @override
  TreatmentPlanController create() => TreatmentPlanController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$treatmentPlanControllerHash() =>
    r'a883a3e30bfd53bcf472397570e63d91ed7db122';

/// Mutation controller managing treatment plan creation, updates, and deletion.
///
/// Rule 28 — declared with `keepAlive: true` to prevent premature disposal during in-flight requests.

abstract class _$TreatmentPlanController extends $Notifier<AsyncValue<void>> {
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
