// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visit_detail_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controller managing a single completed visit's detail state.

@ProviderFor(VisitDetailController)
final visitDetailControllerProvider = VisitDetailControllerFamily._();

/// Controller managing a single completed visit's detail state.
final class VisitDetailControllerProvider
    extends $AsyncNotifierProvider<VisitDetailController, VisitDetailState> {
  /// Controller managing a single completed visit's detail state.
  VisitDetailControllerProvider._({
    required VisitDetailControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'visitDetailControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$visitDetailControllerHash();

  @override
  String toString() {
    return r'visitDetailControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  VisitDetailController create() => VisitDetailController();

  @override
  bool operator ==(Object other) {
    return other is VisitDetailControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$visitDetailControllerHash() =>
    r'6dafcc07b192bfcf64d2ae4047d615e9f5b6d20e';

/// Controller managing a single completed visit's detail state.

final class VisitDetailControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          VisitDetailController,
          AsyncValue<VisitDetailState>,
          VisitDetailState,
          FutureOr<VisitDetailState>,
          String
        > {
  VisitDetailControllerFamily._()
    : super(
        retry: null,
        name: r'visitDetailControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Controller managing a single completed visit's detail state.

  VisitDetailControllerProvider call(String appointmentId) =>
      VisitDetailControllerProvider._(argument: appointmentId, from: this);

  @override
  String toString() => r'visitDetailControllerProvider';
}

/// Controller managing a single completed visit's detail state.

abstract class _$VisitDetailController
    extends $AsyncNotifier<VisitDetailState> {
  late final _$args = ref.$arg as String;
  String get appointmentId => _$args;

  FutureOr<VisitDetailState> build(String appointmentId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<VisitDetailState>, VisitDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<VisitDetailState>, VisitDetailState>,
              AsyncValue<VisitDetailState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
