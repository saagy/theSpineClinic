import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
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
    if (h == null) return const RecordMessage(message: AppStrings.historyNotRecorded);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!h.hasAnyCondition) const RecordMessage(message: AppStrings.noConditionsRecorded),
        if (h.hasDiabetes)
          RecordFact(
            label: AppStrings.diabetes,
            value: h.hba1cValue?.isNotEmpty == true ? '${AppStrings.hba1c}: ${h.hba1cValue}' : AppStrings.yes,
          ),
        if (h.hasHypertension) const RecordFact(label: AppStrings.hypertension, value: AppStrings.yes),
        if (h.hasHyperlipidemia) const RecordFact(label: AppStrings.hyperlipidemia, value: AppStrings.yes),
        if (h.hasRheumatology)
          RecordFact(
            label: AppStrings.rheumatology,
            value: h.rheumatologyDetails?.isNotEmpty == true ? h.rheumatologyDetails! : AppStrings.yes,
          ),
        if (h.additionalNotes?.trim().isNotEmpty == true)
          RecordFact(label: AppStrings.additionalMedicalNotes, value: h.additionalNotes!),
      ],
    );
  }
}
