library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/medical_records/domain/condition_catalog.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_input.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_type.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_repository.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan_input.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/program_controller.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_clinical_inputs.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_condition_selector.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_treatment_plan_inputs.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

/// Screen for creating a new program or editing an existing one with inline treatment plan.
class ProgramFormScreen extends ConsumerStatefulWidget {
  const ProgramFormScreen({super.key, required this.patientId, this.program});
  final String patientId;
  final PatientProgram? program;

  @override
  ConsumerState<ProgramFormScreen> createState() => _ProgramFormScreenState();
}

class _ProgramFormScreenState extends ConsumerState<ProgramFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _examinationController;
  late final TextEditingController _imagingNotesController;
  late final TextEditingController _exaggeratingPositionsController;
  late final TextEditingController _relievingPositionsController;
  late final TextEditingController _notesController;
  late final TextEditingController _planNameController;
  late final TextEditingController _planNotesController;
  late List<ConditionCatalog> _selectedConditions;
  late final Map<ModalityType, ModalityInput> _modalityInputs;
  late Set<ModalityType> _selectedModalities;
  List<PlatformFile> _pendingFiles = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.program;
    final activePlan = p?.activePlan;
    _examinationController = TextEditingController(text: p?.examination ?? '');
    _imagingNotesController = TextEditingController(text: p?.imagingNotes ?? '');
    _exaggeratingPositionsController = TextEditingController(text: p?.exaggeratingPositions ?? '');
    _relievingPositionsController = TextEditingController(text: p?.relievingPositions ?? '');
    _notesController = TextEditingController(text: p?.notes ?? '');
    _planNameController = TextEditingController(text: activePlan?.planName ?? 'Plan 1');
    _planNotesController = TextEditingController(text: activePlan?.notes ?? '');
    _selectedConditions = p?.conditions.where((c) => c.condition != null).map((c) => c.condition!).toList() ?? [];

    _modalityInputs = {for (final t in ModalityType.values) t: ModalityInput(modalityType: t)};
    _selectedModalities = {};

    if (activePlan != null) {
      for (final pm in activePlan.modalities) {
        _selectedModalities.add(pm.modalityType);
        _modalityInputs[pm.modalityType] = ModalityInput(
          modalityType: pm.modalityType,
          notes: pm.notes,
          regions: pm.regions.map((r) => RegionInput(targetRegion: r.targetRegion, laterality: r.laterality, timeMinutes: r.timeMinutes)).toList(),
        );
      }
    }
  }

  @override
  void dispose() {
    _examinationController.dispose();
    _imagingNotesController.dispose();
    _exaggeratingPositionsController.dispose();
    _relievingPositionsController.dispose();
    _notesController.dispose();
    _planNameController.dispose();
    _planNotesController.dispose();
    super.dispose();
  }

  TreatmentPlanInput? _buildTreatmentPlanPayload() {
    if (_selectedModalities.isEmpty && _planNotesController.text.trim().isEmpty) return null;
    return TreatmentPlanInput(
      id: widget.program?.activePlan?.id,
      planName: _planNameController.text.trim().isEmpty ? 'Plan 1' : _planNameController.text.trim(),
      isActive: true,
      notes: _planNotesController.text.trim().isEmpty ? null : _planNotesController.text.trim(),
      modalities: _selectedModalities.map((t) => _modalityInputs[t]!).toList(),
    );
  }

  Future<void> _submit() async {
    if (_selectedConditions.isEmpty) {
      AppSnackbar.show(context, message: AppStrings.selectConditionRequired, variant: AppSnackbarVariant.info);
      return;
    }

    setState(() => _isSubmitting = true);
    final notifier = ref.read(programControllerProvider.notifier);
    final conditionIds = _selectedConditions.map((c) => c.id).toList();
    final attachments = _pendingFiles.where((f) => f.bytes != null).map((f) => ProgramAttachment(fileName: f.name, bytes: f.bytes!)).toList();
    final planPayload = _buildTreatmentPlanPayload();

    final result = widget.program == null
        ? await notifier.createProgram(
            patientId: widget.patientId,
            conditionIds: conditionIds,
            examination: _examinationController.text.trim(),
            imagingNotes: _imagingNotesController.text.trim(),
            exaggeratingPositions: _exaggeratingPositionsController.text.trim(),
            relievingPositions: _relievingPositionsController.text.trim(),
            notes: _notesController.text.trim(),
            pendingAttachments: attachments,
            treatmentPlan: planPayload,
          )
        : await notifier.updateProgram(
            programId: widget.program!.id,
            patientId: widget.patientId,
            conditionIds: conditionIds,
            examination: _examinationController.text.trim(),
            imagingNotes: _imagingNotesController.text.trim(),
            exaggeratingPositions: _exaggeratingPositionsController.text.trim(),
            relievingPositions: _relievingPositionsController.text.trim(),
            notes: _notesController.text.trim(),
            pendingAttachments: attachments,
            treatmentPlan: planPayload,
          );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (_) {
        AppSnackbar.show(context, message: AppStrings.programSaved, variant: AppSnackbarVariant.success);
        context.pop();
      },
      failure: (e) => AppSnackbar.show(context, message: AppStrings.fromKey(e.userMessageKey), variant: AppSnackbarVariant.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.program != null;
    final programId = widget.program?.id;
    final existingDocs = programId != null ? ref.watch(programDocumentsProvider(patientId: widget.patientId, programId: programId)).value ?? [] : const [];
    final affectedRegions = _selectedConditions.map((c) => c.region).toSet();

    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), title: Text(isEdit ? AppStrings.editProgram : AppStrings.newProgram)),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p8, AppSizes.p16, AppSizes.p16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppSizes.formLayoutMaxWidth),
                  child: AppButton(labelText: AppStrings.save, isLoading: _isSubmitting, shape: AppButtonShape.pill, onPressed: _submit),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.formLayoutMaxWidth),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.p16),
                children: [
                  ProgramConditionSelector(
                    selectedConditions: _selectedConditions,
                    onConditionsChanged: (items) => setState(() => _selectedConditions = items),
                  ),
                  const SizedBox(height: AppSizes.p16),
                  ProgramClinicalInputs(
                    examinationController: _examinationController,
                    imagingNotesController: _imagingNotesController,
                    exaggeratingPositionsController: _exaggeratingPositionsController,
                    relievingPositionsController: _relievingPositionsController,
                    notesController: _notesController,
                    pendingFiles: _pendingFiles,
                    existingDocuments: existingDocs.cast(),
                    onPendingFilesChanged: (files) => setState(() => _pendingFiles = files),
                    onDeleteExistingDocument: (doc) => ref.read(patientDocumentsNotifierProvider(widget.patientId).notifier).deleteDocument(doc),
                  ),
                  const SizedBox(height: AppSizes.p16),
                  ProgramTreatmentPlanInputs(
                    nameController: _planNameController,
                    notesController: _planNotesController,
                    selectedModalities: _selectedModalities,
                    modalityInputs: _modalityInputs,
                    onModalitiesChanged: (mods) => setState(() => _selectedModalities = mods),
                    onModalityInputChanged: (t, input) => setState(() => _modalityInputs[t] = input),
                    affectedRegions: affectedRegions,
                  ),
                  const SizedBox(height: AppSizes.p24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
