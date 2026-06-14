// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment_detail_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller managing a single appointment's detail view and mutations.

@ProviderFor(AppointmentDetailController)
final appointmentDetailControllerProvider =
    AppointmentDetailControllerFamily._();

/// Controller managing a single appointment's detail view and mutations.
final class AppointmentDetailControllerProvider
    extends
        $AsyncNotifierProvider<
          AppointmentDetailController,
          AppointmentDetailState
        > {
  /// Controller managing a single appointment's detail view and mutations.
  AppointmentDetailControllerProvider._({
    required AppointmentDetailControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'appointmentDetailControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$appointmentDetailControllerHash();

  @override
  String toString() {
    return r'appointmentDetailControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AppointmentDetailController create() => AppointmentDetailController();

  @override
  bool operator ==(Object other) {
    return other is AppointmentDetailControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$appointmentDetailControllerHash() =>
    r'2a02f7b324f536bf84731ba72ac56eba80989d8c';

/// Controller managing a single appointment's detail view and mutations.

final class AppointmentDetailControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          AppointmentDetailController,
          AsyncValue<AppointmentDetailState>,
          AppointmentDetailState,
          FutureOr<AppointmentDetailState>,
          String
        > {
  AppointmentDetailControllerFamily._()
    : super(
        retry: null,
        name: r'appointmentDetailControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Controller managing a single appointment's detail view and mutations.

  AppointmentDetailControllerProvider call(String appointmentId) =>
      AppointmentDetailControllerProvider._(
        argument: appointmentId,
        from: this,
      );

  @override
  String toString() => r'appointmentDetailControllerProvider';
}

/// Controller managing a single appointment's detail view and mutations.

abstract class _$AppointmentDetailController
    extends $AsyncNotifier<AppointmentDetailState> {
  late final _$args = ref.$arg as String;
  String get appointmentId => _$args;

  FutureOr<AppointmentDetailState> build(String appointmentId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<AppointmentDetailState>, AppointmentDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<AppointmentDetailState>,
                AppointmentDetailState
              >,
              AsyncValue<AppointmentDetailState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
