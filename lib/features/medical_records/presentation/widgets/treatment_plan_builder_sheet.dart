library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/domain/body_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/laterality.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_input.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_target_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_type.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/treatment_plan_controller.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/modality_chip_selector.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/modality_config_card.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/treatment_plan_header_inputs.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/clinical_editor_frame.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

part 'treatment_plan_builder_state.dart';

/// Modal sheet for creating and modifying a treatment plan with modalities and regions.
class TreatmentPlanBuilderSheet extends ConsumerStatefulWidget {
  const TreatmentPlanBuilderSheet({
    super.key,
    required this.programId,
    required this.patientId,
    required this.affectedRegions,
    this.existingPlan,
    this.scrollController,
  });

  final String programId;
  final String patientId;
  final Set<BodyRegion> affectedRegions;
  final TreatmentPlan? existingPlan;
  final ScrollController? scrollController;

  static Future<TreatmentPlan?> show(
    BuildContext context, {
    required String programId,
    required String patientId,
    required Set<BodyRegion> affectedRegions,
    TreatmentPlan? existingPlan,
  }) => AppBottomSheet.show<TreatmentPlan>(
    context: context,
    title: existingPlan != null ? AppStrings.editTreatmentPlan : AppStrings.newTreatmentPlan,
    maxWidth: AppSizes.clinicalContentMaxWidth,
    initialChildSize: 0.85,
    minChildSize: 0.45,
    maxChildSize: AppSizes.sheetMax,
    builder: (ctx, scrollController) => TreatmentPlanBuilderSheet(
      programId: programId,
      patientId: patientId,
      affectedRegions: affectedRegions,
      existingPlan: existingPlan,
      scrollController: scrollController,
    ),
  );

  @override
  ConsumerState<TreatmentPlanBuilderSheet> createState() => _TreatmentPlanBuilderSheetState();
}
