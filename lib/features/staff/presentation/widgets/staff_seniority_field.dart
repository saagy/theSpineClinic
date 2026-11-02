import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'staff_permission_field.dart';

/// Seniority is a capability of the Doctor role, not a separate account role.
class StaffSeniorityField extends StatelessWidget {
  const StaffSeniorityField({
    super.key,
    required this.enabled,
    required this.initialValue,
  });
  final bool enabled;
  final bool initialValue;
  @override
  Widget build(BuildContext context) => StaffPermissionField(
    name: 'is_senior',
    enabled: enabled,
    initialValue: initialValue,
    title: AppStrings.seniorDoctor,
    description: AppStrings.isSeniorDoctorDescription,
  );
}
