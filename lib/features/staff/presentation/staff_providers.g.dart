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

String _$activeDoctorsHash() => r'63a8cabbf18d26a853e0e31abf9a215b2536d74b';

/// Fetches all approved doctors (both active and deactivated, excluding pending applications).
///
/// Used by filter/search dropdowns (PatientListFilters, UnifiedFilterSheet)
/// where users need to filter by historical records tied to deactivated staff.
/// Deactivated doctors are visually distinguished with a "(Deactivated)" badge
/// in the UI. Operational dropdowns (creating/editing) continue to use
/// [activeDoctorsProvider] which strictly excludes inactive staff.

@ProviderFor(allDoctorsForFilter)
final allDoctorsForFilterProvider = AllDoctorsForFilterProvider._();

/// Fetches all approved doctors (both active and deactivated, excluding pending applications).
///
/// Used by filter/search dropdowns (PatientListFilters, UnifiedFilterSheet)
/// where users need to filter by historical records tied to deactivated staff.
/// Deactivated doctors are visually distinguished with a "(Deactivated)" badge
/// in the UI. Operational dropdowns (creating/editing) continue to use
/// [activeDoctorsProvider] which strictly excludes inactive staff.

final class AllDoctorsForFilterProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Staff>>,
          List<Staff>,
          FutureOr<List<Staff>>
        >
    with $FutureModifier<List<Staff>>, $FutureProvider<List<Staff>> {
  /// Fetches all approved doctors (both active and deactivated, excluding pending applications).
  ///
  /// Used by filter/search dropdowns (PatientListFilters, UnifiedFilterSheet)
  /// where users need to filter by historical records tied to deactivated staff.
  /// Deactivated doctors are visually distinguished with a "(Deactivated)" badge
  /// in the UI. Operational dropdowns (creating/editing) continue to use
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
    r'80e6acb30753416a47acbd89a3c37107fe780842';

/// Controller managing the roster of patients assigned to the logged-in doctor with pagination.

@ProviderFor(MyPatientsController)
final myPatientsControllerProvider = MyPatientsControllerProvider._();

/// Controller managing the roster of patients assigned to the logged-in doctor with pagination.
final class MyPatientsControllerProvider
    extends $AsyncNotifierProvider<MyPatientsController, List<Patient>> {
  /// Controller managing the roster of patients assigned to the logged-in doctor with pagination.
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
    r'4ee09af844e1281b9bc4c58a59cdd0b1117827b2';

/// Controller managing the roster of patients assigned to the logged-in doctor with pagination.

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
