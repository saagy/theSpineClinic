/// Riverpod providers for the all-appointments management screen.
///
/// Exposes [allAppointmentsProvider] — a notifier that fetches appointments
/// across all doctors and branches with combinable filters, desktop page
/// navigation, and mobile infinite-scroll pagination.
///
/// Rule 3 — all state via Riverpod.
/// Rule 4 — repository calls always return [Result<T>].
/// Rule 12 — patient search debounce is handled by [AppSearchBar] upstream.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_filter_state.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';

export 'package:spine_clinic_app/features/appointment/presentation/all_appointments_filter_state.dart';

part 'all_appointments_data.dart';
part 'all_appointments_filters.dart';

/// AsyncNotifier managing filtered, paginated appointment list for the
/// all-appointments screen.
///
/// Default filter state: current month, all doctors, all branches, all statuses.
/// Pagination: 30 items per page; page navigation on wide screens, infinite scroll on mobile.
final allAppointmentsProvider =
    AsyncNotifierProvider<AllAppointmentsNotifier, List<AppointmentWithPatient>>(
      AllAppointmentsNotifier.new,
    );

/// Notifier holding filter state, pagination state, and re-fetching on every
/// filter or page change.
class AllAppointmentsNotifier extends AllAppointmentsData with AllAppointmentsFilters {
  /// Re-fetches from scratch. Snapshots filter values at call time so
  /// subsequent rapid filter changes cannot corrupt in-flight queries.
  @override
  void _reload({bool silent = false}) {
    final FilterSnapshot snap = _currentSnapshot();
    _generation++;
    final int gen = _generation;
    _offset = 0;
    _totalCount = 0;

    Future.delayed(const Duration(milliseconds: 150), () async {
      if (gen != _generation) return;
      _offset = 0;
      if (!silent && (!state.hasValue || (state.value?.isEmpty ?? true))) {
        state = const AsyncValue.loading();
      }
      try {
        final List<AppointmentWithPatient> data = await _fetch(snap);
        if (gen != _generation) return;
        state = AsyncValue.data(data);
      } catch (err, stack) {
        if (gen != _generation) return;
        state = AsyncValue.error(err, stack);
      }
    });
  }

  /// Navigates directly to [page] (1-based) replacing the current items with
  /// that single page's appointments. Used on wide/desktop screens.
  Future<void> goToPage(int page) async {
    if (page < 1 || page > totalPages) return;
    final int targetOffset = (page - 1) * _pageSize;
    if (_offset == targetOffset && state.hasValue) return;
    _offset = targetOffset;
    _generation++;
    final int gen = _generation;
    final FilterSnapshot snap = _currentSnapshot();
    state = const AsyncValue.loading();
    try {
      final List<AppointmentWithPatient> data = await _fetch(snap);
      if (gen != _generation) return;
      state = AsyncValue.data(data);
    } catch (err, stack) {
      if (gen != _generation) return;
      state = AsyncValue.error(err, stack);
    }
  }

  /// Navigates to the next page.
  Future<void> nextPage() => goToPage(currentPage + 1);

  /// Navigates to the previous page.
  Future<void> previousPage() => goToPage(currentPage - 1);

  /// Appends the next page of results to the current list. Used for mobile infinite scroll.
  Future<void> loadMore() async {
    if (!hasMore || _loadingMore) return;
    _setLoadingMore(true);
    final FilterSnapshot snap = _currentSnapshot();
    final List<AppointmentWithPatient> current = List<AppointmentWithPatient>.from(
      state.value ?? [],
    );
    _offset += _pageSize;
    try {
      final List<AppointmentWithPatient> newItems = await _fetch(snap);
      state = AsyncValue.data([...current, ...newItems]);
    } catch (err, stack) {
      _offset -= _pageSize;
      state = AsyncValue.error(err, stack);
    } finally {
      _setLoadingMore(false);
    }
  }

  void updateStatus(String appointmentId, AppointmentStatus newStatus) {
    if (!state.hasValue) return;
    final List<AppointmentWithPatient> current = state.value!;
    final updated = <AppointmentWithPatient>[];
    for (final item in current) {
      if (item.appointment.id != appointmentId) {
        updated.add(item);
      } else if (status != null && status != newStatus.dbValue) {
        _totalCount = (_totalCount - 1).clamp(0, _totalCount);
      } else {
        updated.add(item.copyWith(appointment: item.appointment.copyWith(status: newStatus)));
      }
    }
    state = AsyncValue.data(updated);
  }

  /// Refreshes the list while preserving all current filter settings.
  void refresh() => _reload(silent: true);

}
