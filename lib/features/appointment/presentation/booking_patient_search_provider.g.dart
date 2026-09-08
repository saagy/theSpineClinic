// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_patient_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Loads every matching patient a page at a time for booking selection.

@ProviderFor(BookingPatientSearch)
final bookingPatientSearchProvider = BookingPatientSearchFamily._();

/// Loads every matching patient a page at a time for booking selection.
final class BookingPatientSearchProvider
    extends $AsyncNotifierProvider<BookingPatientSearch, List<Patient>> {
  /// Loads every matching patient a page at a time for booking selection.
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
  BookingPatientSearch create() => BookingPatientSearch();

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
    r'00a4779344c1a7861c9cc1ea7fc4f18d9fa4686f';

/// Loads every matching patient a page at a time for booking selection.

final class BookingPatientSearchFamily extends $Family
    with
        $ClassFamilyOverride<
          BookingPatientSearch,
          AsyncValue<List<Patient>>,
          List<Patient>,
          FutureOr<List<Patient>>,
          String
        > {
  BookingPatientSearchFamily._()
    : super(
        retry: null,
        name: r'bookingPatientSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Loads every matching patient a page at a time for booking selection.

  BookingPatientSearchProvider call(String query) =>
      BookingPatientSearchProvider._(argument: query, from: this);

  @override
  String toString() => r'bookingPatientSearchProvider';
}

/// Loads every matching patient a page at a time for booking selection.

abstract class _$BookingPatientSearch extends $AsyncNotifier<List<Patient>> {
  late final _$args = ref.$arg as String;
  String get query => _$args;

  FutureOr<List<Patient>> build(String query);
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
    element.handleCreate(ref, () => build(_$args));
  }
}
