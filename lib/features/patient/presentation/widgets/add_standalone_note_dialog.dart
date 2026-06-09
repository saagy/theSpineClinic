import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Modal dialog overlay to add or edit a standalone clinical note for a patient.
class AddStandaloneNoteDialog extends StatefulWidget {
  /// Creates an [AddStandaloneNoteDialog].
  const AddStandaloneNoteDialog({super.key, required this.onSave, this.initialText});

  /// Callback when saving note content.
  final ValueChanged<String> onSave;

  /// Optional initial text for editing an existing note.
  final String? initialText;

  @override
  State<AddStandaloneNoteDialog> createState() => _AddStandaloneNoteDialogState();
}

class _AddStandaloneNoteDialogState extends State<AddStandaloneNoteDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r12)),
      ),
      backgroundColor: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.initialText != null ? 'Edit Note' : 'Add Standalone Note',
              style: AppTextStyles.headingSmall.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSizes.p16),
            TextField(
              controller: _controller,
              maxLines: 5,
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                hintText: 'Enter clinical findings, patient comments, or standalone notes...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(AppSizes.p12),
              ),
            ),
            const SizedBox(height: AppSizes.p20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: AppSizes.p8),
                ElevatedButton(
                  onPressed: () {
                    final String text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      widget.onSave(text);
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(AppSizes.r6)),
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: AppTextStyles.bodyBold.copyWith(color: AppColors.textOnPrimary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
