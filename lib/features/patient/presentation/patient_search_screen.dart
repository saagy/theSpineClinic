/// Production patient search screen.
///
/// Provides debounced text search across patient names and phone numbers
/// with optional clinic filter chips. Results are rendered using
/// [DataListTile] with a trailing [PatientBalanceChip].
///
/// Rule 1 — under 200 lines (balance chip extracted to sub-widget).
/// Rule 11 — touch-only interaction patterns.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_balance_chip.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_search_filters.dart';
import 'package:spine_clinic_app/shared/widgets/app_search_bar.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';

/// Search screen for finding patients by name or phone number.
class PatientSearchScreen extends ConsumerStatefulWidget {
  /// Creates a [PatientSearchScreen].
  const PatientSearchScreen({super.key});

  @override
  ConsumerState<PatientSearchScreen> createState() =>
      _PatientSearchScreenState();
}

class _PatientSearchScreenState extends ConsumerState<PatientSearchScreen> {
  ClinicLocation? _selectedClinic;
  String _currentQuery = '';

  void _onSearchChanged(String query) {
    _currentQuery = query;
    ref.read(patientSearchProvider.notifier).search(
      query,
      clinic: _selectedClinic,
    );
  }

  void _onClinicSelected(ClinicLocation? clinic) {
    setState(() => _selectedClinic = clinic);
    // Re-run search with updated clinic filter if query exists.
    if (_currentQuery.isNotEmpty) {
      ref.read(patientSearchProvider.notifier).search(
        _currentQuery,
        clinic: clinic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Patient>> asyncPatients =
        ref.watch(patientSearchProvider);
    final user = ref.watch(currentUserProvider).value;
    final showFab = user != null && user.role != UserRole.doctor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.patients,
          style: AppTextStyles.headingSmall,
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.p16, AppSizes.p12, AppSizes.p16, AppSizes.p8,
            ),
            child: AppSearchBar(
              hintText: AppStrings.searchPatients,
              onChanged: _onSearchChanged,
            ),
          ),

          // ── Clinic filter chips ──
          PatientSearchFilters(
            selectedClinic: _selectedClinic,
            onClinicSelected: _onClinicSelected,
          ),
          const SizedBox(height: AppSizes.p8),

          // ── Results ──
          Expanded(
            child: asyncPatients.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
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
                        onPressed: () => _onSearchChanged(_currentQuery),
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
              data: (List<Patient> patients) {
                // Empty state: differentiate between no-query and no-results.
                if (patients.isEmpty) {
                  return EmptyState(
                    message: _currentQuery.isEmpty
                      ? AppStrings.searchPatientsPrompt
                      : AppStrings.noResults,
                    icon: _currentQuery.isEmpty
                      ? Icons.search_rounded
                      : Icons.person_off_rounded,
                  );
                }
                return ListView.builder(
                  itemCount: patients.length,
                  itemBuilder: (_, int index) {
                    final Patient patient = patients[index];
                    return DataListTile(
                      title: patient.fullName,
                      subtitle:
                        '${patient.phoneNumber} · ${patient.clinic.displayLabel}',
                      trailing: PatientBalanceChip(
                        balance: patient.packageBalance,
                      ),
                      onTap: () {
                        context.push('/patient/${patient.id}');
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: showFab
        ? FloatingActionButton(
            onPressed: () => context.push(AppRoutes.newPatient),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          )
        : null,
    );
  }

}
