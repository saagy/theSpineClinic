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

String _$staffListHash() => r'07668598e34b4460f1f955acc2b53c844b05a9b9';

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
    r'01711ae51302d00f059474be7d90fe4181690dee';

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
