/// Paginated Riverpod state for booking patient selection.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

part 'booking_patient_search_provider.g.dart';

/// Loads every matching patient a page at a time for booking selection.
@riverpod
class BookingPatientSearch extends _$BookingPatientSearch {
  static const int _pageSize = 30;
  int _offset = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  /// Whether another page can be requested.
  bool get hasMore => _hasMore;

  @override
  Future<List<Patient>> build(String query) async {
    _offset = 0;
    _hasMore = true;
    _isLoadingMore = false;
    return _fetchPage();
  }

  Future<List<Patient>> _fetchPage() async {
    final repo = ref.read(patientRepositoryProvider);
    final String trimmed = query.trim();
    final Result<List<Patient>> result = await repo.getAllPatients(
      query: trimmed.isEmpty ? null : trimmed,
      offset: _offset,
      limit: _pageSize,
    );
    return result.when(
      success: (List<Patient> patients) {
        _hasMore = patients.length == _pageSize;
        return patients;
      },
      failure: (AppException exception) => throw exception,
    );
  }

  /// Appends the next page while preserving the currently visible patients.
  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || state.isLoading) return;
    final List<Patient> current = List<Patient>.from(state.value ?? const []);
    _isLoadingMore = true;
    _offset += _pageSize;
    try {
      final List<Patient> next = await _fetchPage();
      if (!ref.mounted) return;
      state = AsyncValue.data(<Patient>[...current, ...next]);
    } catch (_) {
      _offset -= _pageSize;
    } finally {
      _isLoadingMore = false;
    }
  }
}
