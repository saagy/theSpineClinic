library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_detail_conditions.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_detail_findings.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_detail_header.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

/// Screen displaying comprehensive details of a single rehabilitation program.
class ProgramDetailScreen extends ConsumerWidget {
  const ProgramDetailScreen({
    super.key,
    required this.patientId,
    required this.programId,
    this.initialProgram,
  });

  final String patientId;
  final String programId;
  final PatientProgram? initialProgram;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(programDetailProvider(programId));

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text(AppStrings.programDetails),
      ),
      body: SafeArea(
        child: asyncDetail.when(
          loading: () {
            if (initialProgram != null) {
              return _buildContent(context, initialProgram!);
            }
            return const Padding(
              padding: EdgeInsets.all(AppSizes.p16),
              child: SkeletonTileList(count: 4),
            );
          },
          error: (err, _) {
            if (initialProgram != null) {
              return _buildContent(context, initialProgram!);
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.p24),
                child: ErrorView(
                  exception: err is AppException
                      ? err
                      : AppException.fromSupabaseException(err),
                  onRetry: () =>
                      ref.invalidate(programDetailProvider(programId)),
                ),
              ),
            );
          },
          data: (program) {
            final effectiveProgram = program ?? initialProgram;
            if (effectiveProgram == null) {
              return const EmptyState(
                message: AppStrings.programNotFound,
                icon: Icons.search_off_rounded,
              );
            }
            return _buildContent(context, effectiveProgram);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PatientProgram program) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSizes.formLayoutMaxWidth,
        ),
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.p16),
          children: [
            ProgramDetailHeader(program: program),
            const SizedBox(height: AppSizes.p16),
            ProgramDetailConditions(program: program),
            const SizedBox(height: AppSizes.p16),
            ProgramDetailFindings(program: program),
            const SizedBox(height: AppSizes.p24),
          ],
        ),
      ),
    );
  }
}
