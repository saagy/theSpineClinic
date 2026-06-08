import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_records_providers.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Interactive card allowing clinicians to edit visit notes inline.
///
/// Features auto-save on focus loss and manual save trigger.
/// Satisfies Rule 16: Controller is initialized in long-lived stateful lifecycle.
class AppointmentNotesCard extends ConsumerStatefulWidget {
  /// Creates an [AppointmentNotesCard].
  const AppointmentNotesCard({
    super.key,
    required this.appointmentId,
    required this.patientId,
  });

  /// The unique ID of the appointment.
  final String appointmentId;

  /// The unique ID of the patient.
  final String patientId;

  @override
  ConsumerState<AppointmentNotesCard> createState() => _AppointmentNotesCardState();
}

class _AppointmentNotesCardState extends ConsumerState<AppointmentNotesCard> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isInitialized = false;
  bool _isSaving = false;
  String _lastSavedText = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _saveNote();
    }
  }

  Future<void> _saveNote() async {
    final String text = _controller.text.trim();
    if (text == _lastSavedText) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(patientNotesNotifierProvider(widget.patientId).notifier)
          .addNote(
            noteText: text,
            appointmentId: widget.appointmentId,
          );
      _lastSavedText = text;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AppException ? e.message : 'Failed to save visit notes.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<PatientNote?> noteAsync =
        ref.watch(appointmentNoteProvider(widget.appointmentId));

    noteAsync.whenData((note) {
      if (!_isInitialized) {
        final String text = note?.noteText ?? '';
        _controller.text = text;
        _lastSavedText = text;
        _isInitialized = true;
      }
    });

    return noteAsync.when(
      loading: () => const SectionCard(
        title: 'Visit Notes',
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (Object error, StackTrace stack) => SectionCard(
        title: 'Visit Notes',
        child: Text(
          'Error loading notes: ${error.toString()}',
          style: AppTextStyles.body.copyWith(color: AppColors.error),
        ),
      ),
      data: (note) {
        final bool isUnsaved = _controller.text.trim() != _lastSavedText;

        return SectionCard(
          title: 'Visit Notes',
          action: _isSaving
              ? const SizedBox(
                  width: AppSizes.p16,
                  height: AppSizes.p16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : isUnsaved
                  ? const Tooltip(
                      message: 'Unsaved changes',
                      child: Icon(
                        Icons.pending_actions_rounded,
                        color: AppColors.warning,
                        size: AppSizes.iconDefault,
                      ),
                    )
                  : const Tooltip(
                      message: 'All changes saved',
                      child: Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.success,
                        size: AppSizes.iconDefault,
                      ),
                    ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 6,
                style: AppTextStyles.body,
                onChanged: (text) {
                  // Trigger state updates to reactively display pending/unsaved status
                  setState(() {});
                },
                decoration: const InputDecoration(
                  hintText: 'Enter clinical visit notes, patient findings, or treatment details...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(AppSizes.p12),
                ),
              ),
              const SizedBox(height: AppSizes.p12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isUnsaved ? 'Unsaved draft changes' : 'Draft auto-saves on focus loss',
                    style: AppTextStyles.caption.copyWith(
                      color: isUnsaved ? AppColors.warning : AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveNote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r6)),
                      ),
                    ),
                    child: Text(
                      'Save Notes',
                      style: AppTextStyles.bodyBold.copyWith(color: AppColors.textOnPrimary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
