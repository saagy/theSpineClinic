import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_badge.dart';
import 'package:spine_clinic_app/shared/widgets/app_search_bar.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Screen displaying the list of patients permanently assigned to the doctor.
class MyPatientsScreen extends ConsumerStatefulWidget {
  /// Creates a [MyPatientsScreen].
  const MyPatientsScreen({super.key});

  @override
  ConsumerState<MyPatientsScreen> createState() => _MyPatientsScreenState();
}

class _MyPatientsScreenState extends ConsumerState<MyPatientsScreen> {
  String _currentQuery = '';

  void _onSearchChanged(String query) {
    setState(() => _currentQuery = query);
    ref.read(myPatientsControllerProvider.notifier).search(query);
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
                AppSizes.p8,
              ),
              child: AppSearchBar(
                hintText: AppStrings.searchPatients,
                onChanged: _onSearchChanged,
              ),
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
                  if (patients.isEmpty) {
                    return EmptyState(
                      message: _currentQuery.isEmpty
                          ? 'No patients assigned to you yet'
                          : "No patients found for '$_currentQuery'",
                      icon: _currentQuery.isEmpty
                          ? Icons.people_outline_rounded
                          : Icons.person_off_rounded,
                    );
                  }

                  return ListView.builder(
                    itemCount: patients.length,
                    itemBuilder: (context, index) {
                      final Patient patient = patients[index];
                      return DataListTile(
                        title: patient.fullName,
                        subtitle: patient.phoneNumber,
                        trailing: AppBadge(
                          label: patient.clinic.displayLabel,
                          textColor: AppColors.info,
                          backgroundColor: AppColors.infoBg,
                        ),
                        onTap: () => context.push('/patient/${patient.id}'),
                      );
                    },
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
