import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/body_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/condition_catalog.dart';
import 'package:spine_clinic_app/features/medical_records/domain/laterality.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_input.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_type.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/plan_modality.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_condition.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_repository.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan_input.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan_repository.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/treatment_plan_controller.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_detail_treatment.dart';

class _FakePlanRepo implements TreatmentPlanRepository {
  String? activatedPlanId;

  @override
  Future<Result<TreatmentPlan>> upsertPlan({
    required String programId,
    String? planId,
    required String planName,
    required bool isActive,
    String? notes,
    required List<ModalityInput> modalities,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Result<void>> activatePlan({required String planId, required String programId}) async {
    activatedPlanId = planId;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> deletePlan(String planId) async => const Result.success(null);
}

class _FakeProgRepo implements ProgramRepository {
  @override
  Future<Result<List<PatientProgram>>> getProgramsForPatient(String patientId) async => const Result.success([]);
  @override
  Future<Result<PatientProgram?>> getProgramById(String programId) async => const Result.success(null);
  @override
  Future<Result<PatientProgram>> createProgram({required String patientId, required List<String> conditionIds, String? examination, String? imagingNotes, String? exaggeratingPositions, String? relievingPositions, String? notes, List<ProgramAttachment>? pendingAttachments, TreatmentPlanInput? treatmentPlan}) async => throw UnimplementedError();
  @override
  Future<Result<PatientProgram>> updateProgram({required String programId, required String patientId, required List<String> conditionIds, String? examination, String? imagingNotes, String? exaggeratingPositions, String? relievingPositions, String? notes, ProgramStatus? status, List<ProgramAttachment>? pendingAttachments, TreatmentPlanInput? treatmentPlan}) async => throw UnimplementedError();
  @override
  Future<Result<void>> updateProgramStatus({required String programId, required ProgramStatus status}) async => const Result.success(null);
  @override
  Future<Result<void>> deleteProgram(String programId) async => const Result.success(null);
}

class _StaticUser extends CurrentUser {
  _StaticUser(this._user);
  final Staff? _user;
  @override
  Future<Staff?> build() async => _user;
}

void main() {
  final senior = Staff(id: 's1', email: 's@c.com', fullName: 'Dr. S', role: UserRole.doctor, isActive: true, isSenior: true, createdAt: DateTime(2026));
  final junior = Staff(id: 'j1', email: 'j@c.com', fullName: 'Dr. J', role: UserRole.doctor, isActive: true, isSenior: false, createdAt: DateTime(2026));

  final baseProg = PatientProgram(
    id: 'p1',
    patientId: 'pat1',
    createdBy: 's1',
    status: ProgramStatus.active,
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
    conditions: const [
      ProgramCondition(id: 'pc1', programId: 'p1', conditionId: 'c1', condition: ConditionCatalog(id: 'c1', region: BodyRegion.lumbarSpine, conditionName: 'Herniation')),
    ],
  );

  final plan1 = TreatmentPlan(
    id: 'tp1',
    programId: 'p1',
    createdBy: 's1',
    planName: 'Phase 1 - Acute',
    isActive: false,
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
    modalities: const [
      PlanModality(id: 'pm1', treatmentPlanId: 'tp1', modalityType: ModalityType.tecar, regions: [
        ModalityRegion(id: 'mr1', planModalityId: 'pm1', targetRegion: 'Lumbar', laterality: null, timeMinutes: 15),
      ]),
    ],
  );

  final plan2 = TreatmentPlan(
    id: 'tp2',
    programId: 'p1',
    createdBy: 's1',
    planName: 'Phase 2 - Strengthening',
    isActive: true,
    createdAt: DateTime(2026, 8, 15),
    updatedAt: DateTime(2026, 8, 15),
    modalities: const [
      PlanModality(id: 'pm2', treatmentPlanId: 'tp2', modalityType: ModalityType.tecar, regions: [
        ModalityRegion(id: 'mr2', planModalityId: 'pm2', targetRegion: 'Gluteus', laterality: Laterality.right, timeMinutes: 20),
      ]),
    ],
  );

  testWidgets('ProgramDetailTreatment renders empty state and new plan button for senior doctor', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWith(() => _StaticUser(senior)),
        treatmentPlanRepositoryProvider.overrideWithValue(_FakePlanRepo()),
        programRepositoryProvider.overrideWithValue(_FakeProgRepo()),
      ],
      child: MaterialApp(home: Scaffold(body: ProgramDetailTreatment(program: baseProg))),
    ));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.noTreatmentPlans), findsOneWidget);
    expect(find.text(AppStrings.newTreatmentPlan), findsOneWidget);
  });

  testWidgets('ProgramDetailTreatment hides new plan button for junior doctor when empty', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWith(() => _StaticUser(junior)),
        treatmentPlanRepositoryProvider.overrideWithValue(_FakePlanRepo()),
        programRepositoryProvider.overrideWithValue(_FakeProgRepo()),
      ],
      child: MaterialApp(home: Scaffold(body: ProgramDetailTreatment(program: baseProg))),
    ));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.noTreatmentPlans), findsOneWidget);
    expect(find.text(AppStrings.newTreatmentPlan), findsNothing);
  });

  testWidgets('ProgramDetailTreatment renders active plan and collapsible previous plans', (tester) async {
    final progWithPlans = baseProg.copyWith(treatmentPlans: [plan1, plan2]);
    final fakeRepo = _FakePlanRepo();

    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentUserProvider.overrideWith(() => _StaticUser(senior)),
        treatmentPlanRepositoryProvider.overrideWithValue(fakeRepo),
        programRepositoryProvider.overrideWithValue(_FakeProgRepo()),
      ],
      child: MaterialApp(home: Scaffold(body: ProgramDetailTreatment(program: progWithPlans))),
    ));
    await tester.pumpAndSettle();

    // Active plan visible
    expect(find.text('Phase 2 - Strengthening'), findsOneWidget);
    expect(find.text('Gluteus (Right) · 20m'), findsOneWidget);

    // Previous plans header visible
    expect(find.text('${AppStrings.previousPlans} (1)'), findsOneWidget);

    // Expand previous plans
    await tester.tap(find.text('${AppStrings.previousPlans} (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Phase 1 - Acute'), findsOneWidget);
    expect(find.text(AppStrings.activate), findsOneWidget);

    // Tap Activate
    await tester.tap(find.text(AppStrings.activate));
    await tester.pumpAndSettle();

    expect(fakeRepo.activatedPlanId, 'tp1');
  });
}
