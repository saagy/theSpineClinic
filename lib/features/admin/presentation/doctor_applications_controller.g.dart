// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'doctor_applications_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier resolving the roster of pending doctor registration applications.

@ProviderFor(PendingDoctorApplications)
final pendingDoctorApplicationsProvider = PendingDoctorApplicationsProvider._();

/// Notifier resolving the roster of pending doctor registration applications.
final class PendingDoctorApplicationsProvider
    extends $AsyncNotifierProvider<PendingDoctorApplications, List<Staff>> {
  /// Notifier resolving the roster of pending doctor registration applications.
  PendingDoctorApplicationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingDoctorApplicationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingDoctorApplicationsHash();

  @$internal
  @override
  PendingDoctorApplications create() => PendingDoctorApplications();
}

String _$pendingDoctorApplicationsHash() =>
    r'0a31fdef37421e0085ec02f44fc501c6005894c5';

/// Notifier resolving the roster of pending doctor registration applications.

abstract class _$PendingDoctorApplications extends $AsyncNotifier<List<Staff>> {
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

/// Notifier resolving the total audit tracker roster of all doctor applications.

@ProviderFor(AllDoctorApplications)
final allDoctorApplicationsProvider = AllDoctorApplicationsProvider._();

/// Notifier resolving the total audit tracker roster of all doctor applications.
final class AllDoctorApplicationsProvider
    extends $AsyncNotifierProvider<AllDoctorApplications, List<Staff>> {
  /// Notifier resolving the total audit tracker roster of all doctor applications.
  AllDoctorApplicationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allDoctorApplicationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allDoctorApplicationsHash();

  @$internal
  @override
  AllDoctorApplications create() => AllDoctorApplications();
}

String _$allDoctorApplicationsHash() =>
    r'defc3ac2dd8dc4aca1b1f9e1f5bbee61eab92fa1';

/// Notifier resolving the total audit tracker roster of all doctor applications.

abstract class _$AllDoctorApplications extends $AsyncNotifier<List<Staff>> {
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

/// Controller managing approval and rejection actions for doctor applications.

@ProviderFor(DoctorApplicationsAction)
final doctorApplicationsActionProvider = DoctorApplicationsActionProvider._();

/// Controller managing approval and rejection actions for doctor applications.
final class DoctorApplicationsActionProvider
    extends $NotifierProvider<DoctorApplicationsAction, AsyncValue<void>> {
  /// Controller managing approval and rejection actions for doctor applications.
  DoctorApplicationsActionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'doctorApplicationsActionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$doctorApplicationsActionHash();

  @$internal
  @override
  DoctorApplicationsAction create() => DoctorApplicationsAction();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$doctorApplicationsActionHash() =>
    r'964d10fe24c83e8cd37cb94bc9a698486e6f125e';

/// Controller managing approval and rejection actions for doctor applications.

abstract class _$DoctorApplicationsAction extends $Notifier<AsyncValue<void>> {
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
