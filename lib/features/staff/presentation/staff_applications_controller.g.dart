// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_applications_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier resolving the roster of pending staff registration applications.

@ProviderFor(PendingStaffApplications)
final pendingStaffApplicationsProvider = PendingStaffApplicationsProvider._();

/// Notifier resolving the roster of pending staff registration applications.
final class PendingStaffApplicationsProvider
    extends $AsyncNotifierProvider<PendingStaffApplications, List<Staff>> {
  /// Notifier resolving the roster of pending staff registration applications.
  PendingStaffApplicationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingStaffApplicationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingStaffApplicationsHash();

  @$internal
  @override
  PendingStaffApplications create() => PendingStaffApplications();
}

String _$pendingStaffApplicationsHash() =>
    r'dbbd55d9e2b3a5df160f24ae81a5161cc4172657';

/// Notifier resolving the roster of pending staff registration applications.

abstract class _$PendingStaffApplications extends $AsyncNotifier<List<Staff>> {
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

/// Controller managing approval and rejection actions for staff applications.

@ProviderFor(StaffApplicationsAction)
final staffApplicationsActionProvider = StaffApplicationsActionProvider._();

/// Controller managing approval and rejection actions for staff applications.
final class StaffApplicationsActionProvider
    extends $NotifierProvider<StaffApplicationsAction, AsyncValue<void>> {
  /// Controller managing approval and rejection actions for staff applications.
  StaffApplicationsActionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'staffApplicationsActionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$staffApplicationsActionHash();

  @$internal
  @override
  StaffApplicationsAction create() => StaffApplicationsAction();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$staffApplicationsActionHash() =>
    r'7e5a0fecd03a16c2d82e01a8cc145a363ecc3858';

/// Controller managing approval and rejection actions for staff applications.

abstract class _$StaffApplicationsAction extends $Notifier<AsyncValue<void>> {
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
