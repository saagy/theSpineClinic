import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/features/medical_records/data/patient_notes_repository.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_notes_list_state.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_notes_sort_option.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_records_providers.dart';

part 'patient_notes_list_notifier.g.dart';

@riverpod
class PatientNotesList extends _$PatientNotesList {
  int _generation = 0;
  static const int _pageSize = 30;

  @override
  PatientNotesListState build(String patientId) {
    Future.microtask(() => _fetchFirstPage());
    return const PatientNotesListState(isLoading: true);
  }

  Future<void> _fetchFirstPage() async {
    _generation++;
    final int currentGen = _generation;

    state = state.copyWith(isLoading: true, errorMessage: null);

    final PatientNotesRepository repo = ref.read(patientNotesRepositoryProvider);
    final countResult = await repo.countNotesForPatient(
      patientId: patientId,
      dateFrom: state.dateFrom,
      dateTo: state.dateTo,
    );

    int totalCount = 0;
    countResult.when(
      success: (count) => totalCount = count,
      failure: (_) => totalCount = 0,
    );

    final result = await repo.getNotesForPatientPaginated(
      patientId: patientId,
      offset: 0,
      limit: _pageSize,
      dateFrom: state.dateFrom,
      dateTo: state.dateTo,
      ascending: state.sort == PatientNotesSortOption.dateOldest,
    );

    if (currentGen != _generation) return;

    result.when(
      success: (List<PatientNote> notes) {
        state = state.copyWith(
          notes: notes,
          isLoading: false,
          totalCount: totalCount,
          hasMore: notes.length < totalCount,
        );
      },
      failure: (error) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.message,
        );
      },
    );
  }

  void _reloadDebounced() {
    _generation++;
    final int currentGen = _generation;
    Future.delayed(const Duration(milliseconds: 150), () {
      if (currentGen == _generation) {
        _fetchFirstPage();
      }
    });
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    final PatientNotesRepository repo = ref.read(patientNotesRepositoryProvider);
    final offset = state.notes.length;
    final result = await repo.getNotesForPatientPaginated(
      patientId: patientId,
      offset: offset,
      limit: _pageSize,
      dateFrom: state.dateFrom,
      dateTo: state.dateTo,
      ascending: state.sort == PatientNotesSortOption.dateOldest,
    );

    result.when(
      success: (List<PatientNote> newNotes) {
        final all = [...state.notes, ...newNotes];
        state = state.copyWith(
          notes: all,
          isLoadingMore: false,
          hasMore: all.length < state.totalCount,
        );
      },
      failure: (error) {
        state = state.copyWith(
          isLoadingMore: false,
          errorMessage: error.message,
        );
      },
    );
  }

  Future<void> refresh() async {
    await _fetchFirstPage();
  }

  void setDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(dateFrom: from, dateTo: to);
    _reloadDebounced();
  }

  void setSort(PatientNotesSortOption sort) {
    state = state.copyWith(sort: sort);
    _reloadDebounced();
  }

  void clearFilters() {
    state = state.copyWith(
      dateFrom: null,
      dateTo: null,
    );
    _fetchFirstPage();
  }
}
