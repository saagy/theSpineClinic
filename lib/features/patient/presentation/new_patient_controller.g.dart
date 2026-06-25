// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_patient_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a fine-grained status for each picked attachment during
/// the [NewPatientController]'s submit loop. Index‑keyed family so
/// the form renders status per row.

@ProviderFor(IndexedAttachmentStatus)
final indexedAttachmentStatusProvider = IndexedAttachmentStatusFamily._();

/// Provides a fine-grained status for each picked attachment during
/// the [NewPatientController]'s submit loop. Index‑keyed family so
/// the form renders status per row.
final class IndexedAttachmentStatusProvider
    extends $NotifierProvider<IndexedAttachmentStatus, AttachmentStatus> {
  /// Provides a fine-grained status for each picked attachment during
  /// the [NewPatientController]'s submit loop. Index‑keyed family so
  /// the form renders status per row.
  IndexedAttachmentStatusProvider._({
    required IndexedAttachmentStatusFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'indexedAttachmentStatusProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$indexedAttachmentStatusHash();

  @override
  String toString() {
    return r'indexedAttachmentStatusProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  IndexedAttachmentStatus create() => IndexedAttachmentStatus();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AttachmentStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AttachmentStatus>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IndexedAttachmentStatusProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$indexedAttachmentStatusHash() =>
    r'0108f879668209e83c3f4ca29536d6f07c1df5d2';

/// Provides a fine-grained status for each picked attachment during
/// the [NewPatientController]'s submit loop. Index‑keyed family so
/// the form renders status per row.

final class IndexedAttachmentStatusFamily extends $Family
    with
        $ClassFamilyOverride<
          IndexedAttachmentStatus,
          AttachmentStatus,
          AttachmentStatus,
          AttachmentStatus,
          int
        > {
  IndexedAttachmentStatusFamily._()
    : super(
        retry: null,
        name: r'indexedAttachmentStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides a fine-grained status for each picked attachment during
  /// the [NewPatientController]'s submit loop. Index‑keyed family so
  /// the form renders status per row.

  IndexedAttachmentStatusProvider call(int index) =>
      IndexedAttachmentStatusProvider._(argument: index, from: this);

  @override
  String toString() => r'indexedAttachmentStatusProvider';
}

/// Provides a fine-grained status for each picked attachment during
/// the [NewPatientController]'s submit loop. Index‑keyed family so
/// the form renders status per row.

abstract class _$IndexedAttachmentStatus extends $Notifier<AttachmentStatus> {
  late final _$args = ref.$arg as int;
  int get index => _$args;

  AttachmentStatus build(int index);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AttachmentStatus, AttachmentStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AttachmentStatus, AttachmentStatus>,
              AttachmentStatus,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

/// Notifier provider handling form submission states for NewPatientScreen.

@ProviderFor(NewPatientController)
final newPatientControllerProvider = NewPatientControllerProvider._();

/// Notifier provider handling form submission states for NewPatientScreen.
final class NewPatientControllerProvider
    extends $AsyncNotifierProvider<NewPatientController, void> {
  /// Notifier provider handling form submission states for NewPatientScreen.
  NewPatientControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newPatientControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newPatientControllerHash();

  @$internal
  @override
  NewPatientController create() => NewPatientController();
}

String _$newPatientControllerHash() =>
    r'8e374063ed125decf3af4ceab69d00aa8bdd95cb';

/// Notifier provider handling form submission states for NewPatientScreen.

abstract class _$NewPatientController extends $AsyncNotifier<void> {
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
