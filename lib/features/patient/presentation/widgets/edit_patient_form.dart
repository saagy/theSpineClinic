import 'package:spine_clinic_app/shared/widgets/form_columns.dart';
import 'package:spine_clinic_app/shared/widgets/form_section.dart';
import 'package:spine_clinic_app/shared/widgets/form_page_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import 'package:spine_clinic_app/shared/widgets/doctor_select_field.dart';
import 'package:spine_clinic_app/shared/widgets/app_chip.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';

/// Form component for editing patient demographics and doctor assignments.
part 'edit_patient_form_view.dart';

class EditPatientForm extends ConsumerStatefulWidget {
  const EditPatientForm({super.key, required this.patient, required this.assignedDoctors});

  final Patient patient;
  final List<Staff> assignedDoctors;

  @override
  ConsumerState<EditPatientForm> createState() => _EditPatientFormState();
}

class _EditPatientFormState extends ConsumerState<EditPatientForm> {
  final _formKey = GlobalKey<FormState>();
  bool _allowPop = false;
  late final TextEditingController _nameCtrl, _phoneCtrl;
  ClinicLocation? _selectedClinic;
  final List<Staff> _selectedDoctors = [];
  late final List<String> _initialDoctorIds;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.patient.fullName);
    _phoneCtrl = TextEditingController(text: widget.patient.phoneNumber);
    _selectedClinic = widget.patient.clinic;
    _selectedDoctors.addAll(widget.assignedDoctors);
    _nameCtrl.addListener(_onInputChanged);
    _phoneCtrl.addListener(_onInputChanged);
    _initialDoctorIds = widget.assignedDoctors.map((d) => d.id).toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool _hasChanges() {
    final patient = widget.patient;
    final initialSet = _initialDoctorIds.toSet();
    final currentIds = _selectedDoctors.map((d) => d.id).toSet();
    return _nameCtrl.text.trim() != patient.fullName ||
        _phoneCtrl.text.trim() != patient.phoneNumber ||
        _selectedClinic != patient.clinic ||
        currentIds.length != initialSet.length ||
        !currentIds.every(initialSet.contains);
  }

  Future<bool> _showDiscardDialog() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => const ConfirmationDialog(
        title: AppStrings.discardChanges,
        message: AppStrings.discardChangesMessage,
        confirmLabel: AppStrings.discard,
        cancelLabel: AppStrings.keepEditing,
        isDestructive: true,
      ),
    );
    return res ?? false;
  }

  Future<void> _leaveForm() async {
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) context.pop();
  }

  Future<void> _handleCancel() async {
    if ((_hasChanges() && await _showDiscardDialog()) || !_hasChanges()) {
      if (mounted) await _leaveForm();
    }
  }

  Future<void> _submit() async {
    if (ref.read(editPatientControllerProvider).isLoading || !_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    final updated = widget.patient.copyWith(
      fullName: _nameCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
      clinic: _selectedClinic!,
    );

    await ref
        .read(editPatientControllerProvider.notifier)
        .submit(
          patient: updated,
          selectedDoctorIds: _selectedDoctors.map((d) => d.id).toList(),
          initialDoctorIds: _initialDoctorIds,
        );
  }

  void _onInputChanged() => setState(() {});

  void _mutate(VoidCallback change) => setState(change);

  @override
  Widget build(BuildContext context) => _buildForm(context);
}
