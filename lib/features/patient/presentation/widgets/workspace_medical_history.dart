import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_medical_history.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_history_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/edit_medical_history_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';

class WorkspaceMedicalHistory extends ConsumerWidget {
  const WorkspaceMedicalHistory({super.key, required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = patientMedicalHistoryProvider(patientId);
    final history = ref.watch(provider);
    final canEdit = ref.watch(currentUserProvider).value?.isSeniorDoctor ?? false;

    return RecordSection(
      title: AppStrings.medicalHistory,
      action: canEdit && history.hasValue ? AppStrings.edit : null,
      onAction: () {
        if (ref.read(currentUserProvider).value?.isSeniorDoctor != true) return;
        EditMedicalHistorySheet.show(context, patientId: patientId, initialHistory: history.value);
      },
      child: RecordAsync(
        value: history,
        onRetry: () => ref.invalidate(provider),
        data: (value) => _History(history: value),
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History({this.history});
  final PatientMedicalHistory? history;

  @override
  Widget build(BuildContext context) {
    final h = history;
    final cs = Theme.of(context).colorScheme;
    if (h == null) return const RecordMessage(message: AppStrings.historyNotRecorded);
    if (!h.hasAnyCondition && (h.additionalNotes == null || h.additionalNotes!.trim().isEmpty)) {
      return const RecordMessage(message: AppStrings.noConditionsRecorded);
    }

    final badges = <String>[];
    if (h.hasDiabetes) {
      badges.add(h.hba1cValue?.isNotEmpty == true ? '${AppStrings.diabetes} (${AppStrings.hba1c}: ${h.hba1cValue})' : AppStrings.diabetes);
    }
    if (h.hasHypertension) badges.add(AppStrings.hypertension);
    if (h.hasHyperlipidemia) badges.add(AppStrings.hyperlipidemia);
    if (h.hasRheumatology) {
      badges.add(h.rheumatologyDetails?.isNotEmpty == true ? '${AppStrings.rheumatology} (${h.rheumatologyDetails!})' : AppStrings.rheumatology);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (badges.isNotEmpty)
          Wrap(
            spacing: AppSizes.p8,
            runSpacing: AppSizes.p8,
            children: badges
                .map((b) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p10, vertical: AppSizes.p6),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(AppSizes.r8),
                        border: Border.all(color: cs.outlineVariant.withAlpha(80)),
                      ),
                      child: Text(b, style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface)),
                    ))
                .toList(),
          ),
        if (h.additionalNotes?.trim().isNotEmpty == true) ...[
          if (badges.isNotEmpty) const SizedBox(height: AppSizes.p12),
          Text(h.additionalNotes!.trim(), style: AppTextStyles.bodySecondary.copyWith(color: cs.onSurfaceVariant)),
        ],
      ],
    );
  }
}
