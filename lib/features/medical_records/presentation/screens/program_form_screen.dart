library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/medical_records/domain/condition_catalog.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_repository.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/program_controller.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_clinical_inputs.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_condition_selector.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';
import 'package:spine_clinic_app/shared/widgets/form_page_body.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

part 'program_form_view.dart';

/// Screen for creating a new program (with auto-transition to plan builder) or editing clinical findings.
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
  late List<ConditionCatalog> _selectedConditions;
  List<PlatformFile> _pendingFiles = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.program;
    _examinationController = TextEditingController(text: p?.examination ?? '');
    _imagingNotesController = TextEditingController(text: p?.imagingNotes ?? '');
    _exaggeratingPositionsController = TextEditingController(text: p?.exaggeratingPositions ?? '');
    _relievingPositionsController = TextEditingController(text: p?.relievingPositions ?? '');
    _notesController = TextEditingController(text: p?.notes ?? '');
    _selectedConditions =
        p?.conditions.where((c) => c.condition != null).map((c) => c.condition!).toList() ?? [];
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
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedConditions.isEmpty) {
      AppSnackbar.show(
        context,
        message: AppStrings.selectConditionRequired,
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

    if (widget.program == null) {
      final result = await notifier.createProgram(
        patientId: widget.patientId,
        conditionIds: conditionIds,
        examination: _examinationController.text.trim(),
        imagingNotes: _imagingNotesController.text.trim(),
        exaggeratingPositions: _exaggeratingPositionsController.text.trim(),
        relievingPositions: _relievingPositionsController.text.trim(),
        notes: _notesController.text.trim(),
        pendingAttachments: attachments,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      result.when(
        success: (program) {
          AppSnackbar.show(
            context,
            message: AppStrings.programSaved,
            variant: AppSnackbarVariant.success,
          );
          final targetUrl = AppRoutes.patientProgramDetail
              .replaceAll(':id', widget.patientId)
              .replaceAll(':programId', program.id);
          context.pushReplacement('$targetUrl?openPlan=true', extra: program);
        },
        failure: (e) => AppSnackbar.show(
          context,
          message: AppStrings.fromKey(e.userMessageKey),
          variant: AppSnackbarVariant.error,
        ),
      );
    } else {
      final result = await notifier.updateProgram(
        programId: widget.program!.id,
        patientId: widget.patientId,
        conditionIds: conditionIds,
        examination: _examinationController.text.trim(),
        imagingNotes: _imagingNotesController.text.trim(),
        exaggeratingPositions: _exaggeratingPositionsController.text.trim(),
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
          _close();
        },
        failure: (e) => AppSnackbar.show(
          context,
          message: AppStrings.fromKey(e.userMessageKey),
          variant: AppSnackbarVariant.error,
        ),
      );
    }
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      final program = widget.program;
      context.go(program == null
          ? AppRoutes.patientDetail.replaceAll(':id', widget.patientId)
          : AppRoutes.patientProgramDetail.replaceAll(':id', widget.patientId)
              .replaceAll(':programId', program.id));
    }
  }

  void _mutate(VoidCallback change) => setState(change);

  @override
  Widget build(BuildContext context) => _buildForm(context);
}
