import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'program_status_control.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';

class ProgramDetailHeader extends ConsumerWidget {
  const ProgramDetailHeader({super.key, required this.program});
  final PatientProgram program;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final cs = Theme.of(context).colorScheme;
    final title = program.affectedRegions.isEmpty
        ? AppStrings.program
        : program.affectedRegions.map((r) => r.displayName).join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headingLarge.copyWith(color: cs.onSurface)),
          const SizedBox(height: AppSizes.p6),
          Text(
            AppStrings.createdLabel(Formatters.formatDateMedium(program.createdAt)),
            style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: AppSizes.p12),
          Wrap(
            spacing: AppSizes.p12,
            runSpacing: AppSizes.p8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ProgramStatusControl(program: program),
              if (user?.isActive == true && user?.isSeniorDoctor == true)
                TextButton.icon(
                  style: TextButton.styleFrom(minimumSize: const Size(AppSizes.tappableMin, AppSizes.tappableMin)),
                  icon: const Icon(Icons.edit_outlined, size: AppSizes.iconSmall),
                  label: const Text(AppStrings.editProgramDetails, style: AppTextStyles.bodyMedium),
                  onPressed: () {
                    final current = ref.read(currentUserProvider).value;
                    if (current?.isActive != true || current?.isSeniorDoctor != true) return;
                    context.push(
                      AppRoutes.editPatientProgram
                          .replaceAll(':id', program.patientId)
                          .replaceAll(':programId', program.id),
                      extra: program,
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
