import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_note_actions_controller.dart';

class WorkspaceNoteEditor extends ConsumerStatefulWidget {
  const WorkspaceNoteEditor({super.key, required this.patientId, this.note});
  final String patientId;
  final PatientNote? note;
  static Future<void> show(BuildContext context, String patientId, {PatientNote? note}) => showDialog<void>(
    context: context,
    builder: (_) => WorkspaceNoteEditor(patientId: patientId, note: note),
  );
  @override
  ConsumerState<WorkspaceNoteEditor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<WorkspaceNoteEditor> {
  late final _text = TextEditingController(text: widget.note?.noteText);
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref
        .read(patientNoteActionsControllerProvider.notifier)
        .save(patientId: widget.patientId, text: _text.text.trim(), existing: widget.note);
    if (!mounted) return;
    switch (result) {
      case Success<PatientNote>():
        Navigator.of(context).pop();
      case Failure<PatientNote>(:final exception):
        setState(() {
          _saving = false;
          _error = AppStrings.fromKey(exception.userMessageKey);
        });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text(
        widget.note == null ? AppStrings.addNote : AppStrings.editNotesTooltip,
        style: AppTextStyles.headingMedium,
      ),
      content: SizedBox(
        width: AppSizes.formLayoutMaxWidth,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _text,
                  autofocus: true,
                  enabled: !_saving,
                  minLines: 5,
                  maxLines: 12,
                  style: AppTextStyles.body,
                  decoration: const InputDecoration(
                    labelText: AppStrings.notes,
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? AppStrings.cannotSaveEmptyNote : null,
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSizes.p12),
                    child: Text(
                      _error!,
                      style: AppTextStyles.body.copyWith(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? AppStrings.loading : AppStrings.saveNotes),
        ),
      ],
    ),
  );
}
