library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/medical_records/domain/condition_catalog.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_repository.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/program_controller.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_clinical_inputs.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_condition_selector.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

/// Screen for creating a new program or editing an existing one.
class ProgramFormScreen extends ConsumerStatefulWidget {
  const ProgramFormScreen({
    super.key,
    required this.patientId,
    this.program,
  });

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
  late List<ConditionCatalog> _selectedConditions;
  List<PlatformFile> _pendingFiles = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.program;
    _examinationController = TextEditingController(text: p?.examination ?? '');
    _imagingNotesController =
        TextEditingController(text: p?.imagingNotes ?? '');
    _exaggeratingPositionsController =
        TextEditingController(text: p?.exaggeratingPositions ?? '');
    _relievingPositionsController =
        TextEditingController(text: p?.relievingPositions ?? '');
    _notesController = TextEditingController(text: p?.notes ?? '');
    _selectedConditions = p?.conditions
            .where((c) => c.condition != null)
            .map((c) => c.condition!)
            .toList() ??
        [];
  }

  @override
  void dispose() {
    _examinationController.dispose();
    _imagingNotesController.dispose();
    _exaggeratingPositionsController.dispose();
    _relievingPositionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedConditions.isEmpty) {
      AppSnackbar.show(
        context,
        message: 'Please select at least one condition/injury.',
        variant: AppSnackbarVariant.info,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final notifier = ref.read(programControllerProvider.notifier);
    final conditionIds = _selectedConditions.map((c) => c.id).toList();

    final attachments = _pendingFiles
        .where((f) => f.bytes != null)
        .map((f) => ProgramAttachment(fileName: f.name, bytes: f.bytes!))
        .toList();

    final result = widget.program == null
        ? await notifier.createProgram(
            patientId: widget.patientId,
            conditionIds: conditionIds,
            examination: _examinationController.text.trim(),
            imagingNotes: _imagingNotesController.text.trim(),
            exaggeratingPositions:
                _exaggeratingPositionsController.text.trim(),
            relievingPositions: _relievingPositionsController.text.trim(),
            notes: _notesController.text.trim(),
            pendingAttachments: attachments,
          )
        : await notifier.updateProgram(
            programId: widget.program!.id,
            patientId: widget.patientId,
            conditionIds: conditionIds,
            examination: _examinationController.text.trim(),
            imagingNotes: _imagingNotesController.text.trim(),
            exaggeratingPositions:
                _exaggeratingPositionsController.text.trim(),
            relievingPositions: _relievingPositionsController.text.trim(),
            notes: _notesController.text.trim(),
            pendingAttachments: attachments,
          );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (_) {
        AppSnackbar.show(
          context,
          message: AppStrings.programSaved,
          variant: AppSnackbarVariant.success,
        );
        context.pop();
      },
      failure: (e) => AppSnackbar.show(
        context,
        message: AppStrings.fromKey(e.userMessageKey),
        variant: AppSnackbarVariant.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.program != null;
    final programId = widget.program?.id;
    final existingDocs = programId != null
        ? ref.watch(programDocumentsProvider(
            patientId: widget.patientId,
            programId: programId,
          )).value ?? []
        : const [];

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(isEdit ? AppStrings.editProgram : AppStrings.newProgram),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSizes.p16),
            children: [
              ProgramConditionSelector(
                selectedConditions: _selectedConditions,
                onConditionsChanged: (items) {
                  setState(() => _selectedConditions = items);
                },
              ),
              const SizedBox(height: AppSizes.p16),
              ProgramClinicalInputs(
                examinationController: _examinationController,
                imagingNotesController: _imagingNotesController,
                exaggeratingPositionsController:
                    _exaggeratingPositionsController,
                relievingPositionsController: _relievingPositionsController,
                notesController: _notesController,
                pendingFiles: _pendingFiles,
                existingDocuments: existingDocs.cast(),
                onPendingFilesChanged: (files) {
                  setState(() => _pendingFiles = files);
                },
                onDeleteExistingDocument: (doc) {
                  ref
                      .read(patientDocumentsNotifierProvider(widget.patientId)
                          .notifier)
                      .deleteDocument(doc);
                },
              ),
              const SizedBox(height: AppSizes.p24),
              AppButton(
                labelText: AppStrings.save,
                isLoading: _isSubmitting,
                shape: AppButtonShape.pill,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSizes.p24),
            ],
          ),
        ),
      ),
    );
  }
}
