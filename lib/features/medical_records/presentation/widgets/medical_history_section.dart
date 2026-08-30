library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_history_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/edit_medical_history_sheet.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/medical_history_content.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/eyebrow_label.dart';

/// Renders the patient's medical history section in the patient profile.
class MedicalHistorySection extends ConsumerWidget {
  const MedicalHistorySection({super.key, required this.patientId});

  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final bool canEdit = user?.isSeniorDoctor ?? false;
    final historyAsync = ref.watch(patientMedicalHistoryProvider(patientId));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EyebrowLabel(
            text: AppStrings.medicalHistory,
            action: canEdit
                ? TextButton.icon(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: AppSizes.iconSmall,
                    ),
                    label: Text(
                      historyAsync.value?.hasAnyCondition == true
                          ? AppStrings.edit
                          : AppStrings.add,
                      style: AppTextStyles.captionBold,
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p8,
                      ),
                      minimumSize: const Size(0, AppSizes.buttonHeightSmall),
                    ),
                    onPressed: () => EditMedicalHistorySheet.show(
                      context,
                      patientId: patientId,
                      initialHistory: historyAsync.value,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: AppSizes.p8),
          historyAsync.when(
            loading: () => const MedicalHistorySkeleton(),
            error: (err, _) => ErrorView(
              exception: err is AppException
                  ? err
                  : AppException.fromSupabaseException(err),
              onRetry: () => ref
                  .read(patientMedicalHistoryProvider(patientId).notifier)
                  .refresh(),
            ),
            data: (history) => MedicalHistoryContent(
              history: history,
              canEdit: canEdit,
              patientId: patientId,
            ),
          ),
        ],
      ),
    );
  }
}
