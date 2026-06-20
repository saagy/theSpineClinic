import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/new_patient_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_form_fields.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/app_doctor_multi_select_field.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Form component for registering a new patient.
class NewPatientForm extends ConsumerStatefulWidget {
  /// Creates a [NewPatientForm].
  const NewPatientForm({super.key});

  @override
  ConsumerState<NewPatientForm> createState() => _NewPatientFormState();
}

class _NewPatientFormState extends ConsumerState<NewPatientForm> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final List<PlatformFile> _selectedFiles = [];

  Future<void> _pickFiles() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
      allowMultiple: true,
    );
    if (result == null) return;

    for (final PlatformFile f in result.files) {
      final String ext = p.extension(f.name).toLowerCase();
      final bool isPdf = ext == '.pdf';
      final int maxBytes = isPdf ? 10 * 1024 * 1024 : 10 * 1024 * 1024;
      if (f.size > maxBytes) {
        if (!mounted) return;
        AppSnackbar.show(
          context,
          message: AppStrings.fromKey(
            isPdf ? 'error_doc_pdf_too_large' : 'error_doc_image_too_large',
          ),
          variant: AppSnackbarVariant.error,
        );
        continue;
      }
      _selectedFiles.add(f);
    }
    setState(() {});
  }

  void _removeFile(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  bool _isFormDirty() {
    final FormBuilderState? state = _formKey.currentState;
    if (state == null) return false;
    final Map<String, dynamic> values = state.instantValue;
    final bool hasName = (values['full_name'] as String?)?.isNotEmpty == true;
    final bool hasPhone =
        (values['phone_number'] as String?)?.isNotEmpty == true;
    final bool hasProgram =
        (values['program'] as String?)?.isNotEmpty == true;
    final bool hasDoctors =
        (values['assigned_doctors'] as List?)?.isNotEmpty == true;
    return hasName ||
        hasPhone ||
        hasProgram ||
        hasDoctors ||
        _selectedFiles.isNotEmpty;
  }

  Future<void> _handleCancel() async {
    if (_isFormDirty()) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => const ConfirmationDialog(
          title: 'Discard Changes',
          message: 'You have entered unsaved information. Discard?',
          confirmLabel: 'Discard',
          cancelLabel: 'Keep Editing',
          isDestructive: true,
        ),
      );
      if (confirm == true && mounted) context.pop();
    } else {
      context.pop();
    }
  }

  Future<void> _handleSave() async {
    final FormBuilderState? state = _formKey.currentState;
    if (state == null || !state.saveAndValidate()) return;

    final String fullName = state.fields['full_name']!.value as String;
    final String phoneNumber = state.fields['phone_number']!.value as String;
    final String? program = state.fields['program']?.value as String?;
    final ClinicLocation clinic =
        state.fields['clinic']!.value as ClinicLocation;
    final assignedDoctors =
        state.fields['assigned_doctors']!.value as List<Staff>;

    final List<String> assignedDoctorIds =
        assignedDoctors.map((d) => d.id).toList();

    final Result<Patient> result = await ref
        .read(newPatientControllerProvider.notifier)
        .createPatient(
          fullName: fullName.trim(),
          phoneNumber: phoneNumber.trim(),
          program: program,
          clinic: clinic,
          assignedDoctorIds: assignedDoctorIds,
          attachments: _selectedFiles,
        );

    if (!mounted) return;

    result.when(
      success: (Patient createdPatient) {
        // Inspect per-attachment status providers to know whether all
        // uploads succeeded or only some did.
        int failedCount = 0;
        for (int i = 0; i < _selectedFiles.length; i++) {
          final AttachmentStatus s =
              ref.read(indexedAttachmentStatusProvider(i));
          if (s == AttachmentStatus.failed) failedCount++;
        }
        if (failedCount > 0) {
          AppSnackbar.show(
            context,
            message: AppStrings.errorAttachmentPartialFail,
            variant: AppSnackbarVariant.error,
          );
        } else {
          AppSnackbar.show(
            context,
            message: 'Patient registered successfully.',
            variant: AppSnackbarVariant.success,
          );
        }
        context.go(
          AppRoutes.patientDetail.replaceAll(':id', createdPatient.id),
        );
      },
      failure: (AppException error) {
        AppSnackbar.show(
          context,
          message: AppStrings.fromKey(error.userMessageKey),
          variant: AppSnackbarVariant.error,
        );
      },
    );
  }

  Widget _buildAttachmentsList(bool isSaving, ColorScheme cs) {
    if (_selectedFiles.isEmpty) {
      return Text(
        'No documents selected.',
        style: AppTextStyles.bodySecondary
            .copyWith(color: AppColors.textMuted),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _selectedFiles.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.p4),
      itemBuilder: (context, index) {
        final PlatformFile file = _selectedFiles[index];
        final AttachmentStatus status =
            ref.watch(indexedAttachmentStatusProvider(index));
        final String ext = p.extension(file.name).toLowerCase();
        final bool isImage =
            const ['.png', '.jpg', '.jpeg'].contains(ext);
        return _AttachmentRow(
          file: file,
          isImage: isImage,
          status: status,
          onRemove: isSaving ? null : () => _removeFile(index),
          cs: cs,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<void> submitState =
        ref.watch(newPatientControllerProvider);
    final bool isSaving = submitState.isLoading;
    final ColorScheme cs = Theme.of(context).colorScheme;

    return FormBuilder(
      key: _formKey,
      enabled: !isSaving,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: 'Patient Demographics',
            child: PatientFormFields(enabled: !isSaving),
          ),
          const SizedBox(height: AppSizes.p16),
          SectionCard(
            title: 'Staff Assignment',
            child: FormBuilderField<List<Staff>>(
              name: 'assigned_doctors',
              initialValue: const [],
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'At least one assigned doctor is required';
                }
                return null;
              },
              builder: (state) {
                return AppDoctorMultiSelectField(
                  initialValue: List<Staff>.from(state.value ?? []),
                  onSavedDoctors: (doctors) => state.didChange(doctors),
                  onChanged: (doctors) => state.didChange(doctors),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'At least one assigned doctor is required';
                    }
                    return null;
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppSizes.p16),
          SectionCard(
            title: 'Attachments',
            action: IconButton(
              icon: Icon(Icons.attach_file_rounded,
                  color: cs.primary),
              onPressed: isSaving ? null : _pickFiles,
            ),
            child: _buildAttachmentsList(isSaving, cs),
          ),
          if (isSaving && _selectedFiles.isNotEmpty) ...[
            const SizedBox(height: AppSizes.p12),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p16),
              child: Text(
                _uploadingLabel,
                style: AppTextStyles.bodySecondary
                    .copyWith(color: cs.onSurface),
              ),
            ),
            const SizedBox(height: AppSizes.p4),
            LinearProgressIndicator(color: cs.primary),
          ],
          const SizedBox(height: AppSizes.p24),
          AppButton(
            labelText: AppStrings.save,
            onPressed: isSaving ? null : _handleSave,
            isLoading: isSaving,
            debounceMs: 1000,
          ),
          const SizedBox(height: AppSizes.p8),
          AppButton(
            labelText: AppStrings.cancel,
            variant: AppButtonVariant.secondary,
            onPressed: isSaving ? null : _handleCancel,
          ),
        ],
      ),
    );
  }

  String get _uploadingLabel {
    int uploading = 0;
    for (int i = 0; i < _selectedFiles.length; i++) {
      final s = ref.read(indexedAttachmentStatusProvider(i));
      if (s == AttachmentStatus.uploading) {
        uploading++;
      }
    }
    return 'Uploading attachments… ($uploading remaining)';
  }
}

// ── _AttachmentRow ────────────────────────────────────────────────

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({
    required this.file,
    required this.isImage,
    required this.status,
    required this.onRemove,
    required this.cs,
  });

  final PlatformFile file;
  final bool isImage;
  final AttachmentStatus status;
  final VoidCallback? onRemove;
  final ColorScheme cs;

  Widget _leading() {
    if (isImage && file.bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.memory(
          file.bytes!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          cacheWidth: 96,
        ),
      );
    }
    return Icon(
      isImage ? Icons.image_rounded : Icons.picture_as_pdf_outlined,
      color: isImage ? cs.primary : cs.error,
      size: AppSizes.iconLarge,
    );
  }

  Widget _statusChip() {
    final Color chipColor = switch (status) {
      AttachmentStatus.idle => AppColors.textMuted,
      AttachmentStatus.uploading => cs.primary,
      AttachmentStatus.done => AppColors.success,
      AttachmentStatus.failed => cs.error,
    };
    final String label = switch (status) {
      AttachmentStatus.idle => 'Ready',
      AttachmentStatus.uploading => 'Uploading',
      AttachmentStatus.done => 'Done',
      AttachmentStatus.failed => 'Failed',
    };
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSizes.p8, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withAlpha(30),
        borderRadius: BorderRadius.circular(AppSizes.r12),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: chipColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _leading(),
          const SizedBox(width: AppSizes.p12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  file.name,
                  style: AppTextStyles.bodyBold.copyWith(
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${(file.size / 1024).toStringAsFixed(1)} KB',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.p8),
          _statusChip(),
          if (onRemove != null) ...[
            const SizedBox(width: AppSizes.p4),
            IconButton(
              icon: Icon(Icons.close_rounded,
                  color: cs.error, size: 20),
              onPressed: onRemove,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}
