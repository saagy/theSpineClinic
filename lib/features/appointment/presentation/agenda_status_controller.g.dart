// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agenda_status_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One in-flight mutation per appointment, shared by row and menu.

@ProviderFor(AgendaStatusController)
final agendaStatusControllerProvider = AgendaStatusControllerFamily._();

/// One in-flight mutation per appointment, shared by row and menu.
final class AgendaStatusControllerProvider
    extends $NotifierProvider<AgendaStatusController, AgendaStatusState> {
  /// One in-flight mutation per appointment, shared by row and menu.
  AgendaStatusControllerProvider._({
    required AgendaStatusControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'agendaStatusControllerProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$agendaStatusControllerHash();

  @override
  String toString() {
    return r'agendaStatusControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AgendaStatusController create() => AgendaStatusController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AgendaStatusState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AgendaStatusState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AgendaStatusControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$agendaStatusControllerHash() =>
    r'41769a03105a19fc0d6acafa9d08f10b76af5102';

/// One in-flight mutation per appointment, shared by row and menu.

final class AgendaStatusControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          AgendaStatusController,
          AgendaStatusState,
          AgendaStatusState,
          AgendaStatusState,
          String
        > {
  AgendaStatusControllerFamily._()
    : super(
        retry: null,
        name: r'agendaStatusControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// One in-flight mutation per appointment, shared by row and menu.

  AgendaStatusControllerProvider call(String appointmentId) =>
      AgendaStatusControllerProvider._(argument: appointmentId, from: this);

  @override
  String toString() => r'agendaStatusControllerProvider';
}

/// One in-flight mutation per appointment, shared by row and menu.

abstract class _$AgendaStatusController extends $Notifier<AgendaStatusState> {
  late final _$args = ref.$arg as String;
  String get appointmentId => _$args;

  AgendaStatusState build(String appointmentId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AgendaStatusState, AgendaStatusState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AgendaStatusState, AgendaStatusState>,
              AgendaStatusState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
