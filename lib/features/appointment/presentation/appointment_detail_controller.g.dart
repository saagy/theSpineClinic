// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment_detail_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller loading a single appointment's detail view.

@ProviderFor(AppointmentDetailController)
final appointmentDetailControllerProvider =
    AppointmentDetailControllerFamily._();

/// Controller loading a single appointment's detail view.
final class AppointmentDetailControllerProvider
    extends
        $AsyncNotifierProvider<
          AppointmentDetailController,
          AppointmentDetailState
        > {
  /// Controller loading a single appointment's detail view.
  AppointmentDetailControllerProvider._({
    required AppointmentDetailControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: retryTransientErrors,
         name: r'appointmentDetailControllerProvider',
         isAutoDispose: false,
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
    r'9cd64f9437fdb8a79fd7d04a901534391373f017';

/// Controller loading a single appointment's detail view.

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
        retry: retryTransientErrors,
        name: r'appointmentDetailControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Controller loading a single appointment's detail view.

  AppointmentDetailControllerProvider call(String appointmentId) =>
      AppointmentDetailControllerProvider._(
        argument: appointmentId,
        from: this,
      );

  @override
  String toString() => r'appointmentDetailControllerProvider';
}

/// Controller loading a single appointment's detail view.

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
