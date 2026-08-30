library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_card.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

/// Tab displaying the list of rehabilitation programs for a patient.
class PatientTabPrograms extends ConsumerWidget {
  const PatientTabPrograms({super.key, required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final bool isSenior = user?.isSeniorDoctor ?? false;
    final programsAsync = ref.watch(patientProgramsProvider(patient.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isSenior)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.p16,
              AppSizes.p12,
              AppSizes.p16,
              AppSizes.p4,
            ),
            child: AppButton(
              labelText: AppStrings.newProgram,
              icon: Icons.add,
              shape: AppButtonShape.pill,
              onPressed: () => context.push(
                AppRoutes.newPatientProgram.replaceAll(':id', patient.id),
                extra: patient,
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(patientProgramsProvider(patient.id).notifier).refresh(),
            child: programsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSizes.p16),
                child: SkeletonTileList(count: 3),
              ),
              error: (err, _) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.p24),
                  child: ErrorView(
                    exception: err is AppException
                        ? err
                        : AppException.fromSupabaseException(err),
                    onRetry: () => ref
                        .read(patientProgramsProvider(patient.id).notifier)
                        .refresh(),
                  ),
                ),
              ),
              data: (programs) {
                if (programs.isEmpty) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSizes.p48),
                      child: EmptyState(
                        message: AppStrings.noProgramsRecorded,
                        icon: Icons.assignment_outlined,
                        actionLabel: isSenior ? AppStrings.newProgram : null,
                        onActionPressed: isSenior
                            ? () => context.push(
                                  AppRoutes.newPatientProgram
                                      .replaceAll(':id', patient.id),
                                  extra: patient,
                                )
                            : null,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(
                    top: AppSizes.p8,
                    bottom: AppSizes.p24,
                  ),
                  itemCount: programs.length,
                  itemBuilder: (context, index) {
                    final program = programs[index];
                    return ProgramCard(
                      program: program,
                      onTap: () => context.push(
                        AppRoutes.patientProgramDetail
                            .replaceAll(':id', patient.id)
                            .replaceAll(':programId', program.id),
                        extra: program,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
