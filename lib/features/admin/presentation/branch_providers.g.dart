// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branch_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Active branch state notifier. Synchronously exposes choices and persists updates.

@ProviderFor(ActiveBranch)
final activeBranchProvider = ActiveBranchProvider._();

/// Active branch state notifier. Synchronously exposes choices and persists updates.
final class ActiveBranchProvider
    extends $NotifierProvider<ActiveBranch, ClinicLocation> {
  /// Active branch state notifier. Synchronously exposes choices and persists updates.
  ActiveBranchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeBranchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeBranchHash();

  @$internal
  @override
  ActiveBranch create() => ActiveBranch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClinicLocation value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClinicLocation>(value),
    );
  }
}

String _$activeBranchHash() => r'8ce81f1d56ea9d4c6e049b9ea2a395746e596caf';

/// Active branch state notifier. Synchronously exposes choices and persists updates.

abstract class _$ActiveBranch extends $Notifier<ClinicLocation> {
  ClinicLocation build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ClinicLocation, ClinicLocation>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ClinicLocation, ClinicLocation>,
              ClinicLocation,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
