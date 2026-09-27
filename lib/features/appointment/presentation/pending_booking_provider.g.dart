// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_booking_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// An unknown outcome must reach the server receipt before balance validation.

@ProviderFor(pendingBooking)
final pendingBookingProvider = PendingBookingFamily._();

/// An unknown outcome must reach the server receipt before balance validation.

final class PendingBookingProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// An unknown outcome must reach the server receipt before balance validation.
  PendingBookingProvider._({
    required PendingBookingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pendingBookingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pendingBookingHash();

  @override
  String toString() {
    return r'pendingBookingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as String;
    return pendingBooking(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingBookingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pendingBookingHash() => r'4422dae3bb98599c01278e01c00d7541e1aa4f3e';

/// An unknown outcome must reach the server receipt before balance validation.

final class PendingBookingFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  PendingBookingFamily._()
    : super(
        retry: null,
        name: r'pendingBookingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// An unknown outcome must reach the server receipt before balance validation.

  PendingBookingProvider call(String patientId) =>
      PendingBookingProvider._(argument: patientId, from: this);

  @override
  String toString() => r'pendingBookingProvider';
}
