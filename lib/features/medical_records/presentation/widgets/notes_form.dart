import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/add_visit_notes_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/app_text_field.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

/// Renders the note-taking and completing form for an appointment.
class NotesForm extends ConsumerStatefulWidget {
  /// Creates a [NotesForm].
  const NotesForm({
    super.key,
    required this.appointment,
    required this.note,
    required this.appointmentId,
  });

  /// The appointment to modify notes for.
  final Appointment appointment;

  /// The optional existing patient note.
  final PatientNote? note;

  /// The appointment's unique ID.
  final String appointmentId;

  @override
  ConsumerState<NotesForm> createState() => _NotesFormState();
}

class _NotesFormState extends ConsumerState<NotesForm> {
  late final TextEditingController _notesController;
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
          message: 'Notes saved successfully.',
          variant: AppSnackbarVariant.success,
        );
      }
    } catch (e) {
      if (mounted) {
        final String errorMsg = e is AppException ? e.message : e.toString();
        AppSnackbar.show(
          context,
          message: 'Failed to save notes: $errorMsg',
          variant: AppSnackbarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleComplete() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(
        title: AppStrings.markAsCompleted,
        message: AppStrings.confirmMarkComplete,
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(addVisitNotesControllerProvider(widget.appointmentId).notifier)
          .completeAppointment(_notesController.text.trim());
      if (mounted) {
        AppSnackbar.show(
          context,
          message: 'Appointment completed.',
          variant: AppSnackbarVariant.success,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final String errorMsg = e is AppException ? e.message : e.toString();
        AppSnackbar.show(
          context,
          message: 'Failed to complete appointment: $errorMsg',
          variant: AppSnackbarVariant.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canComplete = widget.appointment.status == AppointmentStatus.checkedIn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _notesController,
          labelText: AppStrings.notes,
          hintText: 'Enter visit progress notes...',
          maxLines: 8,
          enabled: !_isSaving,
        ),
        const SizedBox(height: AppSizes.p24),
        AppButton(
          labelText: 'Save Notes',
          onPressed: _isSaving ? null : _handleSave,
          isLoading: _isSaving && !canComplete,
          debounceMs: 1000,
        ),
        if (canComplete) ...[
          const SizedBox(height: AppSizes.p12),
          AppButton(
            labelText: AppStrings.markComplete,
            onPressed: _isSaving ? null : _handleComplete,
            isLoading: _isSaving && canComplete,
            variant: AppButtonVariant.secondary,
            debounceMs: 1000,
          ),
        ],
      ],
    );
  }
}
