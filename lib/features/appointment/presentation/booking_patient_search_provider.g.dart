// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_patient_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches a bounded list of patients (up to 20) for booking selection,
/// querying the server directly instead of loading the entire patient base.

@ProviderFor(bookingPatientSearch)
final bookingPatientSearchProvider = BookingPatientSearchFamily._();

/// Fetches a bounded list of patients (up to 20) for booking selection,
/// querying the server directly instead of loading the entire patient base.

final class BookingPatientSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Patient>>,
          List<Patient>,
          FutureOr<List<Patient>>
        >
    with $FutureModifier<List<Patient>>, $FutureProvider<List<Patient>> {
  /// Fetches a bounded list of patients (up to 20) for booking selection,
  /// querying the server directly instead of loading the entire patient base.
  BookingPatientSearchProvider._({
    required BookingPatientSearchFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'bookingPatientSearchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bookingPatientSearchHash();

  @override
  String toString() {
    return r'bookingPatientSearchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Patient>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Patient>> create(Ref ref) {
    final argument = this.argument as String;
    return bookingPatientSearch(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BookingPatientSearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bookingPatientSearchHash() =>
    r'de58dde278b95618ffa4d654a797183638993308';

/// Fetches a bounded list of patients (up to 20) for booking selection,
/// querying the server directly instead of loading the entire patient base.

final class BookingPatientSearchFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Patient>>, String> {
  BookingPatientSearchFamily._()
    : super(
        retry: null,
        name: r'bookingPatientSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches a bounded list of patients (up to 20) for booking selection,
  /// querying the server directly instead of loading the entire patient base.

  BookingPatientSearchProvider call(String query) =>
      BookingPatientSearchProvider._(argument: query, from: this);

  @override
  String toString() => r'bookingPatientSearchProvider';
}
