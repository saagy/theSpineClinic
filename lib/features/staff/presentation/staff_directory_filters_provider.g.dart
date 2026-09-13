// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_directory_filters_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(StaffDirectoryFilters)
final staffDirectoryFiltersProvider = StaffDirectoryFiltersProvider._();

final class StaffDirectoryFiltersProvider
    extends
        $NotifierProvider<StaffDirectoryFilters, StaffDirectoryFilterState> {
  StaffDirectoryFiltersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'staffDirectoryFiltersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$staffDirectoryFiltersHash();

  @$internal
  @override
  StaffDirectoryFilters create() => StaffDirectoryFilters();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StaffDirectoryFilterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StaffDirectoryFilterState>(value),
    );
  }
}

String _$staffDirectoryFiltersHash() =>
    r'2ce98544e9cc2e5feb6d8cc8dc093b548e5fd907';

abstract class _$StaffDirectoryFilters
    extends $Notifier<StaffDirectoryFilterState> {
  StaffDirectoryFilterState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<StaffDirectoryFilterState, StaffDirectoryFilterState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<StaffDirectoryFilterState, StaffDirectoryFilterState>,
              StaffDirectoryFilterState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
