import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/edit_patient_form.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Screen view that loads data and renders the edit patient form.
class EditPatientScreen extends ConsumerWidget {
  /// Creates an [EditPatientScreen].
  const EditPatientScreen({super.key, required this.patientId, this.patient});

  /// Patient ID parameter.
  final String patientId;

  /// Optional pre-loaded patient object.
  final Patient? patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = patient != null
        ? AsyncValue.data(patient!)
        : ref.watch(patientDetailProvider(patientId));
    final assignedAsync = ref.watch(patientAssignedDoctorsProvider(patientId));

    if (patientAsync.hasError || assignedAsync.hasError) {
      final error = patientAsync.error ?? assignedAsync.error;
      final exception = error is AppException ? error : UnknownException(message: error?.toString() ?? '');
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.editPatient)),
        body: ErrorView(
          exception: exception,
          onRetry: () {
            ref.invalidate(patientDetailProvider(patientId));
            ref.invalidate(patientAssignedDoctorsProvider(patientId));
          },
        ),
      );
    }

    if (patientAsync.isLoading || assignedAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.editPatient)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return EditPatientForm(
      patient: patientAsync.value!,
      assignedDoctors: assignedAsync.value!,
    );
  }
}
