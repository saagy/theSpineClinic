import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_palette.dart';
import 'package:spine_clinic_app/core/constants/app_theme.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_input.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_type.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/plan_modality.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_repository.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan_repository.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/screens/program_detail_screen.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/treatment_plan_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_documents_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_programs.dart';
import 'workspace_data.dart';
import 'workspace_overrides.dart';

final uxCurrentPlan = workspacePrograms.first.activePlan!.copyWith(
  planName: 'Strengthening and mobility',
  notes: 'Review movement quality at each visit.',
  modalities: const [
    PlanModality(
      id: 'modality',
      treatmentPlanId: 'plan-0',
      modalityType: ModalityType.tecar,
      regions: [ModalityRegion(id: 'region', planModalityId: 'modality', targetRegion: 'Lumbar', timeMinutes: 15)],
    ),
  ],
);
final uxPreviousPlan = uxCurrentPlan.copyWith(id: 'previous', planName: 'Initial treatment', isActive: false);

class ProgramUxRepository implements ProgramRepository {
  PatientProgram? program = workspacePrograms.first.copyWith(treatmentPlans: [uxCurrentPlan, uxPreviousPlan]);
  int statusWrites = 0;
  @override
  Future<Result<PatientProgram?>> getProgramById(String programId) async => Result.success(program);
  @override
  Future<Result<List<PatientProgram>>> getProgramsForPatient(String patientId) async =>
      Result.success([if (program != null) program!]);
  @override
  Future<Result<void>> updateProgramStatus({required String programId, required ProgramStatus status}) async {
    statusWrites++;
    program = program!.copyWith(status: status);
    return const Result.success(null);
  }

  @override
  Future<Result<void>> deleteProgram(String programId) async {
    program = null;
    return const Result.success(null);
  }

  @override
  Object? noSuchMethod(Invocation invocation) => throw UnsupportedError('${invocation.memberName}');
}

class ProgramUxPlanRepository implements TreatmentPlanRepository {
  ProgramUxPlanRepository(this.programs);
  final ProgramUxRepository programs;
  String? savedId;
  String? activatedId;
  List<ModalityInput>? savedModalities;
  @override
  Future<Result<TreatmentPlan>> upsertPlan({
    required String programId,
    String? planId,
    required String planName,
    required bool isActive,
    String? notes,
    required List<ModalityInput> modalities,
  }) async {
    savedId = planId;
    savedModalities = modalities;
    final plan = uxCurrentPlan.copyWith(id: planId ?? 'new-plan', planName: planName, isActive: isActive, notes: notes);
    programs.program = programs.program!.copyWith(
      treatmentPlans: [
        for (final item in programs.program!.treatmentPlans)
          if (item.id != plan.id) item.copyWith(isActive: isActive ? false : item.isActive),
        plan,
      ],
    );
    return Result.success(plan);
  }

  @override
  Future<Result<void>> activatePlan({required String planId, required String programId}) async {
    activatedId = planId;
    programs.program = programs.program!.copyWith(
      treatmentPlans: [for (final plan in programs.program!.treatmentPlans) plan.copyWith(isActive: plan.id == planId)],
    );
    return const Result.success(null);
  }

  @override
  Future<Result<void>> deletePlan(String planId) async {
    programs.program = programs.program!.copyWith(
      treatmentPlans: programs.program!.treatmentPlans.where((p) => p.id != planId).toList(),
    );
    return const Result.success(null);
  }
}

Widget programUxApp(
  ProgramUxRepository programs,
  ProgramUxPlanRepository plans, {
  bool dark = false,
  double scale = 1,
  String role = 'senior',
  bool list = false,
  GlobalKey? captureKey,
}) {
  final program = workspacePrograms.first;
  final router = GoRouter(
    initialLocation: list ? '/list' : '/patient/${program.patientId}/programs/${program.id}',
    routes: [
      GoRoute(
        path: '/list',
        builder: (_, _) => Scaffold(
          body: SingleChildScrollView(child: WorkspacePrograms(patientId: program.patientId)),
        ),
      ),
      GoRoute(
        path: '/patient/:id/programs/:programId',
        builder: (_, _) => ProgramDetailScreen(patientId: program.patientId, programId: program.id),
      ),
      GoRoute(
        path: '/patient/:id/programs/:programId/edit',
        builder: (_, _) => const Scaffold(body: Text('Program edit destination')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith(() => WorkspaceUser(role)),
      programRepositoryProvider.overrideWithValue(programs),
      treatmentPlanRepositoryProvider.overrideWithValue(plans),
      programDocumentsProvider(patientId: program.patientId, programId: program.id).overrideWith((ref) async => []),
    ],
    child: RepaintBoundary(
      key: captureKey,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: dark ? AppTheme.dark(clinicalBluePaletteDark) : AppTheme.light(clinicalBluePaletteLight),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
}
