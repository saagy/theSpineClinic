/// Bottom sheet for the Quick Action "Add Note" with a compact note editor.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_records_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_notes_list_notifier.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

/// Bottom sheet for adding or editing a patient note.
class AddNoteSheet extends ConsumerStatefulWidget {
  const AddNoteSheet({
    super.key,
    required this.patientId,
    this.initialText,
    this.noteId,
    this.appointmentId,
  });
  final String patientId;
  final String? initialText;
  final String? noteId;
  final String? appointmentId;

  bool get isEditing => noteId != null;

  @override
  ConsumerState<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends ConsumerState<AddNoteSheet> {
  late final _ctrl = TextEditingController(text: widget.initialText ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      AppSnackbar.show(
        context,
        message: AppStrings.cannotSaveEmptyNote,
        variant: AppSnackbarVariant.error,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      // When an appointmentId is available, delegate to the
      // appointment-scoped notifier which is always mounted because
      // AppointmentNotesCard watches it. Using patientNotesNotifierProvider
      // here fails silently — ref.read creates no listener, so ref.mounted
      // returns false inside the notifier and the save is skipped.
      if (widget.appointmentId != null) {
        await ref
            .read(appointmentNoteProvider(widget.appointmentId!).notifier)
            .saveNote(noteText: text, patientId: widget.patientId);
      } else if (widget.isEditing) {
        await ref
            .read(patientNotesNotifierProvider(widget.patientId).notifier)
            .updateExistingNote(noteId: widget.noteId!, noteText: text);
      } else {
        await ref
            .read(patientNotesNotifierProvider(widget.patientId).notifier)
            .addNote(noteText: text, appointmentId: widget.appointmentId);
      }
      if (mounted) {
        ref.invalidate(patientNotesListProvider(widget.patientId));
        ref.invalidate(patientNotesNotifierProvider(widget.patientId));
        if (widget.appointmentId != null) {
          ref.invalidate(appointmentNoteProvider(widget.appointmentId!));
        }
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnackbar.show(
          context,
          message: AppStrings.errorUnknown,
          variant: AppSnackbarVariant.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.p24,
        AppSizes.p24,
        AppSizes.p24,
        AppSizes.p24 + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.isEditing ? AppStrings.editNotesTooltip : AppStrings.addNote,
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: AppSizes.p16),
          TextField(
            controller: _ctrl,
            minLines: 4,
            maxLines: 6,
            textAlignVertical: TextAlignVertical.top,
            keyboardType: TextInputType.multiline,
            enabled: !_saving,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: AppStrings.notes,
              hintStyle: AppTextStyles.bodySecondary.copyWith(
                color: cs.onSurfaceVariant,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.all(AppSizes.p12),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSizes.p20),
          AppButton(
            labelText: AppStrings.save,
            onPressed: () => _save(),
            debounceMs: 1000,
            shape: AppButtonShape.pill,
          ),
        ],
      ),
    );
  }
}
