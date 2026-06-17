/// Patient list screen — Medics UI redesign.
///
/// Clean layout: search bar, outlined sort chip + filter chip,
/// paginated list of [PatientListTile] rows with inset dividers.
/// Pull-to-refresh and infinite scroll. No legacy chrome.
///
/// Rule 1 — under 200 lines.
/// Rule 3 — all state via Riverpod.
/// Rule 12 — search debounce via AppSearchBar (300ms).
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart'
    show AppException, UnknownException;
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_list_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/unified_filter_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_search_bar.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/sort_filter_bar.dart';
import 'package:spine_clinic_app/shared/widgets/sort_options_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/active_filter_chips_row.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';

import 'package:spine_clinic_app/shared/widgets/patient_list_tile.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_search_filters.dart';

/// A searchable, filterable, sortable, paginated patient roster.
class PatientListScreen extends ConsumerStatefulWidget {
  /// Creates a [PatientListScreen].
  const PatientListScreen({super.key});

  @override
  ConsumerState<PatientListScreen> createState() =>
      _PatientListScreenState();
}

enum PatientSortOption {
  nameAsc,
  nameDesc,
  lastVisitNewest,
  lastVisitOldest,
  dateAddedNewest;

  String get displayLabel => switch (this) {
    PatientSortOption.nameAsc => 'Name (A → Z)',
    PatientSortOption.nameDesc => 'Name (Z → A)',
    PatientSortOption.lastVisitNewest => 'Last Visit (Newest)',
    PatientSortOption.lastVisitOldest => 'Last Visit (Oldest)',
    PatientSortOption.dateAddedNewest => 'Date Added (Newest)',
  };

  String get buttonLabel => switch (this) {
    PatientSortOption.nameAsc => 'Name A→Z',
    PatientSortOption.nameDesc => 'Name Z→A',
    PatientSortOption.lastVisitNewest => 'Last Visit (Newest)',
    PatientSortOption.lastVisitOldest => 'Last Visit (Oldest)',
    PatientSortOption.dateAddedNewest => 'Date Added',
  };
}

class _PatientListScreenState extends ConsumerState<PatientListScreen> {
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(patientListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String query) {
    ref.read(patientListProvider.notifier).searchNow(query);
  }

  Future<void> _onRefresh() async {
    await ref.read(patientListProvider.notifier).refresh();
  }

  PatientSortOption get _currentSort {
    final n = ref.read(patientListProvider.notifier);
    if (n.orderBy == 'last_appointment_date') {
      return n.isAscending
          ? PatientSortOption.lastVisitOldest
          : PatientSortOption.lastVisitNewest;
    }
    if (n.orderBy == 'created_at') {
      return PatientSortOption.dateAddedNewest;
    }
    // full_name (default)
    return n.isAscending
        ? PatientSortOption.nameAsc
        : PatientSortOption.nameDesc;
  }

  String get _sortButtonLabel => _currentSort.buttonLabel;

  /// Sort patients client-side when sorting by last visit date
  /// (the column doesn't exist in the DB — same pattern as MyPatientsScreen).
  List<Patient> _sorted(List<Patient> patients) {
    final sort = _currentSort;
    if (sort != PatientSortOption.lastVisitNewest &&
        sort != PatientSortOption.lastVisitOldest) {
      return patients;
    }
    final list = List<Patient>.from(patients);
    final bool newest = sort == PatientSortOption.lastVisitNewest;
    list.sort((a, b) {
      if (a.lastAppointmentDate == null && b.lastAppointmentDate == null) return 0;
      if (a.lastAppointmentDate == null) return 1;
      if (b.lastAppointmentDate == null) return -1;
      return newest
          ? b.lastAppointmentDate!.compareTo(a.lastAppointmentDate!)
          : a.lastAppointmentDate!.compareTo(b.lastAppointmentDate!);
    });
    return list;
  }

  Future<void> _showSortSheet() async {
    final currentSort = _currentSort;
    final selected = await SortOptionsSheet.show<PatientSortOption>(
      context: context,
      title: 'Sort Options',
      options: PatientSortOption.values
          .map((o) => SortOption(
                value: o,
                label: o.displayLabel,
                buttonLabel: o.buttonLabel,
              ))
          .toList(),
      selected: currentSort,
    );
    if (selected != null && mounted) {
      final (String orderBy, bool ascending) = switch (selected) {
        PatientSortOption.nameAsc => ('full_name', true),
        PatientSortOption.nameDesc => ('full_name', false),
        PatientSortOption.lastVisitNewest => ('last_appointment_date', false),
        PatientSortOption.lastVisitOldest => ('last_appointment_date', true),
        PatientSortOption.dateAddedNewest => ('created_at', false),
      };
      ref.read(patientListProvider.notifier).setSort(orderBy, ascending);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Patient>> state = ref.watch(patientListProvider);
    final clinicFilter = ref.watch(patientListProvider.notifier).currentClinicFilter;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.p16,
                AppSizes.p12,
                AppSizes.p16,
                AppSizes.p4,
              ),
              child: AppSearchBar(
                hintText: AppStrings.searchPatients,
                onChanged: _onSearchChanged,
              ),
            ),

            // ── Branch Filter Chips ──
            PatientSearchFilters(
              selectedClinic: clinicFilter,
              onClinicSelected: (clinic) {
                ref.read(patientListProvider.notifier).setClinicFilter(clinic);
              },
            ),
            const SizedBox(height: AppSizes.p4),

            // ── Sort + Filter buttons row ──
            SortFilterBar(
              sortLabel: 'Sort: $_sortButtonLabel',
              onSortTap: _showSortSheet,
              activeFilterCount: _activeChips.length,
              onFilterTap: _showPatientFilterSheet,
            ),

            // ── Active filter chips row ──
            ActiveFilterChipsRow(
              chips: _activeChips,
              onClearAll: () {
                ref.read(patientListProvider.notifier)
                  ..setDoctorFilter(null)
                  ..setClinicFilter(null);
              },
            ),

            // ── List ──
            Expanded(
              child: state.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSizes.p16),
                  child: SkeletonTileList(count: 8),
                ),
                error: (Object error, StackTrace _) {
                  final AppException ex = error is AppException
                      ? error
                      : UnknownException(message: error.toString());
                  return ErrorView(
                    exception: ex,
                    onRetry: _onRefresh,
                  );
                },
                data: (List<Patient> rawPatients) {
                  final patients = _sorted(rawPatients);
                  if (patients.isEmpty) {
                    final notifier = ref.read(patientListProvider.notifier);
                    final query = notifier.currentQuery;
                    final hasClinicFilter = notifier.currentClinicFilter != null;

                    return EmptyState(
                      message: AppStrings.noPatients,
                      icon: Icons.people_outline_rounded,
                      secondaryMessage: query.isNotEmpty
                          ? 'No results for "$query"'
                          : AppStrings.searchPatients,
                      actionLabel: (query.isNotEmpty && hasClinicFilter)
                          ? 'Search in all branches'
                          : null,
                      onActionPressed: (query.isNotEmpty && hasClinicFilter)
                          ? () => ref.read(patientListProvider.notifier).setClinicFilter(null)
                          : null,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: AppColors.primary,
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.only(
                        left: AppSizes.p16,
                        right: AppSizes.p16,
                        top: AppSizes.p4,
                        bottom: AppSizes.p48,
                      ),
                      itemCount: patients.length + 1,
                      itemBuilder: (_, int index) {
                        if (index == patients.length) {
                          return _buildLoadMore();
                        }
                        final Patient p = patients[index];
                        return PatientListTile(
                          name: p.fullName,
                          phone: p.phoneNumber,
                          branchLabel: p.clinic.displayLabel,
                          lastVisitDate: p.lastAppointmentDate,
                          onTap: () => context.push(
                            AppRoutes.patientDetail
                                .replaceAll(':id', p.id),
                          ),
                        ).animate().fadeIn(
                              duration: 300.ms,
                              delay: (index * 40).ms,
                            );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.newPatient),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showPatientFilterSheet() {
    final notifier = ref.read(patientListProvider.notifier);

    AppBottomSheet.show(
      context: context,
      title: 'Filters',
      builder: (context, scrollController) => UnifiedFilterSheet(
        initialDoctorId: notifier.currentDoctorFilter,
        initialClinic: notifier.currentClinicFilter,
        scrollController: scrollController,
        onApplied: (String? doctorId, ClinicLocation? clinic) {
          if (doctorId != notifier.currentDoctorFilter) {
            notifier.setDoctorFilter(doctorId);
          }
          if (clinic != notifier.currentClinicFilter) {
            notifier.setClinicFilter(clinic);
          }
          Navigator.of(context).pop();
        },
        onReset: () {
          notifier.setDoctorFilter(null);
          notifier.setClinicFilter(null);
        },
      ),
    );
  }

  List<ActiveFilterChip> get _activeChips {
    final chips = <ActiveFilterChip>[];
    final n = ref.read(patientListProvider.notifier);
    if (n.currentDoctorFilter != null) {
      final doctors = ref.watch(activeDoctorsProvider).value ?? [];
      final doctor = doctors.cast<Staff?>().firstWhere(
            (d) => d!.id == n.currentDoctorFilter,
            orElse: () => null,
          );
      chips.add(ActiveFilterChip(
        label: doctor?.fullName ?? 'Doctor',
        onRemove: () => n.setDoctorFilter(null),
      ));
    }
    return chips;
  }

  Widget _buildLoadMore() {
    final n = ref.read(patientListProvider.notifier);
    if (!n.hasMore) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.all(AppSizes.p16),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
