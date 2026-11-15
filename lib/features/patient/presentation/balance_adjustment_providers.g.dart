// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance_adjustment_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(balanceAdjustmentRepository)
final balanceAdjustmentRepositoryProvider =
    BalanceAdjustmentRepositoryProvider._();

final class BalanceAdjustmentRepositoryProvider
    extends
        $FunctionalProvider<
          BalanceAdjustmentRepository,
          BalanceAdjustmentRepository,
          BalanceAdjustmentRepository
        >
    with $Provider<BalanceAdjustmentRepository> {
  BalanceAdjustmentRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'balanceAdjustmentRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$balanceAdjustmentRepositoryHash();

  @$internal
  @override
  $ProviderElement<BalanceAdjustmentRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BalanceAdjustmentRepository create(Ref ref) {
    return balanceAdjustmentRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BalanceAdjustmentRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BalanceAdjustmentRepository>(value),
    );
  }
}

String _$balanceAdjustmentRepositoryHash() =>
    r'42995c9a27c2003c97dec5ba24125a7cd4ba6df4';

/// A patient's balance corrections, newest first.

@ProviderFor(balanceAdjustments)
final balanceAdjustmentsProvider = BalanceAdjustmentsFamily._();

/// A patient's balance corrections, newest first.

final class BalanceAdjustmentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BalanceAdjustment>>,
          List<BalanceAdjustment>,
          FutureOr<List<BalanceAdjustment>>
        >
    with
        $FutureModifier<List<BalanceAdjustment>>,
        $FutureProvider<List<BalanceAdjustment>> {
  /// A patient's balance corrections, newest first.
  BalanceAdjustmentsProvider._({
    required BalanceAdjustmentsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'balanceAdjustmentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$balanceAdjustmentsHash();

  @override
  String toString() {
    return r'balanceAdjustmentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<BalanceAdjustment>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BalanceAdjustment>> create(Ref ref) {
    final argument = this.argument as String;
    return balanceAdjustments(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BalanceAdjustmentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$balanceAdjustmentsHash() =>
    r'b2fbb894a8075d73167f231898c86a6f9750be42';

/// A patient's balance corrections, newest first.

final class BalanceAdjustmentsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<BalanceAdjustment>>, String> {
  BalanceAdjustmentsFamily._()
    : super(
        retry: null,
        name: r'balanceAdjustmentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A patient's balance corrections, newest first.

  BalanceAdjustmentsProvider call(String patientId) =>
      BalanceAdjustmentsProvider._(argument: patientId, from: this);

  @override
  String toString() => r'balanceAdjustmentsProvider';
}

/// Saves a correction. Kept alive so a save started from a dialog finishes
/// its refreshes even after the dialog closes.

@ProviderFor(BalanceAdjustmentController)
final balanceAdjustmentControllerProvider =
    BalanceAdjustmentControllerProvider._();

/// Saves a correction. Kept alive so a save started from a dialog finishes
/// its refreshes even after the dialog closes.
final class BalanceAdjustmentControllerProvider
    extends $NotifierProvider<BalanceAdjustmentController, bool> {
  /// Saves a correction. Kept alive so a save started from a dialog finishes
  /// its refreshes even after the dialog closes.
  BalanceAdjustmentControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'balanceAdjustmentControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$balanceAdjustmentControllerHash();

  @$internal
  @override
  BalanceAdjustmentController create() => BalanceAdjustmentController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$balanceAdjustmentControllerHash() =>
    r'd64f9899e0e271d9ce4211050b435f7c3658dfc3';

/// Saves a correction. Kept alive so a save started from a dialog finishes
/// its refreshes even after the dialog closes.

abstract class _$BalanceAdjustmentController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
