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

String _$staffRepositoryHash() => r'699ba4610d67e407c097cd066f8afce5869443f7';

/// Fetches all active/approved staff members with the role of doctor or super admin.

@ProviderFor(activeDoctors)
final activeDoctorsProvider = ActiveDoctorsProvider._();

/// Fetches all active/approved staff members with the role of doctor or super admin.

final class ActiveDoctorsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Staff>>,
          List<Staff>,
          FutureOr<List<Staff>>
        >
    with $FutureModifier<List<Staff>>, $FutureProvider<List<Staff>> {
  /// Fetches all active/approved staff members with the role of doctor or super admin.
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

String _$activeDoctorsHash() => r'63a8cabbf18d26a853e0e31abf9a215b2536d74b';

/// Fetches all doctors and super admins regardless of active status.
///
/// Used by filter/search dropdowns (PatientListFilters, UnifiedFilterSheet)
/// where users need to filter by historical records tied to deactivated staff.
/// Inactive doctors are visually distinguished with an "(Inactive)" badge in
/// the UI. Operational dropdowns (creating/editing) continue to use
/// [activeDoctorsProvider] which strictly excludes inactive staff.

@ProviderFor(allDoctorsForFilter)
final allDoctorsForFilterProvider = AllDoctorsForFilterProvider._();

/// Fetches all doctors and super admins regardless of active status.
///
/// Used by filter/search dropdowns (PatientListFilters, UnifiedFilterSheet)
/// where users need to filter by historical records tied to deactivated staff.
/// Inactive doctors are visually distinguished with an "(Inactive)" badge in
/// the UI. Operational dropdowns (creating/editing) continue to use
/// [activeDoctorsProvider] which strictly excludes inactive staff.

final class AllDoctorsForFilterProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Staff>>,
          List<Staff>,
          FutureOr<List<Staff>>
        >
    with $FutureModifier<List<Staff>>, $FutureProvider<List<Staff>> {
  /// Fetches all doctors and super admins regardless of active status.
  ///
  /// Used by filter/search dropdowns (PatientListFilters, UnifiedFilterSheet)
  /// where users need to filter by historical records tied to deactivated staff.
  /// Inactive doctors are visually distinguished with an "(Inactive)" badge in
  /// the UI. Operational dropdowns (creating/editing) continue to use
  /// [activeDoctorsProvider] which strictly excludes inactive staff.
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
    r'0d283bfdef4ce1138bc4d02eb7ff55498076e93c';

/// Controller managing the roster of patients assigned to the logged-in doctor.

@ProviderFor(MyPatientsController)
final myPatientsControllerProvider = MyPatientsControllerProvider._();

/// Controller managing the roster of patients assigned to the logged-in doctor.
final class MyPatientsControllerProvider
    extends $AsyncNotifierProvider<MyPatientsController, List<Patient>> {
  /// Controller managing the roster of patients assigned to the logged-in doctor.
  MyPatientsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myPatientsControllerProvider',
        isAutoDispose: true,
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
    r'2c0455708a80fcbef69c9910a276bf63e52d6034';

/// Controller managing the roster of patients assigned to the logged-in doctor.

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
