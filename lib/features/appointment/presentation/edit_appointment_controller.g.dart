// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edit_appointment_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier state class for editing appointment.

@ProviderFor(EditAppointmentController)
final editAppointmentControllerProvider = EditAppointmentControllerProvider._();

/// Notifier state class for editing appointment.
final class EditAppointmentControllerProvider
    extends $AsyncNotifierProvider<EditAppointmentController, void> {
  /// Notifier state class for editing appointment.
  EditAppointmentControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'editAppointmentControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$editAppointmentControllerHash();

  @$internal
  @override
  EditAppointmentController create() => EditAppointmentController();
}

String _$editAppointmentControllerHash() =>
    r'8abec258c121b3ea591cbc160a7bf99d8a60636b';

/// Notifier state class for editing appointment.

abstract class _$EditAppointmentController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
