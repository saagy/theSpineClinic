// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_details_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One staff member's reference details for the editor. Only transient
/// network failures retry in the background; others show Retry at once.

@ProviderFor(staffDetails)
final staffDetailsProvider = StaffDetailsFamily._();

/// One staff member's reference details for the editor. Only transient
/// network failures retry in the background; others show Retry at once.

final class StaffDetailsProvider
    extends
        $FunctionalProvider<
          AsyncValue<StaffDetails>,
          StaffDetails,
          FutureOr<StaffDetails>
        >
    with $FutureModifier<StaffDetails>, $FutureProvider<StaffDetails> {
  /// One staff member's reference details for the editor. Only transient
  /// network failures retry in the background; others show Retry at once.
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

String _$staffDetailsHash() => r'b8c9dc40be890ecfce0435508eaace89e52af596';

/// One staff member's reference details for the editor. Only transient
/// network failures retry in the background; others show Retry at once.

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

  /// One staff member's reference details for the editor. Only transient
  /// network failures retry in the background; others show Retry at once.

  StaffDetailsProvider call(String staffId) =>
      StaffDetailsProvider._(argument: staffId, from: this);

  @override
  String toString() => r'staffDetailsProvider';
}

/// Working days and hours by staff ID for the directory. Empty for anyone
/// but super admins, and on failure the directory simply omits them.

@ProviderFor(staffSchedules)
final staffSchedulesProvider = StaffSchedulesProvider._();

/// Working days and hours by staff ID for the directory. Empty for anyone
/// but super admins, and on failure the directory simply omits them.

final class StaffSchedulesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, StaffDetails>>,
          Map<String, StaffDetails>,
          FutureOr<Map<String, StaffDetails>>
        >
    with
        $FutureModifier<Map<String, StaffDetails>>,
        $FutureProvider<Map<String, StaffDetails>> {
  /// Working days and hours by staff ID for the directory. Empty for anyone
  /// but super admins, and on failure the directory simply omits them.
  StaffSchedulesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'staffSchedulesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$staffSchedulesHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, StaffDetails>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, StaffDetails>> create(Ref ref) {
    return staffSchedules(ref);
  }
}

String _$staffSchedulesHash() => r'b2406a2aefe92714c3878c9f220efb26545290af';
