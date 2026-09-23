import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';

String appointmentProgramSummary(List<PatientProgram> programs) {
  if (programs.isEmpty) return AppStrings.noProgramsRecorded;
  final active = programs.firstWhere(
    (program) => program.status == ProgramStatus.active,
    orElse: () => programs.first,
  );
  final regions = active.affectedRegions.isNotEmpty
      ? active.affectedRegions.map((region) => region.displayName).join(' & ')
      : active.conditions
            .map((condition) => condition.condition?.conditionName)
            .whereType<String>()
            .join(', ');
  final title = regions.isEmpty ? AppStrings.rehabilitationProgram : regions;
  final planName = active.activePlan?.planName;
  return planName == null ? title : '$title · $planName';
}
