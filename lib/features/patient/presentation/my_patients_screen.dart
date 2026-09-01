import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/my_patients_sort_options.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_search_filters.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/shared/widgets/active_filter_chips_row.dart';
import 'package:spine_clinic_app/shared/widgets/animated_list_item.dart';
import 'package:spine_clinic_app/shared/widgets/app_search_bar.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/patient_list_tile.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';
import 'package:spine_clinic_app/shared/widgets/sort_filter_bar.dart';

/// Screen displaying the paginated roster of patients assigned to the doctor.
class MyPatientsScreen extends ConsumerStatefulWidget {
  /// Creates a [MyPatientsScreen].
  const MyPatientsScreen({super.key});

  @override
  ConsumerState<MyPatientsScreen> createState() => _MyPatientsScreenState();
}

class _MyPatientsScreenState extends ConsumerState<MyPatientsScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  final Set<int> _animatedIndices = <int>{};
  MyPatientSortOption _sortOption = MyPatientSortOption.nameAsc;

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
      ref.read(myPatientsControllerProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String query) {
    _animatedIndices.clear();
    ref.read(myPatientsControllerProvider.notifier).searchNow(query);
  }

  Future<void> _showSortSheet() async {
    final selected = await MyPatientSortOption.show(context, _sortOption);
    if (selected != null && mounted) {
      setState(() {
        _sortOption = selected;
        _animatedIndices.clear();
      });
      ref
          .read(myPatientsControllerProvider.notifier)
          .setSort(selected.orderByColumn, selected.isAscending);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Patient>> assignedPatients =
        ref.watch(myPatientsControllerProvider);
    final notifier = ref.read(myPatientsControllerProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.p16,
                AppSizes.p16,
                AppSizes.p16,
                AppSizes.p4,
              ),
              child: AppSearchBar(
                hintText: AppStrings.searchPatients,
                onChanged: _onSearchChanged,
              ),
            ),
            PatientSearchFilters(
              selectedClinic: notifier.currentClinicFilter,
              onClinicSelected: (clinic) {
                _animatedIndices.clear();
                notifier.setClinicFilter(clinic);
              },
            ),
            const SizedBox(height: AppSizes.p4),
            SortFilterBar(
              sortLabel: 'Sort: ${_sortOption.buttonLabel}',
              onSortTap: _showSortSheet,
              activeFilterCount: notifier.currentClinicFilter != null ? 1 : 0,
              onFilterTap: _showSortSheet,
            ),
            ActiveFilterChipsRow(
              chips: [
                if (notifier.currentClinicFilter != null)
                  ActiveFilterChip(
                    label: notifier.currentClinicFilter!.displayLabel,
                    onRemove: () {
                      _animatedIndices.clear();
                      notifier.setClinicFilter(null);
                    },
                  ),
              ],
              onClearAll: () {
                _animatedIndices.clear();
                notifier.setClinicFilter(null);
              },
            ),
            assignedPatients.when(
              data: (patients) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p16,
                  vertical: AppSizes.p8,
                ),
                child: Text(
                  '${notifier.totalCount} ${notifier.totalCount == 1 ? 'Patient' : 'Patients'}',
                  style: AppTextStyles.bodyBold.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            Expanded(
              child: assignedPatients.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSizes.p16),
                  child: SkeletonTileList(count: 6),
                ),
                error: (error, _) => ErrorView(
                  exception: error is AppException
                      ? error
                      : UnknownException(message: error.toString()),
                  onRetry: () => notifier.refresh(),
                ),
                data: (List<Patient> patients) {
                  if (patients.isEmpty) {
                    return EmptyState(
                      message: notifier.currentQuery.isEmpty
                          ? AppStrings.noAssignedPatientsYet
                          : AppStrings.noPatientsFoundFor(notifier.currentQuery),
                      icon: notifier.currentQuery.isEmpty
                          ? Icons.people_outline_rounded
                          : Icons.person_off_rounded,
                    );
                  }

                  return RefreshIndicator(
                    color: cs.primary,
                    onRefresh: () => notifier.refresh(),
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p16,
                      ),
                      itemCount: patients.length + (notifier.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= patients.length) {
                          return const Padding(
                            padding: EdgeInsets.all(AppSizes.p16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final Patient patient = patients[index];
                        return AnimatedListItem(
                          index: index,
                          animatedIndices: _animatedIndices,
                          child: PatientListTile(
                            name: patient.fullName,
                            phone: patient.phoneNumber,
                            branchLabel: patient.clinic.displayLabel,
                            lastVisitDate: patient.lastAppointmentDate,
                            onTap: () =>
                                context.push('/patient/${patient.id}'),
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
    );
  }
}
