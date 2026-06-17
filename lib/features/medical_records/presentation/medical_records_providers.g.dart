// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medical_records_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a singleton instance of [PatientNotesRepository].

@ProviderFor(patientNotesRepository)
final patientNotesRepositoryProvider = PatientNotesRepositoryProvider._();

/// Provides a singleton instance of [PatientNotesRepository].

final class PatientNotesRepositoryProvider
    extends
        $FunctionalProvider<
          PatientNotesRepository,
          PatientNotesRepository,
          PatientNotesRepository
        >
    with $Provider<PatientNotesRepository> {
  /// Provides a singleton instance of [PatientNotesRepository].
  PatientNotesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'patientNotesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$patientNotesRepositoryHash();

  @$internal
  @override
  $ProviderElement<PatientNotesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PatientNotesRepository create(Ref ref) {
    return patientNotesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PatientNotesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PatientNotesRepository>(value),
    );
  }
}

String _$patientNotesRepositoryHash() =>
    r'564f0ca28b521ad05930ad2350be06c00e989a7c';

/// Fetches all notes associated with a specific patient.

@ProviderFor(patientNotes)
final patientNotesProvider = PatientNotesFamily._();

/// Fetches all notes associated with a specific patient.

final class PatientNotesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PatientNote>>,
          List<PatientNote>,
          FutureOr<List<PatientNote>>
        >
    with
        $FutureModifier<List<PatientNote>>,
        $FutureProvider<List<PatientNote>> {
  /// Fetches all notes associated with a specific patient.
  PatientNotesProvider._({
    required PatientNotesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'patientNotesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$patientNotesHash();

  @override
  String toString() {
    return r'patientNotesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PatientNote>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PatientNote>> create(Ref ref) {
    final argument = this.argument as String;
    return patientNotes(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PatientNotesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$patientNotesHash() => r'462420257907d23c6a7dc5c6bb43e29e29bed335';

/// Fetches all notes associated with a specific patient.

final class PatientNotesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PatientNote>>, String> {
  PatientNotesFamily._()
    : super(
        retry: null,
        name: r'patientNotesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches all notes associated with a specific patient.

  PatientNotesProvider call(String patientId) =>
      PatientNotesProvider._(argument: patientId, from: this);

  @override
  String toString() => r'patientNotesProvider';
}

/// Manages the note linked to a specific appointment.

@ProviderFor(AppointmentNote)
final appointmentNoteProvider = AppointmentNoteFamily._();

/// Manages the note linked to a specific appointment.
final class AppointmentNoteProvider
    extends $AsyncNotifierProvider<AppointmentNote, PatientNote?> {
  /// Manages the note linked to a specific appointment.
  AppointmentNoteProvider._({
    required AppointmentNoteFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'appointmentNoteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$appointmentNoteHash();

  @override
  String toString() {
    return r'appointmentNoteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AppointmentNote create() => AppointmentNote();

  @override
  bool operator ==(Object other) {
    return other is AppointmentNoteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$appointmentNoteHash() => r'91bcaf81da4a5e8353b9b5772052309138c79a70';

/// Manages the note linked to a specific appointment.

final class AppointmentNoteFamily extends $Family
    with
        $ClassFamilyOverride<
          AppointmentNote,
          AsyncValue<PatientNote?>,
          PatientNote?,
          FutureOr<PatientNote?>,
          String
        > {
  AppointmentNoteFamily._()
    : super(
        retry: null,
        name: r'appointmentNoteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Manages the note linked to a specific appointment.

  AppointmentNoteProvider call(String appointmentId) =>
      AppointmentNoteProvider._(argument: appointmentId, from: this);

  @override
  String toString() => r'appointmentNoteProvider';
}

/// Manages the note linked to a specific appointment.

abstract class _$AppointmentNote extends $AsyncNotifier<PatientNote?> {
  late final _$args = ref.$arg as String;
  String get appointmentId => _$args;

  FutureOr<PatientNote?> build(String appointmentId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PatientNote?>, PatientNote?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PatientNote?>, PatientNote?>,
              AsyncValue<PatientNote?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

/// Family notifier managing the patient notes list state.

@ProviderFor(PatientNotesNotifierNotifier)
final patientNotesNotifierProvider = PatientNotesNotifierNotifierFamily._();

/// Family notifier managing the patient notes list state.
final class PatientNotesNotifierNotifierProvider
    extends
        $AsyncNotifierProvider<
          PatientNotesNotifierNotifier,
          List<PatientNote>
        > {
  /// Family notifier managing the patient notes list state.
  PatientNotesNotifierNotifierProvider._({
    required PatientNotesNotifierNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'patientNotesNotifierProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$patientNotesNotifierNotifierHash();

  @override
  String toString() {
    return r'patientNotesNotifierProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PatientNotesNotifierNotifier create() => PatientNotesNotifierNotifier();

  @override
  bool operator ==(Object other) {
    return other is PatientNotesNotifierNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$patientNotesNotifierNotifierHash() =>
    r'41a88cd00e5b1df655c9bcf89bc3d0b59712f709';

/// Family notifier managing the patient notes list state.

final class PatientNotesNotifierNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          PatientNotesNotifierNotifier,
          AsyncValue<List<PatientNote>>,
          List<PatientNote>,
          FutureOr<List<PatientNote>>,
          String
        > {
  PatientNotesNotifierNotifierFamily._()
    : super(
        retry: null,
        name: r'patientNotesNotifierProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Family notifier managing the patient notes list state.

  PatientNotesNotifierNotifierProvider call(String patientId) =>
      PatientNotesNotifierNotifierProvider._(argument: patientId, from: this);

  @override
  String toString() => r'patientNotesNotifierProvider';
}

/// Family notifier managing the patient notes list state.

abstract class _$PatientNotesNotifierNotifier
    extends $AsyncNotifier<List<PatientNote>> {
  late final _$args = ref.$arg as String;
  String get patientId => _$args;

  FutureOr<List<PatientNote>> build(String patientId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<PatientNote>>, List<PatientNote>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<PatientNote>>, List<PatientNote>>,
              AsyncValue<List<PatientNote>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
