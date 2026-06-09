import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_strings_auth.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/edit_patient_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_demographic_fields.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/app_doctor_multi_select_field.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_chip.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Form component for editing patient demographics and doctor assignments.
class EditPatientForm extends ConsumerStatefulWidget {
  /// Creates an [EditPatientForm].
  const EditPatientForm({super.key, required this.patient, required this.assignedDoctors});

  /// The patient entity to edit.
  final Patient patient;

  /// Currently assigned doctors.
  final List<Staff> assignedDoctors;

  @override
  ConsumerState<EditPatientForm> createState() => _EditPatientFormState();
}

class _EditPatientFormState extends ConsumerState<EditPatientForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl, _phoneCtrl, _programCtrl;
  ClinicLocation? _selectedClinic;
  final List<Staff> _selectedDoctors = [];
  late final List<String> _initialDoctorIds;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.patient.fullName);
    _phoneCtrl = TextEditingController(text: widget.patient.phoneNumber);
    _programCtrl = TextEditingController(text: widget.patient.program ?? '');
    _selectedClinic = widget.patient.clinic;
    _selectedDoctors.addAll(widget.assignedDoctors);
    _initialDoctorIds = widget.assignedDoctors.map((d) => d.id).toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _programCtrl.dispose();
    super.dispose();
  }

  bool _hasChanges() {
    final patient = widget.patient;
    final initialSet = _initialDoctorIds.toSet();
    final programVal = _programCtrl.text.trim();
    final currentIds = _selectedDoctors.map((d) => d.id).toSet();
    return _nameCtrl.text.trim() != patient.fullName ||
        _phoneCtrl.text.trim() != patient.phoneNumber ||
        (programVal.isEmpty ? null : programVal) != patient.program ||
        _selectedClinic != patient.clinic ||
        currentIds.length != initialSet.length ||
        !currentIds.every(initialSet.contains);
  }

  Future<bool> _showDiscardDialog() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => const ConfirmationDialog(
        title: 'Discard Changes',
        message: 'You have unsaved changes. Discard?',
        confirmLabel: 'Discard',
        cancelLabel: 'Keep Editing',
        isDestructive: true,
      ),
    );
    return res ?? false;
  }

  Future<void> _handleCancel() async {
    if (_hasChanges() && await _showDiscardDialog()) {
      if (mounted) context.pop();
    } else if (!_hasChanges()) {
      if (mounted) context.pop();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    final updated = widget.patient.copyWith(
      fullName: _nameCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
      program: _programCtrl.text.trim().isEmpty ? null : _programCtrl.text.trim(),
      clinic: _selectedClinic!,
    );
    
    await ref.read(editPatientControllerProvider.notifier).submit(
      patient: updated,
      selectedDoctorIds: _selectedDoctors.map((d) => d.id).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(editPatientControllerProvider).isLoading;
    final user = ref.watch(currentUserProvider).value;
    final isDoctor = user?.role == UserRole.doctor;

    ref.listen<AsyncValue<void>>(
      editPatientControllerProvider,
      (previous, next) {
        next.whenOrNull(
          data: (_) {
            AppSnackbar.show(
              context,
              message: AppStringsAuth.patientUpdatedSuccess,
              variant: AppSnackbarVariant.success,
            );
            context.pop();
          },
          error: (error, stackTrace) {
            final exception = error is AppException ? error : UnknownException(message: error.toString());
            AppSnackbar.show(
              context,
              message: AppStrings.fromKey(exception.userMessageKey),
              variant: AppSnackbarVariant.error,
            );
          },
        );
      },
    );

    return PopScope(
      canPop: !_hasChanges() && !isSaving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || isSaving) return;
        if (await _showDiscardDialog() && context.mounted) context.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(AppStrings.editPatient),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: isSaving ? null : _handleCancel,
          ),
        ),
        body: LoadingOverlay(
          isLoading: isSaving,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionCard(
                    title: AppStrings.patientDetails,
                    child: PatientDemographicFields(
                      nameCtrl: _nameCtrl,
                      phoneCtrl: _phoneCtrl,
                      programCtrl: _programCtrl,
                      selectedClinic: _selectedClinic,
                      onClinicChanged: (val) => setState(() => _selectedClinic = val),
                      enabled: !isSaving,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p16),
                  SectionCard(
                    title: AppStrings.assignedDoctors,
                    child: isDoctor
                        ? Wrap(
                            spacing: AppSizes.p8,
                            runSpacing: AppSizes.p8,
                            children: _selectedDoctors
                                .map((doc) => AppChip(label: doc.fullName))
                                .toList(),
                          )
                        : AppDoctorMultiSelectField(
                            initialValue: _selectedDoctors,
                            onSavedDoctors: (doctors) => setState(() {
                              _selectedDoctors.clear();
                              _selectedDoctors.addAll(doctors);
                            }),
                            onChanged: (doctors) => setState(() {
                              _selectedDoctors.clear();
                              _selectedDoctors.addAll(doctors);
                            }),
                            validator: (val) => (val == null || val.isEmpty)
                                ? AppStringsAuth.validationDoctorRequired
                                : null,
                          ),
                  ),
                  const SizedBox(height: AppSizes.p32),
                  AppButton(labelText: AppStrings.save, onPressed: isSaving ? null : _submit),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
