// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'condition_catalog_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a singleton instance of [ConditionCatalogRepository].

@ProviderFor(conditionCatalogRepository)
final conditionCatalogRepositoryProvider =
    ConditionCatalogRepositoryProvider._();

/// Provides a singleton instance of [ConditionCatalogRepository].

final class ConditionCatalogRepositoryProvider
    extends
        $FunctionalProvider<
          ConditionCatalogRepository,
          ConditionCatalogRepository,
          ConditionCatalogRepository
        >
    with $Provider<ConditionCatalogRepository> {
  /// Provides a singleton instance of [ConditionCatalogRepository].
  ConditionCatalogRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conditionCatalogRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conditionCatalogRepositoryHash();

  @$internal
  @override
  $ProviderElement<ConditionCatalogRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ConditionCatalogRepository create(Ref ref) {
    return conditionCatalogRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConditionCatalogRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConditionCatalogRepository>(value),
    );
  }
}

String _$conditionCatalogRepositoryHash() =>
    r'64b152a85713fcbcaf78dd0a7038fd5093eb6822';

/// Provides all condition catalog entries cached application-wide.

@ProviderFor(conditionCatalog)
final conditionCatalogProvider = ConditionCatalogProvider._();

/// Provides all condition catalog entries cached application-wide.

final class ConditionCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ConditionCatalog>>,
          List<ConditionCatalog>,
          FutureOr<List<ConditionCatalog>>
        >
    with
        $FutureModifier<List<ConditionCatalog>>,
        $FutureProvider<List<ConditionCatalog>> {
  /// Provides all condition catalog entries cached application-wide.
  ConditionCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conditionCatalogProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conditionCatalogHash();

  @$internal
  @override
  $FutureProviderElement<List<ConditionCatalog>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ConditionCatalog>> create(Ref ref) {
    return conditionCatalog(ref);
  }
}

String _$conditionCatalogHash() => r'62619a03385f0710b44d8c20f8914de6416d0f2d';

/// Provides condition catalog entries filtered for a specific [region].

@ProviderFor(conditionsByRegion)
final conditionsByRegionProvider = ConditionsByRegionFamily._();

/// Provides condition catalog entries filtered for a specific [region].

final class ConditionsByRegionProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ConditionCatalog>>,
          List<ConditionCatalog>,
          FutureOr<List<ConditionCatalog>>
        >
    with
        $FutureModifier<List<ConditionCatalog>>,
        $FutureProvider<List<ConditionCatalog>> {
  /// Provides condition catalog entries filtered for a specific [region].
  ConditionsByRegionProvider._({
    required ConditionsByRegionFamily super.from,
    required BodyRegion super.argument,
  }) : super(
         retry: null,
         name: r'conditionsByRegionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conditionsByRegionHash();

  @override
  String toString() {
    return r'conditionsByRegionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ConditionCatalog>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ConditionCatalog>> create(Ref ref) {
    final argument = this.argument as BodyRegion;
    return conditionsByRegion(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ConditionsByRegionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conditionsByRegionHash() =>
    r'614d213c854a3eaa41d2f283b50999f93785307b';

/// Provides condition catalog entries filtered for a specific [region].

final class ConditionsByRegionFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<ConditionCatalog>>,
          BodyRegion
        > {
  ConditionsByRegionFamily._()
    : super(
        retry: null,
        name: r'conditionsByRegionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides condition catalog entries filtered for a specific [region].

  ConditionsByRegionProvider call(BodyRegion region) =>
      ConditionsByRegionProvider._(argument: region, from: this);

  @override
  String toString() => r'conditionsByRegionProvider';
}
