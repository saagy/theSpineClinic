import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_search_bar.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/patient_list_tile.dart';
import 'package:spine_clinic_app/shared/widgets/sort_filter_bar.dart';
import 'package:spine_clinic_app/shared/widgets/sort_options_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/unified_filter_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/active_filter_chips_row.dart';

/// Screen displaying the list of patients permanently assigned to the doctor.
class MyPatientsScreen extends ConsumerStatefulWidget {
  /// Creates a [MyPatientsScreen].
  const MyPatientsScreen({super.key});

  @override
  ConsumerState<MyPatientsScreen> createState() => _MyPatientsScreenState();
}

enum MyPatientSortOption {
  nameAsc,
  nameDesc,
  lastVisitNewest,
  lastVisitOldest;

  String get displayLabel => switch (this) {
    MyPatientSortOption.nameAsc => 'Name (A → Z)',
    MyPatientSortOption.nameDesc => 'Name (Z → A)',
    MyPatientSortOption.lastVisitNewest => 'Last Visit (Newest)',
    MyPatientSortOption.lastVisitOldest => 'Last Visit (Oldest)',
  };

  String get buttonLabel => switch (this) {
    MyPatientSortOption.nameAsc => 'Name A→Z',
    MyPatientSortOption.nameDesc => 'Name Z→A',
    MyPatientSortOption.lastVisitNewest => 'Last Visit ↓',
    MyPatientSortOption.lastVisitOldest => 'Last Visit ↑',
  };
}

class _MyPatientsScreenState extends ConsumerState<MyPatientsScreen> {
  String _currentQuery = '';
  MyPatientSortOption _sortOption = MyPatientSortOption.nameAsc;
  ClinicLocation? _branchFilter;

  void _onSearchChanged(String query) {
    setState(() => _currentQuery = query);
    ref.read(myPatientsControllerProvider.notifier).search(query);
  }

  Future<void> _showSortSheet() async {
    final selected = await SortOptionsSheet.show<MyPatientSortOption>(
      context: context,
      title: 'Sort Options',
      options: MyPatientSortOption.values
          .map((o) => SortOption(
                value: o,
                label: o.displayLabel,
                buttonLabel: o.buttonLabel,
              ))
          .toList(),
      selected: _sortOption,
    );
    if (selected != null && mounted) {
      setState(() => _sortOption = selected);
    }
  }

  List<Patient> _sorted(List<Patient> patients) {
    final list = List<Patient>.from(patients);
    switch (_sortOption) {
      case MyPatientSortOption.nameAsc:
        list.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
      case MyPatientSortOption.nameDesc:
        list.sort((a, b) => b.fullName.toLowerCase().compareTo(a.fullName.toLowerCase()));
      case MyPatientSortOption.lastVisitNewest:
        list.sort((a, b) {
          if (a.lastAppointmentDate == null && b.lastAppointmentDate == null) return 0;
          if (a.lastAppointmentDate == null) return 1;
          if (b.lastAppointmentDate == null) return -1;
          return b.lastAppointmentDate!.compareTo(a.lastAppointmentDate!);
        });
      case MyPatientSortOption.lastVisitOldest:
        list.sort((a, b) {
          if (a.lastAppointmentDate == null && b.lastAppointmentDate == null) return 0;
          if (a.lastAppointmentDate == null) return 1;
          if (b.lastAppointmentDate == null) return -1;
          return a.lastAppointmentDate!.compareTo(b.lastAppointmentDate!);
        });
    }
    return list;
  }

  void _showFilterSheet() {
    AppBottomSheet.show(
      context: context,
      title: 'Filters',
      builder: (ctx, scrollCtrl) => UnifiedFilterSheet(
        initialDoctorId: null,
        initialClinic: _branchFilter,
        showDoctorFilter: false,
        showBranchFilter: true,
        scrollController: scrollCtrl,
        onReset: () {
          setState(() => _branchFilter = null);
          Navigator.of(ctx).pop();
        },
        onApplied: (String? doctorId, ClinicLocation? clinic) {
          setState(() => _branchFilter = clinic);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  List<Patient> _filtered(List<Patient> patients) {
    if (_branchFilter == null) return patients;
    return patients.where((p) => p.clinic == _branchFilter).toList();
  }

  List<ActiveFilterChip> get _activeChips {
    if (_branchFilter == null) return const [];
    return [
      ActiveFilterChip(
        label: _branchFilter!.displayLabel,
        onRemove: () => setState(() => _branchFilter = null),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Patient>> assignedPatients = ref.watch(myPatientsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
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
            SortFilterBar(
              sortLabel: 'Sort: ${_sortOption.buttonLabel}',
              onSortTap: _showSortSheet,
              activeFilterCount: _activeChips.length,
              onFilterTap: _showFilterSheet,
            ),
            ActiveFilterChipsRow(
              chips: _activeChips,
              onClearAll: () => setState(() => _branchFilter = null),
            ),
            assignedPatients.when(
              data: (patients) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p16,
                  vertical: AppSizes.p8,
                ),
                child: Text(
                  '${patients.length} ${patients.length == 1 ? 'Patient' : 'Patients'}',
                  style: AppTextStyles.bodyBold.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            Expanded(
              child: assignedPatients.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
                error: (error, _) => ErrorView(
                  exception: error is AppException
                      ? error
                      : UnknownException(message: error.toString()),
                  onRetry: () => ref
                      .read(myPatientsControllerProvider.notifier)
                      .search(_currentQuery),
                ),
                data: (List<Patient> patients) {
                  final displayPatients = _sorted(_filtered(patients));
                  if (displayPatients.isEmpty) {
                    return EmptyState(
                      message: _currentQuery.isEmpty
                          ? AppStrings.noAssignedPatientsYet
                          : AppStrings.noPatientsFoundFor(_currentQuery),
                      icon: _currentQuery.isEmpty
                          ? Icons.people_outline_rounded
                          : Icons.person_off_rounded,
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async =>
                        ref.invalidate(myPatientsControllerProvider),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.p16),
                      itemCount: displayPatients.length,
                      itemBuilder: (context, index) {
                        final Patient patient = displayPatients[index];
                        return PatientListTile(
                          name: patient.fullName,
                          phone: patient.phoneNumber,
                          branchLabel: patient.clinic.displayLabel,
                          lastVisitDate: patient.lastAppointmentDate,
                          onTap: () =>
                              context.push('/patient/${patient.id}'),
                        );
                    },
                  ),
                  ); // RefreshIndicator close
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
