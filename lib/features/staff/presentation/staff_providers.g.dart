// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a singleton [StaffRepository] instance.

@ProviderFor(staffRepository)
final staffRepositoryProvider = StaffRepositoryProvider._();

/// Provides a singleton [StaffRepository] instance.

final class StaffRepositoryProvider
    extends
        $FunctionalProvider<StaffRepository, StaffRepository, StaffRepository>
    with $Provider<StaffRepository> {
  /// Provides a singleton [StaffRepository] instance.
  StaffRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'staffRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$staffRepositoryHash();

  @$internal
  @override
  $ProviderElement<StaffRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StaffRepository create(Ref ref) {
    return staffRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StaffRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StaffRepository>(value),
    );
  }
}

String _$staffRepositoryHash() => r'3ba368c8f6795b30ed9068a9129e8433cfde3fd6';

/// Fetches all active/approved staff members with the doctor role.

@ProviderFor(activeDoctors)
final activeDoctorsProvider = ActiveDoctorsProvider._();

/// Fetches all active/approved staff members with the doctor role.

final class ActiveDoctorsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Staff>>,
          List<Staff>,
          FutureOr<List<Staff>>
        >
    with $FutureModifier<List<Staff>>, $FutureProvider<List<Staff>> {
  /// Fetches all active/approved staff members with the doctor role.
  ActiveDoctorsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeDoctorsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeDoctorsHash();

  @$internal
  @override
  $FutureProviderElement<List<Staff>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Staff>> create(Ref ref) {
    return activeDoctors(ref);
  }
}

String _$activeDoctorsHash() => r'a0059252e266680f9dcc4ee21660081d9ef19579';

/// Fetches approved doctors (active and deactivated) for filter dropdowns.

@ProviderFor(allDoctorsForFilter)
final allDoctorsForFilterProvider = AllDoctorsForFilterProvider._();

/// Fetches approved doctors (active and deactivated) for filter dropdowns.

final class AllDoctorsForFilterProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Staff>>,
          List<Staff>,
          FutureOr<List<Staff>>
        >
    with $FutureModifier<List<Staff>>, $FutureProvider<List<Staff>> {
  /// Fetches approved doctors (active and deactivated) for filter dropdowns.
  AllDoctorsForFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allDoctorsForFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allDoctorsForFilterHash();

  @$internal
  @override
  $FutureProviderElement<List<Staff>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Staff>> create(Ref ref) {
    return allDoctorsForFilter(ref);
  }
}

String _$allDoctorsForFilterHash() =>
    r'f77c3862328d0d1630480220fc57d7f1689b75cc';

/// Controller managing the roster of patients assigned to the doctor.

@ProviderFor(MyPatientsController)
final myPatientsControllerProvider = MyPatientsControllerProvider._();

/// Controller managing the roster of patients assigned to the doctor.
final class MyPatientsControllerProvider
    extends $AsyncNotifierProvider<MyPatientsController, List<Patient>> {
  /// Controller managing the roster of patients assigned to the doctor.
  MyPatientsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myPatientsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myPatientsControllerHash();

  @$internal
  @override
  MyPatientsController create() => MyPatientsController();
}

String _$myPatientsControllerHash() =>
    r'c0daf662f604539d24701dc554637b3ddcac23c9';

/// Controller managing the roster of patients assigned to the doctor.

abstract class _$MyPatientsController extends $AsyncNotifier<List<Patient>> {
  FutureOr<List<Patient>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Patient>>, List<Patient>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Patient>>, List<Patient>>,
              AsyncValue<List<Patient>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
