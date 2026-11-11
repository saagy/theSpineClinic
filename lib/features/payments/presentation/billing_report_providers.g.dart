// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_report_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(billingReportRepository)
final billingReportRepositoryProvider = BillingReportRepositoryProvider._();

final class BillingReportRepositoryProvider
    extends
        $FunctionalProvider<
          BillingReportRepository,
          BillingReportRepository,
          BillingReportRepository
        >
    with $Provider<BillingReportRepository> {
  BillingReportRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billingReportRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billingReportRepositoryHash();

  @$internal
  @override
  $ProviderElement<BillingReportRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BillingReportRepository create(Ref ref) {
    return billingReportRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BillingReportRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BillingReportRepository>(value),
    );
  }
}

String _$billingReportRepositoryHash() =>
    r'555f8e7c2a583c6f12136ee62d0ff1a858c0b46c';

@ProviderFor(BillingReportFilterController)
final billingReportFilterControllerProvider =
    BillingReportFilterControllerProvider._();

final class BillingReportFilterControllerProvider
    extends
        $NotifierProvider<BillingReportFilterController, BillingReportFilter> {
  BillingReportFilterControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billingReportFilterControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billingReportFilterControllerHash();

  @$internal
  @override
  BillingReportFilterController create() => BillingReportFilterController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BillingReportFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BillingReportFilter>(value),
    );
  }
}

String _$billingReportFilterControllerHash() =>
    r'e6dd0955211e08f415b4e4a3cf943e8f02136bfa';

abstract class _$BillingReportFilterController
    extends $Notifier<BillingReportFilter> {
  BillingReportFilter build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<BillingReportFilter, BillingReportFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BillingReportFilter, BillingReportFilter>,
              BillingReportFilter,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// One report. The database checks the same permission on every request.

@ProviderFor(billingReport)
final billingReportProvider = BillingReportFamily._();

/// One report. The database checks the same permission on every request.

final class BillingReportProvider
    extends
        $FunctionalProvider<
          AsyncValue<BillingReportData>,
          BillingReportData,
          FutureOr<BillingReportData>
        >
    with
        $FutureModifier<BillingReportData>,
        $FutureProvider<BillingReportData> {
  /// One report. The database checks the same permission on every request.
  BillingReportProvider._({
    required BillingReportFamily super.from,
    required BillingReportQuery super.argument,
  }) : super(
         retry: _noRetry,
         name: r'billingReportProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$billingReportHash();

  @override
  String toString() {
    return r'billingReportProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<BillingReportData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BillingReportData> create(Ref ref) {
    final argument = this.argument as BillingReportQuery;
    return billingReport(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BillingReportProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$billingReportHash() => r'89071d4f8eb2ae91b7acf5977f273a899d0aee47';

/// One report. The database checks the same permission on every request.

final class BillingReportFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<BillingReportData>,
          BillingReportQuery
        > {
  BillingReportFamily._()
    : super(
        retry: _noRetry,
        name: r'billingReportProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One report. The database checks the same permission on every request.

  BillingReportProvider call(BillingReportQuery query) =>
      BillingReportProvider._(argument: query, from: this);

  @override
  String toString() => r'billingReportProvider';
}

/// The report laid out for the screen, CSV and print. Kept per request so
/// table paging survives rebuilds.

@ProviderFor(billingReportView)
final billingReportViewProvider = BillingReportViewFamily._();

/// The report laid out for the screen, CSV and print. Kept per request so
/// table paging survives rebuilds.

final class BillingReportViewProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReportView>,
          ReportView,
          FutureOr<ReportView>
        >
    with $FutureModifier<ReportView>, $FutureProvider<ReportView> {
  /// The report laid out for the screen, CSV and print. Kept per request so
  /// table paging survives rebuilds.
  BillingReportViewProvider._({
    required BillingReportViewFamily super.from,
    required BillingReportQuery super.argument,
  }) : super(
         retry: _noRetry,
         name: r'billingReportViewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$billingReportViewHash();

  @override
  String toString() {
    return r'billingReportViewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ReportView> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<ReportView> create(Ref ref) {
    final argument = this.argument as BillingReportQuery;
    return billingReportView(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BillingReportViewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$billingReportViewHash() => r'0b7519bd950dd1883cb9c290624adb32a7942a97';

/// The report laid out for the screen, CSV and print. Kept per request so
/// table paging survives rebuilds.

final class BillingReportViewFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ReportView>, BillingReportQuery> {
  BillingReportViewFamily._()
    : super(
        retry: _noRetry,
        name: r'billingReportViewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The report laid out for the screen, CSV and print. Kept per request so
  /// table paging survives rebuilds.

  BillingReportViewProvider call(BillingReportQuery query) =>
      BillingReportViewProvider._(argument: query, from: this);

  @override
  String toString() => r'billingReportViewProvider';
}
