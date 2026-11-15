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
import 'package:spine_clinic_app/features/medical_records/domain/modality_type.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_program.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_repository.dart';
import 'package:spine_clinic_app/features/medical_records/domain/program_status.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan_input.dart';
import 'package:spine_clinic_app/features/medical_records/domain/treatment_plan_repository.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_programs_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/treatment_plan_controller.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/modality_chip_selector.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/modality_config_card.dart';
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
  Future<Result<PatientProgram>> updateProgram({required String programId, required String patientId, required List<String> conditionIds, String? examination, String? imagingNotes, String? exaggeratingPositions, String? relievingPositions, String? notes, ProgramStatus? status, List<ProgramAttachment>? pendingAttachments, List<String> removedDocumentIds = const [], TreatmentPlanInput? treatmentPlan}) async => throw UnimplementedError();
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
    expect(find.text(AppStrings.saveAndUsePlan), findsOneWidget);

    await tester.tap(find.text(AppStrings.saveAndUsePlan));
    await tester.pumpAndSettle();

    expect(fakeRepo.lastUpserted, isNotNull);
    expect(fakeRepo.lastUpserted!.planName, 'Plan 1');
  });

  Future<void> pumpBuilder(WidgetTester tester, {TreatmentPlan? existingPlan}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(() => _StaticUser(senior)),
          treatmentPlanRepositoryProvider.overrideWithValue(_FakePlanRepo()),
          programRepositoryProvider.overrideWithValue(_FakeProgRepo()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TreatmentPlanBuilderSheet(
              programId: 'prog-1',
              patientId: 'pat-1',
              affectedRegions: const {BodyRegion.lumbarSpine},
              existingPlan: existingPlan,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder chip(ModalityType type) => find.descendant(
    of: find.byType(ModalityChipSelector),
    matching: find.text(type.displayLabel),
  );

  List<ModalityType> cardOrder(WidgetTester tester) => tester
      .widgetList<ModalityConfigCard>(find.byType(ModalityConfigCard, skipOffstage: false))
      .map((card) => card.modalityType)
      .toList();

  Future<void> toggle(WidgetTester tester, ModalityType type) async {
    await tester.tap(chip(type));
    await tester.pumpAndSettle();
  }

  testWidgets('cards follow selection order and re-adding moves a card last', (tester) async {
    await pumpBuilder(tester);

    await toggle(tester, ModalityType.exercise);
    await toggle(tester, ModalityType.musclePain);
    await toggle(tester, ModalityType.tecar);
    expect(cardOrder(tester), [ModalityType.exercise, ModalityType.musclePain, ModalityType.tecar]);

    await toggle(tester, ModalityType.exercise);
    await toggle(tester, ModalityType.exercise);
    expect(cardOrder(tester), [ModalityType.musclePain, ModalityType.tecar, ModalityType.exercise]);
  });

  testWidgets('a reopened plan keeps its saved order', (tester) async {
    final plan = TreatmentPlan.fromJson({
      'id': 'plan-1',
      'program_id': 'prog-1',
      'created_by': 'doc-1',
      'created_at': '2026-08-30T00:00:00Z',
      'updated_at': '2026-08-30T00:00:00Z',
      'plan_modalities': [
        {'id': 'b', 'treatment_plan_id': 'plan-1', 'modality_type': 'mulligan', 'sort_order': 9},
        {'id': 'a', 'treatment_plan_id': 'plan-1', 'modality_type': 'exercise', 'sort_order': 4},
        {'id': 'c', 'treatment_plan_id': 'plan-1', 'modality_type': 'tecar_focal', 'sort_order': 12},
      ],
    });

    expect(plan.modalities.map((m) => m.modalityType), [
      ModalityType.exercise,
      ModalityType.mulligan,
      ModalityType.tecarFocal,
    ]);

    await pumpBuilder(tester, existingPlan: plan);
    expect(cardOrder(tester), [ModalityType.exercise, ModalityType.mulligan, ModalityType.tecarFocal]);
  });

  testWidgets('on a phone the chips stay pinned and each new card scrolls into view', (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpBuilder(tester);

    for (final type in [ModalityType.musclePain, ModalityType.massBuilt]) {
      await toggle(tester, type);
      final chipsBottom = tester.getBottomLeft(find.byType(ModalityChipSelector)).dy;
      final saveBarTop = tester.getTopLeft(find.text(AppStrings.saveAndUsePlan)).dy;
      final newCardTop = tester.getTopLeft(find.byType(ModalityConfigCard).last).dy;
      expect(tester.getTopLeft(chip(type)).dy, greaterThanOrEqualTo(0));
      expect(newCardTop, greaterThanOrEqualTo(chipsBottom));
      expect(newCardTop, lessThan(saveBarTop));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('short windows let the chips scroll away instead of covering the form', (tester) async {
    tester.view.physicalSize = const Size(800, 380);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpBuilder(tester);

    expect(find.byType(PinnedHeaderSliver), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
