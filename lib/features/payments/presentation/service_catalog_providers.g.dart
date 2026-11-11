// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_catalog_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(invoiceRepository)
final invoiceRepositoryProvider = InvoiceRepositoryProvider._();

final class InvoiceRepositoryProvider
    extends
        $FunctionalProvider<
          InvoiceRepository,
          InvoiceRepository,
          InvoiceRepository
        >
    with $Provider<InvoiceRepository> {
  InvoiceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'invoiceRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$invoiceRepositoryHash();

  @$internal
  @override
  $ProviderElement<InvoiceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InvoiceRepository create(Ref ref) {
    return invoiceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InvoiceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InvoiceRepository>(value),
    );
  }
}

String _$invoiceRepositoryHash() => r'dfefea0d4dd8868dd649f66757d15b826168aff9';

/// The full catalog. Small enough to load once and filter on the device.

@ProviderFor(serviceCatalog)
final serviceCatalogProvider = ServiceCatalogProvider._();

/// The full catalog. Small enough to load once and filter on the device.

final class ServiceCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ServiceCatalogItem>>,
          List<ServiceCatalogItem>,
          FutureOr<List<ServiceCatalogItem>>
        >
    with
        $FutureModifier<List<ServiceCatalogItem>>,
        $FutureProvider<List<ServiceCatalogItem>> {
  /// The full catalog. Small enough to load once and filter on the device.
  ServiceCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serviceCatalogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serviceCatalogHash();

  @$internal
  @override
  $FutureProviderElement<List<ServiceCatalogItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ServiceCatalogItem>> create(Ref ref) {
    return serviceCatalog(ref);
  }
}

String _$serviceCatalogHash() => r'f3b8fd083f192c71c4ea5b1b90e5247900db1fa3';

/// Saves catalog changes. Kept alive so a save finishing after the form
/// closes still refreshes the catalog.

@ProviderFor(ServiceCatalogController)
final serviceCatalogControllerProvider = ServiceCatalogControllerProvider._();

/// Saves catalog changes. Kept alive so a save finishing after the form
/// closes still refreshes the catalog.
final class ServiceCatalogControllerProvider
    extends $NotifierProvider<ServiceCatalogController, ServiceSaveState> {
  /// Saves catalog changes. Kept alive so a save finishing after the form
  /// closes still refreshes the catalog.
  ServiceCatalogControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serviceCatalogControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serviceCatalogControllerHash();

  @$internal
  @override
  ServiceCatalogController create() => ServiceCatalogController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ServiceSaveState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ServiceSaveState>(value),
    );
  }
}

String _$serviceCatalogControllerHash() =>
    r'6b6cb442254dc821c4a8996dee96ef096d4fed16';

/// Saves catalog changes. Kept alive so a save finishing after the form
/// closes still refreshes the catalog.

abstract class _$ServiceCatalogController extends $Notifier<ServiceSaveState> {
  ServiceSaveState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ServiceSaveState, ServiceSaveState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ServiceSaveState, ServiceSaveState>,
              ServiceSaveState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
