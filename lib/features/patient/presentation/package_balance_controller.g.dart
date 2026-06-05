// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package_balance_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Presentation controller managing the state of manual package balance edits.

@ProviderFor(PackageBalanceController)
final packageBalanceControllerProvider = PackageBalanceControllerProvider._();

/// Presentation controller managing the state of manual package balance edits.
final class PackageBalanceControllerProvider
    extends $AsyncNotifierProvider<PackageBalanceController, void> {
  /// Presentation controller managing the state of manual package balance edits.
  PackageBalanceControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'packageBalanceControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$packageBalanceControllerHash();

  @$internal
  @override
  PackageBalanceController create() => PackageBalanceController();
}

String _$packageBalanceControllerHash() =>
    r'b31df24878cdba7615df8253a3f768583ead1bb7';

/// Presentation controller managing the state of manual package balance edits.

abstract class _$PackageBalanceController extends $AsyncNotifier<void> {
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
