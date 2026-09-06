import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_list_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_data_table.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_filter_sheet.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_list_header.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_mobile_list.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_sort_options.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_table_pagination.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_table_skeleton.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Redesigned 2026 SaaS Patient Directory screen.
class PatientListScreen extends ConsumerStatefulWidget {
  const PatientListScreen({super.key});

  @override
  ConsumerState<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends ConsumerState<PatientListScreen> {
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
      final notifier = ref.read(patientListProvider.notifier);
      if (notifier.hasMore) {
        notifier.loadMore();
      }
    }
  }

  Future<void> _openFilters() async {
    final notifier = ref.read(patientListProvider.notifier);
    final user = ref.read(currentUserProvider).value;
    final canFilterDoctor = user?.role == UserRole.receptionist ||
        (user?.role == UserRole.doctor && (user?.isSeniorDoctor ?? false)) ||
        user?.role == UserRole.superAdmin;

    final result = await PatientFilterSheet.show(
      context: context,
      clinic: notifier.currentClinicFilter,
      doctorId: notifier.currentDoctorFilter,
      sort: PatientSortOption.fromParams(notifier.orderBy, notifier.isAscending),
      canFilterDoctor: canFilterDoctor,
    );

    if (result != null && mounted) {
      final (orderBy, ascending) = result.sortOption.sortParams;
      ref.read(patientListProvider.notifier).applyFilters(
        clinic: result.clinic, doctorId: result.doctorId, orderBy: orderBy, ascending: ascending,
      );
    }
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
    final state = ref.watch(patientListProvider);
    final user = ref.watch(currentUserProvider).value;
    final notifier = ref.watch(patientListProvider.notifier);
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    final canCreate = user != null &&
        (user.role != UserRole.doctor || user.isSeniorDoctor);

    int activeFiltersCount = 0;
    if (notifier.currentClinicFilter != null) activeFiltersCount++;
    if (notifier.currentDoctorFilter != null) activeFiltersCount++;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            PatientListHeader(
              totalCount: notifier.totalCount,
              searchQuery: notifier.currentQuery,
              onSearchChanged: (q) => ref.read(patientListProvider.notifier).searchNow(q),
              onFilterTap: _openFilters,
              activeFiltersCount: activeFiltersCount,
              canCreatePatient: canCreate,
              onNewPatientTap: () => context.push(AppRoutes.newPatient),
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
                    onRetry: () => ref.read(patientListProvider.notifier).refresh(),
                  );
                },
                data: (patients) {
                  if (patients.isEmpty) {
                    final q = notifier.currentQuery;
                    return EmptyState(
                      message: AppStrings.noPatients,
                      icon: LucideIcons.users,
                      secondaryMessage: q.isNotEmpty
                          ? 'No results for "$q"'
                          : AppStrings.searchPatientsPrompt,
                      actionLabel: q.isNotEmpty && notifier.currentClinicFilter != null
                          ? AppStrings.filterAllBranches
                          : null,
                      onActionPressed: q.isNotEmpty && notifier.currentClinicFilter != null
                          ? () => ref.read(patientListProvider.notifier).setClinicFilter(null)
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
                          onPrevious: () => ref.read(patientListProvider.notifier).previousPage(),
                          onNext: () => ref.read(patientListProvider.notifier).nextPage(),
                        ),
                      ],
                    );
                  }

                  return PatientMobileList(
                    patients: patients,
                    hasMore: notifier.hasMore,
                    onRefresh: () => ref.read(patientListProvider.notifier).refresh(),
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
