import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';
import 'patient_notes_sort_option.dart';

part 'patient_notes_list_state.freezed.dart';

@freezed
abstract class PatientNotesListState with _$PatientNotesListState {
  const factory PatientNotesListState({
    @Default([]) List<PatientNote> notes,
    @Default(true) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default(false) bool hasMore,
    @Default(0) int totalCount,
    String? errorMessage,
    DateTime? dateFrom,
    DateTime? dateTo,
    @Default(PatientNotesSortOption.dateNewest) PatientNotesSortOption sort,
  }) = _PatientNotesListState;
}
