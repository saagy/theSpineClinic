import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_data_table.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_filter_sheet.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_list_header.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_mobile_list.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_sort_options.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_table_pagination.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_table_skeleton.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Redesigned Doctor's Assigned Patients screen.
///
/// Features the unified 2026 SaaS layout: responsive data table on desktop,
/// sleek compact list on mobile, and debounced search with filter sheet.
class MyPatientsScreen extends ConsumerStatefulWidget {
  const MyPatientsScreen({super.key});

  @override
  ConsumerState<MyPatientsScreen> createState() => _MyPatientsScreenState();
}

class _MyPatientsScreenState extends ConsumerState<MyPatientsScreen> {
  final ScrollController _mobileScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _mobileScrollCtrl.addListener(_onMobileScroll);
  }

  @override
  void dispose() {
    _mobileScrollCtrl.dispose();
    super.dispose();
  }

  void _onMobileScroll() {
    if (_mobileScrollCtrl.position.pixels >=
        _mobileScrollCtrl.position.maxScrollExtent - 200) {
      final notifier = ref.read(myPatientsControllerProvider.notifier);
      if (notifier.hasMore) {
        notifier.loadMore();
      }
    }
  }

  Future<void> _openFilters() async {
    final notifier = ref.read(myPatientsControllerProvider.notifier);
    final result = await PatientFilterSheet.show(
      context: context,
      clinic: notifier.currentClinicFilter,
      doctorId: null,
      sort: PatientSortOption.fromParams(notifier.orderBy, notifier.isAscending),
      canFilterDoctor: false,
    );

    if (result != null && mounted) {
      final (orderBy, ascending) = result.sortOption.sortParams;
      ref.read(myPatientsControllerProvider.notifier)
        ..setClinicFilter(result.clinic)
        ..setSort(orderBy, ascending);
    }
  }

  void _onPatientTap(Patient p) {
    context.push(AppRoutes.patientDetail.replaceAll(':id', p.id));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myPatientsControllerProvider);
    final notifier = ref.watch(myPatientsControllerProvider.notifier);
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    final int activeFiltersCount = notifier.currentClinicFilter != null ? 1 : 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            PatientListHeader(
              totalCount: notifier.totalCount,
              searchQuery: notifier.currentQuery,
              onSearchChanged: (q) => ref.read(myPatientsControllerProvider.notifier).searchNow(q),
              onFilterTap: _openFilters,
              activeFiltersCount: activeFiltersCount,
              canCreatePatient: false,
              onNewPatientTap: () {},
            ),
            Expanded(
              child: state.when(
                loading: () => PatientTableSkeleton(isDesktop: isDesktop),
                error: (error, _) {
                  final ex = error is AppException
                      ? error
                      : UnknownException(message: error.toString());
                  return ErrorView(
                    exception: ex,
                    onRetry: () => ref.read(myPatientsControllerProvider.notifier).refresh(),
                  );
                },
                data: (patients) {
                  if (patients.isEmpty) {
                    final q = notifier.currentQuery;
                    return EmptyState(
                      message: AppStrings.noPatients,
                      icon: LucideIcons.users,
                      secondaryMessage: q.isNotEmpty
                          ? 'No assigned patients for "$q"'
                          : AppStrings.searchPatientsPrompt,
                      actionLabel: q.isNotEmpty && notifier.currentClinicFilter != null
                          ? AppStrings.filterAllBranches
                          : null,
                      onActionPressed: q.isNotEmpty && notifier.currentClinicFilter != null
                          ? () => ref.read(myPatientsControllerProvider.notifier).setClinicFilter(null)
                          : null,
                    );
                  }

                  if (isDesktop) {
                    return Column(
                      children: [
                        Expanded(
                          child: PatientDataTable(
                            patients: patients,
                            onPatientTap: _onPatientTap,
                          ),
                        ),
                        PatientTablePagination(
                          currentPage: notifier.currentPage,
                          totalPages: notifier.totalPages,
                          totalCount: notifier.totalCount,
                          pageSize: notifier.pageSize,
                          hasPrevious: notifier.hasPreviousPage,
                          hasNext: notifier.hasNextPage,
                          onPrevious: () => ref.read(myPatientsControllerProvider.notifier).previousPage(),
                          onNext: () => ref.read(myPatientsControllerProvider.notifier).nextPage(),
                        ),
                      ],
                    );
                  }

                  return PatientMobileList(
                    patients: patients,
                    hasMore: notifier.hasMore,
                    onRefresh: () => ref.read(myPatientsControllerProvider.notifier).refresh(),
                    onPatientTap: _onPatientTap,
                    scrollController: _mobileScrollCtrl,
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
