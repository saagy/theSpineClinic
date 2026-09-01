library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_medical_history.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_history_controller.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_history_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/medical_history_toggle_card.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/app_text_field.dart';

/// Modal bottom sheet for senior doctors to edit a patient's medical history.
class EditMedicalHistorySheet extends ConsumerStatefulWidget {
  const EditMedicalHistorySheet({
    super.key,
    required this.patientId,
    this.initialHistory,
    this.scrollController,
  });

  final String patientId;
  final PatientMedicalHistory? initialHistory;
  final ScrollController? scrollController;

  static Future<void> show(
    BuildContext context, {
    required String patientId,
    PatientMedicalHistory? initialHistory,
  }) {
    return AppBottomSheet.show<void>(
      context: context,
      title: AppStrings.editMedicalHistory,
      initialChildSize: 0.85,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) => EditMedicalHistorySheet(
        patientId: patientId,
        initialHistory: initialHistory,
        scrollController: scrollController,
      ),
    );
  }

  @override
  ConsumerState<EditMedicalHistorySheet> createState() =>
      _EditMedicalHistorySheetState();
}

class _EditMedicalHistorySheetState
    extends ConsumerState<EditMedicalHistorySheet> {
  late bool _hasDiabetes;
  late bool _hasHypertension;
  late bool _hasHyperlipidemia;
  late bool _hasRheumatology;

  late final TextEditingController _hba1cController;
  late final TextEditingController _rheumatologyController;
  late final TextEditingController _notesController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final h = widget.initialHistory;
    _hasDiabetes = h?.hasDiabetes ?? false;
    _hasHypertension = h?.hasHypertension ?? false;
    _hasHyperlipidemia = h?.hasHyperlipidemia ?? false;
    _hasRheumatology = h?.hasRheumatology ?? false;

    _hba1cController = TextEditingController(text: h?.hba1cValue ?? '');
    _rheumatologyController =
        TextEditingController(text: h?.rheumatologyDetails ?? '');
    _notesController = TextEditingController(text: h?.additionalNotes ?? '');
  }

  @override
  void dispose() {
    _hba1cController.dispose();
    _rheumatologyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final history = PatientMedicalHistory(
      id: widget.initialHistory?.id ?? '',
      patientId: widget.patientId,
      hasDiabetes: _hasDiabetes,
      hba1cValue: _hasDiabetes ? _hba1cController.text.trim() : null,
      hasHypertension: _hasHypertension,
      hasHyperlipidemia: _hasHyperlipidemia,
      hasRheumatology: _hasRheumatology,
      rheumatologyDetails: _hasRheumatology ? _rheumatologyController.text.trim() : null,
      additionalNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: widget.initialHistory?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await ref.read(medicalHistoryControllerProvider.notifier).saveMedicalHistory(history);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (saved) {
        ref.read(patientMedicalHistoryProvider(widget.patientId).notifier).updateData(saved);
        Navigator.of(context).pop();
        AppSnackbar.show(context, message: AppStrings.medicalHistorySaved, variant: AppSnackbarVariant.success);
      },
      failure: (error) => AppSnackbar.show(context, message: AppStrings.fromKey(error.userMessageKey), variant: AppSnackbarVariant.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p20,
        vertical: AppSizes.p12,
      ),
      children: [
        MedicalHistoryToggleCard(
          title: AppStrings.diabetes,
          value: _hasDiabetes,
          onChanged: (val) => setState(() => _hasDiabetes = val),
          expandedChild: _hasDiabetes
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSizes.p12),
                  child: AppTextField(
                    controller: _hba1cController,
                    labelText: AppStrings.hba1cValue,
                    hintText: AppStrings.hba1cHint,
                  ),
                )
              : null,
        ),
        const SizedBox(height: AppSizes.p12),
        MedicalHistoryToggleCard(
          title: AppStrings.hypertension,
          value: _hasHypertension,
          onChanged: (val) => setState(() => _hasHypertension = val),
        ),
        const SizedBox(height: AppSizes.p12),
        MedicalHistoryToggleCard(
          title: AppStrings.hyperlipidemia,
          value: _hasHyperlipidemia,
          onChanged: (val) => setState(() => _hasHyperlipidemia = val),
        ),
        const SizedBox(height: AppSizes.p12),
        MedicalHistoryToggleCard(
          title: AppStrings.rheumatology,
          value: _hasRheumatology,
          onChanged: (val) => setState(() => _hasRheumatology = val),
          expandedChild: _hasRheumatology
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSizes.p12),
                  child: AppTextField(
                    controller: _rheumatologyController,
                    labelText: AppStrings.rheumatologyDetails,
                    hintText: AppStrings.rheumatologyDetailsHint,
                    maxLines: 2,
                  ),
                )
              : null,
        ),
        const SizedBox(height: AppSizes.p16),
        AppTextField(
          controller: _notesController,
          labelText: AppStrings.additionalMedicalNotes,
          hintText: AppStrings.additionalMedicalNotesHint,
          maxLines: 3,
        ),
        const SizedBox(height: AppSizes.p24),
        AppButton(
          labelText: AppStrings.save,
          isLoading: _isSubmitting,
          onPressed: _handleSave,
        ),
        const SizedBox(height: AppSizes.p24),
      ],
    );
  }
}
