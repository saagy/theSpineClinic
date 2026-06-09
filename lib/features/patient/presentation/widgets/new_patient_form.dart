import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/presentation/new_patient_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_form_fields.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/app_doctor_multi_select_field.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';
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
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() => _selectedFiles.addAll(result.files));
    }
  }

  void _removeFile(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  bool _isFormDirty() {
    final state = _formKey.currentState;
    if (state == null) return false;
    final values = state.instantValue;
    final hasName = (values['full_name'] as String?)?.isNotEmpty == true;
    final hasPhone = (values['phone_number'] as String?)?.isNotEmpty == true;
    final hasProgram = (values['program'] as String?)?.isNotEmpty == true;
    final hasDoctors = (values['assigned_doctors'] as List?)?.isNotEmpty == true;
    return hasName || hasPhone || hasProgram || hasDoctors || _selectedFiles.isNotEmpty;
  }

  Future<void> _handleCancel() async {
    if (_isFormDirty()) {
      final confirm = await showDialog<bool>(
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
    final state = _formKey.currentState;
    if (state == null || !state.saveAndValidate()) return;

    final String fullName = state.fields['full_name']!.value as String;
    final String phoneNumber = state.fields['phone_number']!.value as String;
    final String? program = state.fields['program']?.value as String?;
    final ClinicLocation clinic = state.fields['clinic']!.value as ClinicLocation;
    final assignedDoctors = state.fields['assigned_doctors']!.value as List<Staff>;

    final assignedDoctorIds = assignedDoctors.map((d) => d.id).toList();

    final result = await ref.read(newPatientControllerProvider.notifier).createPatient(
          fullName: fullName.trim(),
          phoneNumber: phoneNumber.trim(),
          program: program,
          clinic: clinic,
          assignedDoctorIds: assignedDoctorIds,
          attachments: _selectedFiles,
        );

    if (!mounted) return;

    result.when(
      success: (createdPatient) {
        AppSnackbar.show(context, message: 'Patient registered successfully.', variant: AppSnackbarVariant.success);
        context.go(AppRoutes.patientDetail.replaceAll(':id', createdPatient.id));
      },
      failure: (error) {
        AppSnackbar.show(context, message: AppStrings.fromKey(error.userMessageKey), variant: AppSnackbarVariant.error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(newPatientControllerProvider);
    final isSaving = submitState.isLoading;

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
              icon: const Icon(Icons.attach_file_rounded, color: AppColors.primary),
              onPressed: isSaving ? null : _pickFiles,
            ),
            child: _selectedFiles.isEmpty
                ? Text(
                    'No documents selected.',
                    style: AppTextStyles.bodySecondary.copyWith(color: AppColors.textMuted),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _selectedFiles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSizes.p4),
                    itemBuilder: (context, index) {
                      final file = _selectedFiles[index];
                      return DataListTile(
                        title: file.name,
                        subtitle: '${(file.size / 1024).toStringAsFixed(1)} KB',
                        leading: const Icon(Icons.insert_drive_file_outlined, color: AppColors.primary),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                          onPressed: isSaving ? null : () => _removeFile(index),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: AppSizes.p24),
          AppButton(
            labelText: AppStrings.save,
            onPressed: isSaving ? null : _handleSave,
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
}
