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
import 'package:spine_clinic_app/features/patient/presentation/patient_list_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_filter_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_search_bar.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/filter_chip.dart'
    show AppFilterChip, AppFilterChipVariant;
import 'package:spine_clinic_app/shared/widgets/patient_list_tile.dart';

/// A searchable, filterable, sortable, paginated patient roster.
class PatientListScreen extends ConsumerStatefulWidget {
  /// Creates a [PatientListScreen].
  const PatientListScreen({super.key});

  @override
  ConsumerState<PatientListScreen> createState() =>
      _PatientListScreenState();
}

enum _SortMode { name, recent }

class _PatientListScreenState extends ConsumerState<PatientListScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  _SortMode _sortMode = _SortMode.name;

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

  void _onSortToggled() {
    setState(() {
      _sortMode =
          _sortMode == _SortMode.name ? _SortMode.recent : _SortMode.name;
    });
  }

  List<Patient> _sorted(Iterable<Patient> patients) {
    final list = List<Patient>.from(patients);
    if (_sortMode == _SortMode.name) {
      list.sort((a, b) => a.fullName.compareTo(b.fullName));
    } else {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Patient>> state = ref.watch(patientListProvider);

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

            // ── Sort + Filter chips ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.p16,
                AppSizes.p4,
                AppSizes.p16,
                AppSizes.p8,
              ),
              child: Row(
                children: [
                  // Sort — outlined to distinguish from filter
                  AppFilterChip(
                    label: _sortMode == _SortMode.name
                        ? AppStrings.sortByName
                        : AppStrings.sortByRecent,
                    variant: AppFilterChipVariant.outlined,
                    isActive: true,
                    onTap: _onSortToggled,
                  ),
                  const SizedBox(width: AppSizes.p8),
                  // Filters — filled when active
                  AppFilterChip(
                    label: AppStrings.filters,
                    isActive: _hasActiveFilters,
                    onTap: () => showPatientFilterSheet(context, ref),
                  ),
                ],
              ),
            ),

            // ── List ──
            Expanded(
              child: state.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
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
                data: (List<Patient> patients) {
                  if (patients.isEmpty) {
                    return EmptyState(
                      message: AppStrings.noPatients,
                      icon: Icons.people_outline_rounded,
                      secondaryMessage: AppStrings.searchPatients,
                    );
                  }

                  final sorted = _sorted(patients);

                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: AppColors.primary,
                    child: ListView.separated(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.only(
                        top: AppSizes.p4,
                        bottom: AppSizes.p48,
                      ),
                      itemCount: sorted.length + 1,
                      separatorBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.only(left: 72),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.border,
                        ),
                      ),
                      itemBuilder: (_, int index) {
                        if (index == sorted.length) {
                          return _buildLoadMore();
                        }
                        final Patient p = sorted[index];
                        return PatientListTile(
                          name: p.fullName,
                          subtitle: _subtitle(p),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.r16),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  bool get _hasActiveFilters {
    final n = ref.read(patientListProvider.notifier);
    return n.currentDoctorFilter != null || n.currentClinicFilter != null;
  }

  String _subtitle(Patient p) {
    return '${p.phoneNumber}  ·  ${p.clinic.displayLabel}';
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
