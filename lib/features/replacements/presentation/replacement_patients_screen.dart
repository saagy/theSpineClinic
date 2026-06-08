import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_badge.dart';
import 'package:spine_clinic_app/shared/widgets/app_search_bar.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Screen displaying patients covered by the active doctor today.
class ReplacementPatientsScreen extends ConsumerStatefulWidget {
  /// Creates a [ReplacementPatientsScreen].
  const ReplacementPatientsScreen({super.key});

  @override
  ConsumerState<ReplacementPatientsScreen> createState() =>
      _ReplacementPatientsScreenState();
}

class _ReplacementPatientsScreenState
    extends ConsumerState<ReplacementPatientsScreen> {
  String _currentQuery = '';

  void _onSearchChanged(String query) {
    setState(() => _currentQuery = query);
    ref.read(replacementPatientsControllerProvider.notifier).search(query);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ReplacementPatientsState> stateAsync =
        ref.watch(replacementPatientsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: stateAsync.when(
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
                .read(replacementPatientsControllerProvider.notifier)
                .search(_currentQuery),
          ),
          data: (ReplacementPatientsState state) {
            // Rule 9 / Req 3: If no replacement records, abort layout and show EmptyState
            if (state.absentDoctors.isEmpty) {
              return const EmptyState(
                message: 'No replacement patients assigned to you today.',
                icon: Icons.people_outline_rounded,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Banners for covering absent doctors ──
                ...state.absentDoctors.map((Staff doctor) => _buildCoveringBanner(doctor)),

                // ── Search bar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.p16,
                    AppSizes.p12,
                    AppSizes.p16,
                    AppSizes.p8,
                  ),
                  child: AppSearchBar(
                    hintText: AppStrings.searchPatients,
                    onChanged: _onSearchChanged,
                  ),
                ),

                // ── List or Empty state for search results ──
                Expanded(
                  child: state.patients.isEmpty
                      ? EmptyState(
                          message: _currentQuery.isEmpty
                              ? 'No replacement patients today'
                              : "No patients found for '$_currentQuery'",
                          icon: _currentQuery.isEmpty
                              ? Icons.group_off_rounded
                              : Icons.person_off_rounded,
                        )
                      : ListView.builder(
                          itemCount: state.patients.length,
                          itemBuilder: (context, index) {
                            final Patient patient = state.patients[index];
                            final String absentDoctorName =
                                state.patientDoctorMap[patient.id] ?? 'Unknown';

                            return DataListTile(
                              title: patient.fullName,
                              subtitle: patient.phoneNumber,
                              leading: AppBadge(
                                label: patient.clinic.displayLabel,
                                textColor: AppColors.info,
                                backgroundColor: AppColors.infoBg,
                              ),
                              trailing: AppBadge(
                                label: 'Covering $absentDoctorName',
                                textColor: AppColors.warning,
                                backgroundColor: AppColors.warningBg,
                              ),
                              onTap: () => context.push('/patient/${patient.id}'),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCoveringBanner(Staff doctor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSizes.p16,
        AppSizes.p16,
        AppSizes.p16,
        0,
      ),
      padding: const EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        border: Border.all(color: AppColors.info.withAlpha(50)),
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r8)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.info,
            size: AppSizes.iconDefault,
          ),
          const SizedBox(width: AppSizes.p12),
          Expanded(
            child: Text(
              'You are covering for ${doctor.fullName} today',
              style: AppTextStyles.bodyBold.copyWith(
                color: AppColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
