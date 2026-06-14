// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_schedule_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the doctor's calendar schedule, resolving active doctor context,
/// querying database data, and applying correct horizon filtering.

@ProviderFor(MyScheduleController)
final myScheduleControllerProvider = MyScheduleControllerProvider._();

/// Manages the doctor's calendar schedule, resolving active doctor context,
/// querying database data, and applying correct horizon filtering.
final class MyScheduleControllerProvider
    extends $AsyncNotifierProvider<MyScheduleController, MyScheduleState> {
  /// Manages the doctor's calendar schedule, resolving active doctor context,
  /// querying database data, and applying correct horizon filtering.
  MyScheduleControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myScheduleControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myScheduleControllerHash();

  @$internal
  @override
  MyScheduleController create() => MyScheduleController();
}

String _$myScheduleControllerHash() =>
    r'd32666e763487b1a4fdb090e2f3f4758a0feb7ac';

/// Manages the doctor's calendar schedule, resolving active doctor context,
/// querying database data, and applying correct horizon filtering.

abstract class _$MyScheduleController extends $AsyncNotifier<MyScheduleState> {
  FutureOr<MyScheduleState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<MyScheduleState>, MyScheduleState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MyScheduleState>, MyScheduleState>,
              AsyncValue<MyScheduleState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
