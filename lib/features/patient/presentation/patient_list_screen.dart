/// Patient list screen for receptionist and admin roles.
///
/// Provides debounced search, doctor/branch filters, paginated list,
/// and a FAB for quick patient registration.
///
/// Rule 1 — under 200 lines (sub-widgets extracted).
/// Rule 12 — debounced search via AppSearchBar (300ms built-in).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_list_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_balance_chip.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_list_filters.dart';
import 'package:spine_clinic_app/shared/widgets/app_search_bar.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';

/// Screen displaying a searchable, filterable, paginated patient roster.
class PatientListScreen extends ConsumerStatefulWidget {
  /// Creates a [PatientListScreen].
  const PatientListScreen({super.key});

  @override
  ConsumerState<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends ConsumerState<PatientListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(patientListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String query) {
    // AppSearchBar already debounces 300ms, so call directly.
    ref.read(patientListProvider.notifier).searchNow(query);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar (debounced internally by AppSearchBar)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.p16, AppSizes.p12, AppSizes.p16, AppSizes.p8,
              ),
              child: AppSearchBar(
                hintText: AppStrings.searchPatients,
                onChanged: _onSearchChanged,
              ),
            ),
            // Filter bar
            const PatientListFilters(),
            const SizedBox(height: AppSizes.p8),
            // Results
            Expanded(
              child: state.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: AppSizes.paddingScreenH,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppStrings.errorDatabaseGeneric,
                          style: AppTextStyles.bodySecondary,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSizes.p16),
                        TextButton(
                          onPressed: () => ref
                              .read(patientListProvider.notifier)
                              .refresh(),
                          child: Text(
                            AppStrings.retry,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (patients) {
                  if (patients.isEmpty) {
                    return EmptyState(
                      message: AppStrings.noPatients,
                      icon: Icons.people_outline_rounded,
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: patients.length + 1,
                    itemBuilder: (_, int index) {
                      if (index == patients.length) {
                        return _buildLoadMoreIndicator();
                      }
                      final Patient patient = patients[index];
                      return DataListTile(
                        title: patient.fullName,
                        subtitle:
                            '${patient.phoneNumber} · ${patient.clinic.displayLabel}',
                        trailing: PatientBalanceChip(
                          balance: patient.packageBalance,
                        ),
                        onTap: () => context.push(
                          AppRoutes.patientDetail.replaceAll(':id', patient.id),
                        ),
                      );
                    },
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
        child: const Icon(Icons.add, color: AppColors.textOnPrimary),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    final notifier = ref.read(patientListProvider.notifier);
    if (!notifier.hasMore) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.all(AppSizes.p16),
      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}
