import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/add_visit_notes_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/app_text_field.dart';
import 'package:spine_clinic_app/shared/widgets/pain_severity_slider.dart';

/// Renders the note-taking and completing form for an appointment.
class NotesForm extends ConsumerStatefulWidget {
  /// Creates a [NotesForm].
  const NotesForm({super.key, required this.note, required this.appointmentId});

  /// The optional existing patient note.
  final PatientNote? note;

  /// The appointment's unique ID.
  final String appointmentId;

  @override
  ConsumerState<NotesForm> createState() => _NotesFormState();
}

class _NotesFormState extends ConsumerState<NotesForm> {
  late final TextEditingController _notesController;
  int _painScore = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.note?.noteText ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(addVisitNotesControllerProvider(widget.appointmentId).notifier)
          .saveNotes(_notesController.text.trim());
      if (mounted) {
        AppSnackbar.show(
          context,
          message: AppStrings.notesSavedSuccess,
          variant: AppSnackbarVariant.success,
        );
      }
    } catch (e) {
      if (mounted) {
        final String errorMsg = e is AppException ? e.message : e.toString();
        AppSnackbar.show(
          context,
          message: '${AppStrings.notesSaveFailed}: $errorMsg',
          variant: AppSnackbarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PainSeveritySlider(
          value: _painScore,
          onChanged: (int score) => setState(() => _painScore = score),
        ),
        const SizedBox(height: AppSizes.p20),
        AppTextField(
          controller: _notesController,
          labelText: AppStrings.notes,
          hintText: AppStrings.visitNotesHint,
          maxLines: 8,
          enabled: !_isSaving,
        ),
        const SizedBox(height: AppSizes.p24),
        AppButton(
          labelText: AppStrings.saveNotes,
          onPressed: _isSaving ? null : _handleSave,
          isLoading: _isSaving,
          debounceMs: 1000,
        ),
      ],
    );
  }
}
