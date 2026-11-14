// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_details_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One staff member's employment details. Row-level security returns
/// nothing for colleagues a head receptionist does not share a branch with,
/// which reads as empty. Only transient failures retry in the background.

@ProviderFor(staffDetails)
final staffDetailsProvider = StaffDetailsFamily._();

/// One staff member's employment details. Row-level security returns
/// nothing for colleagues a head receptionist does not share a branch with,
/// which reads as empty. Only transient failures retry in the background.

final class StaffDetailsProvider
    extends
        $FunctionalProvider<
          AsyncValue<StaffDetails>,
          StaffDetails,
          FutureOr<StaffDetails>
        >
    with $FutureModifier<StaffDetails>, $FutureProvider<StaffDetails> {
  /// One staff member's employment details. Row-level security returns
  /// nothing for colleagues a head receptionist does not share a branch with,
  /// which reads as empty. Only transient failures retry in the background.
  StaffDetailsProvider._({
    required StaffDetailsFamily super.from,
    required String super.argument,
  }) : super(
         retry: retryTransientErrors,
         name: r'staffDetailsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$staffDetailsHash();

  @override
  String toString() {
    return r'staffDetailsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<StaffDetails> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<StaffDetails> create(Ref ref) {
    final argument = this.argument as String;
    return staffDetails(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is StaffDetailsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$staffDetailsHash() => r'f3d3495541ac170e990799df69ba1995a3b4a361';

/// One staff member's employment details. Row-level security returns
/// nothing for colleagues a head receptionist does not share a branch with,
/// which reads as empty. Only transient failures retry in the background.

final class StaffDetailsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<StaffDetails>, String> {
  StaffDetailsFamily._()
    : super(
        retry: retryTransientErrors,
        name: r'staffDetailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One staff member's employment details. Row-level security returns
  /// nothing for colleagues a head receptionist does not share a branch with,
  /// which reads as empty. Only transient failures retry in the background.

  StaffDetailsProvider call(String staffId) =>
      StaffDetailsProvider._(argument: staffId, from: this);

  @override
  String toString() => r'staffDetailsProvider';
}

/// Every staff member's branches and weekly shifts. Pickers, filters and
/// booking warnings read it; it is reloaded after a staff save.

@ProviderFor(staffAssignments)
final staffAssignmentsProvider = StaffAssignmentsProvider._();

/// Every staff member's branches and weekly shifts. Pickers, filters and
/// booking warnings read it; it is reloaded after a staff save.

final class StaffAssignmentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<StaffAssignments>,
          StaffAssignments,
          FutureOr<StaffAssignments>
        >
    with $FutureModifier<StaffAssignments>, $FutureProvider<StaffAssignments> {
  /// Every staff member's branches and weekly shifts. Pickers, filters and
  /// booking warnings read it; it is reloaded after a staff save.
  StaffAssignmentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: retryTransientErrors,
        name: r'staffAssignmentsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$staffAssignmentsHash();

  @$internal
  @override
  $FutureProviderElement<StaffAssignments> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<StaffAssignments> create(Ref ref) {
    return staffAssignments(ref);
  }
}

String _$staffAssignmentsHash() => r'460ddf11797ee9e24c9821aa2ed653c71e252537';

/// The branches the signed-in person belongs to; empty when they have none
/// or while the assignments load (branches only order and default lists,
/// so a missing value never hides anything).

@ProviderFor(myBranches)
final myBranchesProvider = MyBranchesProvider._();

/// The branches the signed-in person belongs to; empty when they have none
/// or while the assignments load (branches only order and default lists,
/// so a missing value never hides anything).

final class MyBranchesProvider
    extends
        $FunctionalProvider<
          List<ClinicLocation>,
          List<ClinicLocation>,
          List<ClinicLocation>
        >
    with $Provider<List<ClinicLocation>> {
  /// The branches the signed-in person belongs to; empty when they have none
  /// or while the assignments load (branches only order and default lists,
  /// so a missing value never hides anything).
  MyBranchesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myBranchesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myBranchesHash();

  @$internal
  @override
  $ProviderElement<List<ClinicLocation>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ClinicLocation> create(Ref ref) {
    return myBranches(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ClinicLocation> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ClinicLocation>>(value),
    );
  }
}

String _$myBranchesHash() => r'44e3c2a961b351344766e0ad659fb76a54245071';
