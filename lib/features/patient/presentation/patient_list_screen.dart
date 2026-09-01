/// Patient list screen — Medics UI redesign.
///
/// Clean layout: search bar, outlined sort chip + filter chip,
/// paginated list of [PatientListTile] rows with inset dividers.
/// Pull-to-refresh and infinite scroll. Pure server-side pagination & sorting.
///
/// Rule 1 — under 200 lines.
/// Rule 3 — all state via Riverpod.
/// Rule 12 — search debounce via AppSearchBar (300ms).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart'
    show AppException, UnknownException;
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_list_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_search_filters.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_sort_options.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/shared/widgets/active_filter_chips_row.dart';
import 'package:spine_clinic_app/shared/widgets/animated_list_item.dart';
import 'package:spine_clinic_app/shared/widgets/app_search_bar.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/doctor_picker_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/patient_list_tile.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';
import 'package:spine_clinic_app/shared/widgets/sort_filter_bar.dart';

/// A searchable, filterable, sortable, paginated patient roster.
class PatientListScreen extends ConsumerStatefulWidget {
  /// Creates a [PatientListScreen].
  const PatientListScreen({super.key});

  @override
  ConsumerState<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends ConsumerState<PatientListScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  final Set<int> _animatedIndices = <int>{};

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
      final notifier = ref.read(patientListProvider.notifier);
      if (notifier.hasMore) {
        notifier.loadMore();
      }
    }
  }

  PatientSortOption get _currentSort {
    final n = ref.read(patientListProvider.notifier);
    return PatientSortOption.fromParams(n.orderBy, n.isAscending);
  }

  Future<void> _showSortSheet() async {
    final selected = await PatientSortOption.show(context, _currentSort);
    if (selected != null && mounted) {
      final (orderBy, ascending) = selected.sortParams;
      ref.read(patientListProvider.notifier).setSort(orderBy, ascending);
    }
  }

  Future<void> _showPatientFilterSheet() async {
    final notifier = ref.read(patientListProvider.notifier);
    final picked = await DoctorPickerSheet.showSingle(
      context: context,
      selectedDoctorId: notifier.currentDoctorFilter,
      showAllOption: true,
      showDeactivated: true,
      title: AppStrings.filterByDoctor,
    );
    notifier.setDoctorFilter(picked?.id);
  }

  Future<void> _onPatientTap(Patient p) async {
    final user = ref.read(currentUserProvider).value;
    if (user?.role == UserRole.doctor && !(user?.isSeniorDoctor ?? false)) {
      final canAccess = await ref.read(canAccessPatientProvider(p.id).future);
      if (!canAccess) {
        if (mounted) {
          AppSnackbar.show(
            context,
            message: AppStrings.errorDatabasePermissionDenied,
            variant: AppSnackbarVariant.error,
          );
        }
        return;
      }
    }
    if (mounted) {
      context.push(AppRoutes.patientDetail.replaceAll(':id', p.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Patient>> state = ref.watch(patientListProvider);
    final user = ref.watch(currentUserProvider).value;
    if (state.isLoading && state.value == null) {
      _animatedIndices.clear();
    }
    final notifier = ref.watch(patientListProvider.notifier);
    final clinicFilter = notifier.currentClinicFilter;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.p16,
                AppSizes.p12,
                AppSizes.p16,
                AppSizes.p4,
              ),
              child: AppSearchBar(
                hintText: AppStrings.searchPatients,
                onChanged: (q) => ref.read(patientListProvider.notifier).searchNow(q),
              ),
            ),
            PatientSearchFilters(
              selectedClinic: clinicFilter,
              onClinicSelected: (clinic) {
                ref.read(patientListProvider.notifier).setClinicFilter(clinic);
              },
            ),
            const SizedBox(height: AppSizes.p4),
            SortFilterBar(
              sortLabel: 'Sort: ${_currentSort.buttonLabel}',
              onSortTap: _showSortSheet,
              activeFilterCount: _activeChips.length,
              onFilterTap: _showPatientFilterSheet,
            ),
            ActiveFilterChipsRow(
              chips: _activeChips,
              onClearAll: () {
                ref.read(patientListProvider.notifier)
                  ..setDoctorFilter(null)
                  ..setClinicFilter(null);
              },
            ),
            if (state.value != null && !state.isLoading)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.p20,
                  AppSizes.p8,
                  AppSizes.p20,
                  AppSizes.p4,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Total Patients: ${notifier.totalCount}',
                    style: AppTextStyles.captionBold.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
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
                    onRetry: () => ref.read(patientListProvider.notifier).refresh(),
                  );
                },
                data: (List<Patient> patients) {
                  if (patients.isEmpty) {
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
                    onRefresh: () => ref.read(patientListProvider.notifier).refresh(),
                    color: Theme.of(context).colorScheme.primary,
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(
                        left: AppSizes.p16,
                        right: AppSizes.p16,
                        top: AppSizes.p4,
                        bottom: AppSizes.p48,
                      ),
                      itemCount: patients.length + (notifier.hasMore ? 1 : 0),
                      itemBuilder: (_, int index) {
                        if (index >= patients.length) {
                          return Padding(
                            padding: const EdgeInsets.all(AppSizes.p16),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          );
                        }
                        final Patient p = patients[index];
                        return AnimatedListItem(
                          index: index,
                          animatedIndices: _animatedIndices,
                          child: PatientListTile(
                            name: p.fullName,
                            phone: p.phoneNumber,
                            branchLabel: p.clinic.displayLabel,
                            onTap: () => _onPatientTap(p),
                          ),
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
      floatingActionButton: (user != null &&
              (user.role != UserRole.doctor || user.isSeniorDoctor))
          ? FloatingActionButton(
              onPressed: () => context.push(AppRoutes.newPatient),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: const CircleBorder(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  List<ActiveFilterChip> get _activeChips {
    final chips = <ActiveFilterChip>[];
    final n = ref.read(patientListProvider.notifier);
    if (n.currentDoctorFilter != null) {
      final doctors = ref.watch(allDoctorsForFilterProvider).value ?? [];
      final doctor = doctors.cast<Staff?>().firstWhere(
            (d) => d!.id == n.currentDoctorFilter,
            orElse: () => null,
          );
      chips.add(ActiveFilterChip(
        label: doctor?.fullName ?? AppStrings.unknownDoctorFallback,
        onRemove: () => n.setDoctorFilter(null),
      ));
    }
    return chips;
  }
}
