/// Bottom sheet for the Quick Action "Add Note" — auto-focused
/// multi-line text field and save button.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_records_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

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
  final _focus = FocusNode();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.cannotSaveEmptyNote),
          backgroundColor: AppColors.error,
        ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note saved'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSizes.p24, AppSizes.p24, AppSizes.p24, AppSizes.p24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.isEditing ? 'Edit Note' : 'Add Note',
              style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSizes.p16),
          // Constrain the text field height so it doesn't stretch/glitch
          // when the iOS keyboard first appears (Task #4).
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              keyboardType: TextInputType.multiline,
              enabled: !_saving,
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                hintText: 'Type your note here...',
                hintStyle: TextStyle(color: AppColors.textMuted),
                isDense: true,
                contentPadding: EdgeInsets.all(AppSizes.p12),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.p20),
          AppButton(
            labelText: 'Save Note',
            onPressed: () => _save(),
            debounceMs: 1000,
            shape: AppButtonShape.pill,
          ),
        ],
      ),
    );
  }
}
