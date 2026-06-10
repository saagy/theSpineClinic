// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reports_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider managing active report query filters with 300ms debounce.

@ProviderFor(ReportsFilterState)
final reportsFilterStateProvider = ReportsFilterStateProvider._();

/// Provider managing active report query filters with 300ms debounce.
final class ReportsFilterStateProvider
    extends $NotifierProvider<ReportsFilterState, ReportsFilter> {
  /// Provider managing active report query filters with 300ms debounce.
  ReportsFilterStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportsFilterStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportsFilterStateHash();

  @$internal
  @override
  ReportsFilterState create() => ReportsFilterState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReportsFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReportsFilter>(value),
    );
  }
}

String _$reportsFilterStateHash() =>
    r'49d5a71069404c5d12412ba3d0e4ce0af5a5e7a1';

/// Provider managing active report query filters with 300ms debounce.

abstract class _$ReportsFilterState extends $Notifier<ReportsFilter> {
  ReportsFilter build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ReportsFilter, ReportsFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReportsFilter, ReportsFilter>,
              ReportsFilter,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Async provider fetching report analytics metrics from Supabase.
/// Depends on [reportsFilterStateProvider] to reactively query.

@ProviderFor(reportsData)
final reportsDataProvider = ReportsDataProvider._();

/// Async provider fetching report analytics metrics from Supabase.
/// Depends on [reportsFilterStateProvider] to reactively query.

final class ReportsDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReportData>,
          ReportData,
          FutureOr<ReportData>
        >
    with $FutureModifier<ReportData>, $FutureProvider<ReportData> {
  /// Async provider fetching report analytics metrics from Supabase.
  /// Depends on [reportsFilterStateProvider] to reactively query.
  ReportsDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportsDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportsDataHash();

  @$internal
  @override
  $FutureProviderElement<ReportData> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<ReportData> create(Ref ref) {
    return reportsData(ref);
  }
}

String _$reportsDataHash() => r'a023ef53c0f92d0d671540031631c7bbcfa1bc67';
