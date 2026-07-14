// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_workboard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BookingWorkboard)
final bookingWorkboardProvider = BookingWorkboardProvider._();

final class BookingWorkboardProvider
    extends $NotifierProvider<BookingWorkboard, BookingWorkboardState> {
  BookingWorkboardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookingWorkboardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookingWorkboardHash();

  @$internal
  @override
  BookingWorkboard create() => BookingWorkboard();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BookingWorkboardState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BookingWorkboardState>(value),
    );
  }
}

String _$bookingWorkboardHash() => r'd40c73156d8504b03590b98086c2957e706eec71';

abstract class _$BookingWorkboard extends $Notifier<BookingWorkboardState> {
  BookingWorkboardState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<BookingWorkboardState, BookingWorkboardState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BookingWorkboardState, BookingWorkboardState>,
              BookingWorkboardState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
