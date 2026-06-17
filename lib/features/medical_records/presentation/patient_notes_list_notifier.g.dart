// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_notes_list_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PatientNotesList)
final patientNotesListProvider = PatientNotesListFamily._();

final class PatientNotesListProvider
    extends $NotifierProvider<PatientNotesList, PatientNotesListState> {
  PatientNotesListProvider._({
    required PatientNotesListFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'patientNotesListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$patientNotesListHash();

  @override
  String toString() {
    return r'patientNotesListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PatientNotesList create() => PatientNotesList();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PatientNotesListState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PatientNotesListState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PatientNotesListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$patientNotesListHash() => r'd04f84c428f75d0838db6150c4e5f8b15fc637cd';

final class PatientNotesListFamily extends $Family
    with
        $ClassFamilyOverride<
          PatientNotesList,
          PatientNotesListState,
          PatientNotesListState,
          PatientNotesListState,
          String
        > {
  PatientNotesListFamily._()
    : super(
        retry: null,
        name: r'patientNotesListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PatientNotesListProvider call(String patientId) =>
      PatientNotesListProvider._(argument: patientId, from: this);

  @override
  String toString() => r'patientNotesListProvider';
}

abstract class _$PatientNotesList extends $Notifier<PatientNotesListState> {
  late final _$args = ref.$arg as String;
  String get patientId => _$args;

  PatientNotesListState build(String patientId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PatientNotesListState, PatientNotesListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PatientNotesListState, PatientNotesListState>,
              PatientNotesListState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
