import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/body_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_input.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_repository.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan_input.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan_repository.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/treatment_plan_controller.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/treatment_plan_builder_sheet.dart';

class _FakePlanRepo implements TreatmentPlanRepository {
  TreatmentPlan? lastUpserted;

  @override
  Future<Result<TreatmentPlan>> upsertPlan({
    required String programId,
    String? planId,
    required String planName,
    required bool isActive,
    String? notes,
    required List<ModalityInput> modalities,
  }) async {
    final plan = TreatmentPlan(
      id: planId ?? 'plan-123',
      programId: programId,
      createdBy: 'doc-1',
      planName: planName,
      isActive: isActive,
      notes: notes,
      createdAt: DateTime(2026, 8, 30),
      updatedAt: DateTime(2026, 8, 30),
      modalities: const [],
    );
    lastUpserted = plan;
    return Result.success(plan);
  }

  @override
  Future<Result<void>> activatePlan({required String planId, required String programId}) async => const Result.success(null);

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
  final senior = Staff(
    id: 's1',
    email: 's@c.com',
    fullName: 'Dr. S',
    role: UserRole.doctor,
    isActive: true,
    isSenior: true,
    createdAt: DateTime(2026),
  );

  testWidgets('TreatmentPlanBuilderSheet renders and saves plan', (tester) async {
    final fakeRepo = _FakePlanRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(() => _StaticUser(senior)),
          treatmentPlanRepositoryProvider.overrideWithValue(fakeRepo),
          programRepositoryProvider.overrideWithValue(_FakeProgRepo()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TreatmentPlanBuilderSheet(
              programId: 'prog-1',
              patientId: 'pat-1',
              affectedRegions: {BodyRegion.lumbarSpine},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.planName), findsOneWidget);
    expect(find.text(AppStrings.selectModalities), findsOneWidget);
    expect(find.text(AppStrings.save), findsOneWidget);

    await tester.tap(find.text(AppStrings.save));
    await tester.pumpAndSettle();

    expect(fakeRepo.lastUpserted, isNotNull);
    expect(fakeRepo.lastUpserted!.planName, 'Plan 1');
  });
}
