library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/medical_records/domain/condition_catalog.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_repository.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/program_controller.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/program_document_draft.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/program_mutation_state.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/program_edit_section.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_imaging_picker.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_clinical_inputs.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_condition_selector.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';
import 'package:spine_clinic_app/shared/widgets/form_page_body.dart';
import 'package:spine_clinic_app/shared/widgets/form_section.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

part 'program_form_view.dart';
part 'program_form_actions.dart';

/// Screen for creating a new program (with auto-transition to plan builder) or editing clinical findings.
class ProgramFormScreen extends ConsumerStatefulWidget {
  const ProgramFormScreen({
    super.key,
    required this.patientId,
    this.program,
    this.initialSection = ProgramEditSection.conditions,
  });
  final String patientId;
  final PatientProgram? program;
  final ProgramEditSection initialSection;

  @override
  ConsumerState<ProgramFormScreen> createState() => _ProgramFormScreenState();
}

class _ProgramFormScreenState extends ConsumerState<ProgramFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _conditionsKey = GlobalKey();
  final _findingsKey = GlobalKey();
  final _documentsKey = GlobalKey();
  late final TextEditingController _examinationController;
  late final TextEditingController _imagingNotesController;
  late final TextEditingController _exaggeratingPositionsController;
  late final TextEditingController _relievingPositionsController;
  late final TextEditingController _notesController;
  late List<ConditionCatalog> _selectedConditions;
  List<PlatformFile> _pendingFiles = [];
  bool _isSubmitting = false;
  late ProviderContainer _draftContainer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _draftContainer = ProviderScope.containerOf(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    final p = widget.program;
    _examinationController = TextEditingController(text: p?.examination ?? '');
    _imagingNotesController = TextEditingController(text: p?.imagingNotes ?? '');
    _exaggeratingPositionsController = TextEditingController(text: p?.exaggeratingPositions ?? '');
    _relievingPositionsController = TextEditingController(text: p?.relievingPositions ?? '');
    _notesController = TextEditingController(text: p?.notes ?? '');
    _selectedConditions = p?.conditions.where((c) => c.condition != null).map((c) => c.condition!).toList() ?? [];
    if (p != null && widget.initialSection != ProgramEditSection.conditions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final target = switch (widget.initialSection) {
          ProgramEditSection.conditions => _conditionsKey,
          ProgramEditSection.findings => _findingsKey,
          ProgramEditSection.documents => _documentsKey,
        };
        final targetContext = target.currentContext;
        if (targetContext != null) Scrollable.ensureVisible(targetContext);
      });
    }
  }

  @override
  void dispose() {
    _draftContainer.invalidate(programDocumentDraftProvider(_formKey));
    _examinationController.dispose();
    _imagingNotesController.dispose();
    _exaggeratingPositionsController.dispose();
    _relievingPositionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _mutate(VoidCallback change) => setState(change);

  @override
  Widget build(BuildContext context) => _buildForm(context);
}
