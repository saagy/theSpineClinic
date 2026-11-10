// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(billingRepository)
final billingRepositoryProvider = BillingRepositoryProvider._();

final class BillingRepositoryProvider
    extends
        $FunctionalProvider<
          BillingRepository,
          BillingRepository,
          BillingRepository
        >
    with $Provider<BillingRepository> {
  BillingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billingRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billingRepositoryHash();

  @$internal
  @override
  $ProviderElement<BillingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BillingRepository create(Ref ref) {
    return billingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BillingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BillingRepository>(value),
    );
  }
}

String _$billingRepositoryHash() => r'fdae2899a840d31d81b6cb989796ae84fa51d582';

@ProviderFor(billingRegister)
final billingRegisterProvider = BillingRegisterFamily._();

final class BillingRegisterProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BillingInvoice>>,
          List<BillingInvoice>,
          FutureOr<List<BillingInvoice>>
        >
    with
        $FutureModifier<List<BillingInvoice>>,
        $FutureProvider<List<BillingInvoice>> {
  BillingRegisterProvider._({
    required BillingRegisterFamily super.from,
    required (BillingFilter, int, int) super.argument,
  }) : super(
         retry: null,
         name: r'billingRegisterProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$billingRegisterHash();

  @override
  String toString() {
    return r'billingRegisterProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<BillingInvoice>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BillingInvoice>> create(Ref ref) {
    final argument = this.argument as (BillingFilter, int, int);
    return billingRegister(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is BillingRegisterProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$billingRegisterHash() => r'befb8bfdb5bd11df52cd4134207e5f4aa65c44ff';

final class BillingRegisterFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<BillingInvoice>>,
          (BillingFilter, int, int)
        > {
  BillingRegisterFamily._()
    : super(
        retry: null,
        name: r'billingRegisterProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BillingRegisterProvider call(BillingFilter filter, int offset, int limit) =>
      BillingRegisterProvider._(argument: (filter, offset, limit), from: this);

  @override
  String toString() => r'billingRegisterProvider';
}

@ProviderFor(billingInvoice)
final billingInvoiceProvider = BillingInvoiceFamily._();

final class BillingInvoiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<BillingInvoice>,
          BillingInvoice,
          FutureOr<BillingInvoice>
        >
    with $FutureModifier<BillingInvoice>, $FutureProvider<BillingInvoice> {
  BillingInvoiceProvider._({
    required BillingInvoiceFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'billingInvoiceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$billingInvoiceHash();

  @override
  String toString() {
    return r'billingInvoiceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<BillingInvoice> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BillingInvoice> create(Ref ref) {
    final argument = this.argument as String;
    return billingInvoice(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BillingInvoiceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$billingInvoiceHash() => r'd245b18e928446b29471da32f20b968d4b40db73';

final class BillingInvoiceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<BillingInvoice>, String> {
  BillingInvoiceFamily._()
    : super(
        retry: null,
        name: r'billingInvoiceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BillingInvoiceProvider call(String id) =>
      BillingInvoiceProvider._(argument: id, from: this);

  @override
  String toString() => r'billingInvoiceProvider';
}

@ProviderFor(billingCatalog)
final billingCatalogProvider = BillingCatalogFamily._();

final class BillingCatalogProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BillingItem>>,
          List<BillingItem>,
          FutureOr<List<BillingItem>>
        >
    with
        $FutureModifier<List<BillingItem>>,
        $FutureProvider<List<BillingItem>> {
  BillingCatalogProvider._({
    required BillingCatalogFamily super.from,
    required (String, bool, {int offset, int limit, String excluded})
    super.argument,
  }) : super(
         retry: null,
         name: r'billingCatalogProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$billingCatalogHash();

  @override
  String toString() {
    return r'billingCatalogProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<BillingItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BillingItem>> create(Ref ref) {
    final argument =
        this.argument
            as (String, bool, {int offset, int limit, String excluded});
    return billingCatalog(
      ref,
      argument.$1,
      argument.$2,
      offset: argument.offset,
      limit: argument.limit,
      excluded: argument.excluded,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BillingCatalogProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$billingCatalogHash() => r'f80fedbb963aa2e6bf0d9a020a3f61d91c82e353';

final class BillingCatalogFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<BillingItem>>,
          (String, bool, {int offset, int limit, String excluded})
        > {
  BillingCatalogFamily._()
    : super(
        retry: null,
        name: r'billingCatalogProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BillingCatalogProvider call(
    String query,
    bool activeOnly, {
    int offset = 0,
    int limit = 100,
    String excluded = '',
  }) => BillingCatalogProvider._(
    argument: (
      query,
      activeOnly,
      offset: offset,
      limit: limit,
      excluded: excluded,
    ),
    from: this,
  );

  @override
  String toString() => r'billingCatalogProvider';
}

@ProviderFor(billingLookup)
final billingLookupProvider = BillingLookupFamily._();

final class BillingLookupProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BillingParty>>,
          List<BillingParty>,
          FutureOr<List<BillingParty>>
        >
    with
        $FutureModifier<List<BillingParty>>,
        $FutureProvider<List<BillingParty>> {
  BillingLookupProvider._({
    required BillingLookupFamily super.from,
    required (BillingLookup, String, int, int) super.argument,
  }) : super(
         retry: null,
         name: r'billingLookupProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$billingLookupHash();

  @override
  String toString() {
    return r'billingLookupProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<BillingParty>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BillingParty>> create(Ref ref) {
    final argument = this.argument as (BillingLookup, String, int, int);
    return billingLookup(
      ref,
      argument.$1,
      argument.$2,
      argument.$3,
      argument.$4,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BillingLookupProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$billingLookupHash() => r'80273702a85f7be60e40960ba7ab7f6a307bd6da';

final class BillingLookupFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<BillingParty>>,
          (BillingLookup, String, int, int)
        > {
  BillingLookupFamily._()
    : super(
        retry: null,
        name: r'billingLookupProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BillingLookupProvider call(
    BillingLookup kind,
    String query,
    int offset,
    int limit,
  ) => BillingLookupProvider._(
    argument: (kind, query, offset, limit),
    from: this,
  );

  @override
  String toString() => r'billingLookupProvider';
}

@ProviderFor(BillingWriter)
final billingWriterProvider = BillingWriterProvider._();

final class BillingWriterProvider
    extends $NotifierProvider<BillingWriter, BillingWriteState> {
  BillingWriterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billingWriterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billingWriterHash();

  @$internal
  @override
  BillingWriter create() => BillingWriter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BillingWriteState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BillingWriteState>(value),
    );
  }
}

String _$billingWriterHash() => r'19ab20cee7a68291651e227a729ae0145d8610ea';

abstract class _$BillingWriter extends $Notifier<BillingWriteState> {
  BillingWriteState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<BillingWriteState, BillingWriteState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BillingWriteState, BillingWriteState>,
              BillingWriteState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
