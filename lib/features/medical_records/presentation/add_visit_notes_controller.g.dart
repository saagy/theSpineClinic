// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_visit_notes_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller managing a single appointment's visit notes state and updates.

@ProviderFor(AddVisitNotesController)
final addVisitNotesControllerProvider = AddVisitNotesControllerFamily._();

/// Controller managing a single appointment's visit notes state and updates.
final class AddVisitNotesControllerProvider
    extends
        $AsyncNotifierProvider<AddVisitNotesController, AddVisitNotesState> {
  /// Controller managing a single appointment's visit notes state and updates.
  AddVisitNotesControllerProvider._({
    required AddVisitNotesControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'addVisitNotesControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$addVisitNotesControllerHash();

  @override
  String toString() {
    return r'addVisitNotesControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AddVisitNotesController create() => AddVisitNotesController();

  @override
  bool operator ==(Object other) {
    return other is AddVisitNotesControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$addVisitNotesControllerHash() =>
    r'06b53488e8c350030863284c86b26fa86b3dbf3d';

/// Controller managing a single appointment's visit notes state and updates.

final class AddVisitNotesControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          AddVisitNotesController,
          AsyncValue<AddVisitNotesState>,
          AddVisitNotesState,
          FutureOr<AddVisitNotesState>,
          String
        > {
  AddVisitNotesControllerFamily._()
    : super(
        retry: null,
        name: r'addVisitNotesControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Controller managing a single appointment's visit notes state and updates.

  AddVisitNotesControllerProvider call(String appointmentId) =>
      AddVisitNotesControllerProvider._(argument: appointmentId, from: this);

  @override
  String toString() => r'addVisitNotesControllerProvider';
}

/// Controller managing a single appointment's visit notes state and updates.

abstract class _$AddVisitNotesController
    extends $AsyncNotifier<AddVisitNotesState> {
  late final _$args = ref.$arg as String;
  String get appointmentId => _$args;

  FutureOr<AddVisitNotesState> build(String appointmentId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<AddVisitNotesState>, AddVisitNotesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AddVisitNotesState>, AddVisitNotesState>,
              AsyncValue<AddVisitNotesState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
