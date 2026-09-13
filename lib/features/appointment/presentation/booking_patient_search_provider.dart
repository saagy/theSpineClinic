/// Paginated Riverpod state for booking patient selection.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

part 'booking_patient_search_provider.g.dart';

/// Loads every matching patient a page at a time for booking selection.
@riverpod
class BookingPatientSearch extends _$BookingPatientSearch {
  static const int _pageSize = 30;
  ClinicLocation? _clinic;
  int _generation = 0;
  int _offset = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  /// Whether another page can be requested.
  bool get hasMore => _hasMore;

  @override
  Future<List<Patient>> build(String query) async {
    final userFuture = ref.watch(currentUserProvider.future);
    final branch = ref.watch(activeBranchProvider);
    final int generation = ++_generation;
    _offset = 0;
    _hasMore = true;
    _isLoadingMore = false;
    final user = await userFuture;
    if (!ref.mounted || generation != _generation || user == null) return [];
    _clinic = user.role == UserRole.receptionist ? branch : null;
    return _fetchPage(generation);
  }

  Future<List<Patient>> _fetchPage(int generation) async {
    final repo = ref.read(patientRepositoryProvider);
    final String trimmed = query.trim();
    final Result<List<Patient>> result = await repo.getAllPatients(
      query: trimmed.isEmpty ? null : trimmed,
      clinic: _clinic,
      offset: _offset,
      limit: _pageSize,
    );
    return result.when(
      success: (List<Patient> patients) {
        if (ref.mounted && generation == _generation) {
          _hasMore = patients.length == _pageSize;
        }
        return patients;
      },
      failure: (AppException exception) => throw exception,
    );
  }

  /// Appends the next page while preserving the currently visible patients.
  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || state.isLoading) return;
    final List<Patient> current = List<Patient>.from(state.value ?? const []);
    final int generation = _generation;
    _isLoadingMore = true;
    _offset += _pageSize;
    try {
      final List<Patient> next = await _fetchPage(generation);
      if (!ref.mounted || generation != _generation) return;
      state = AsyncValue.data(<Patient>[...current, ...next]);
    } catch (_) {
      if (generation == _generation) _offset -= _pageSize;
    } finally {
      if (generation == _generation) _isLoadingMore = false;
    }
  }
}
