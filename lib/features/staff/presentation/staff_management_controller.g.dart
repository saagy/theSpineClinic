// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_management_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier providing the reactive list of all clinic staff members (including doctors).
/// Enforces Super Admin role-based access check on build.

@ProviderFor(StaffList)
final staffListProvider = StaffListProvider._();

/// Notifier providing the reactive list of all clinic staff members (including doctors).
/// Enforces Super Admin role-based access check on build.
final class StaffListProvider
    extends $AsyncNotifierProvider<StaffList, List<Staff>> {
  /// Notifier providing the reactive list of all clinic staff members (including doctors).
  /// Enforces Super Admin role-based access check on build.
  StaffListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'staffListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$staffListHash();

  @$internal
  @override
  StaffList create() => StaffList();
}

String _$staffListHash() => r'19fe24e462b5e768ee35d560a16f4f8e831f34ad';

/// Notifier providing the reactive list of all clinic staff members (including doctors).
/// Enforces Super Admin role-based access check on build.

abstract class _$StaffList extends $AsyncNotifier<List<Staff>> {
  FutureOr<List<Staff>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Staff>>, List<Staff>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Staff>>, List<Staff>>,
              AsyncValue<List<Staff>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider for the selected role filter on the staff list screen.

@ProviderFor(StaffFilter)
final staffFilterProvider = StaffFilterProvider._();

/// Provider for the selected role filter on the staff list screen.
final class StaffFilterProvider extends $NotifierProvider<StaffFilter, String> {
  /// Provider for the selected role filter on the staff list screen.
  StaffFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'staffFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$staffFilterHash();

  @$internal
  @override
  StaffFilter create() => StaffFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$staffFilterHash() => r'137aa72dec8aefa332726cc337fa22b1f8f29084';

/// Provider for the selected role filter on the staff list screen.

abstract class _$StaffFilter extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Computes the filtered roster of clinic staff members based on the selected filter.

@ProviderFor(filteredStaff)
final filteredStaffProvider = FilteredStaffProvider._();

/// Computes the filtered roster of clinic staff members based on the selected filter.

final class FilteredStaffProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Staff>>,
          List<Staff>,
          FutureOr<List<Staff>>
        >
    with $FutureModifier<List<Staff>>, $FutureProvider<List<Staff>> {
  /// Computes the filtered roster of clinic staff members based on the selected filter.
  FilteredStaffProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredStaffProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredStaffHash();

  @$internal
  @override
  $FutureProviderElement<List<Staff>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Staff>> create(Ref ref) {
    return filteredStaff(ref);
  }
}

String _$filteredStaffHash() => r'55a678f0224ffd90e91419405fcfadcd46750dc9';

/// Controller managing staff account registration and modifications.

@ProviderFor(StaffFormController)
final staffFormControllerProvider = StaffFormControllerProvider._();

/// Controller managing staff account registration and modifications.
final class StaffFormControllerProvider
    extends $NotifierProvider<StaffFormController, AsyncValue<void>> {
  /// Controller managing staff account registration and modifications.
  StaffFormControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'staffFormControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$staffFormControllerHash();

  @$internal
  @override
  StaffFormController create() => StaffFormController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$staffFormControllerHash() =>
    r'eccfe3d5ec04e064613a8a10f1c2b7e1614b5539';

/// Controller managing staff account registration and modifications.

abstract class _$StaffFormController extends $Notifier<AsyncValue<void>> {
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
